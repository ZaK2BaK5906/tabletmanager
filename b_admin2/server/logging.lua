-- ============================================
-- B_ADMIN2 - SYSTÈME DE LOGGING MAXIMUM
-- ============================================

-- ============================================
-- UTILITAIRES
-- ============================================

--- Envoie un embed Discord via webhook
---@param webhook string URL du webhook
---@param embed table Embed Discord
local function SendDiscordWebhook(webhook, embed)
    if not webhook or webhook == '' or webhook:find('YOUR_WEBHOOK') then
        return -- Webhook non configuré
    end

    PerformHttpRequest(webhook, function(err, text, headers)
        if err ~= 200 and err ~= 204 then
            print('^1[B_ADMIN2 Logging]^7 Erreur webhook Discord: ' .. tostring(err))
        end
    end, 'POST', json.encode({
        username = Config.ServerName .. ' - Admin Logs',
        embeds = { embed }
    }), {
        ['Content-Type'] = 'application/json'
    })
end

--- Crée un embed Discord formaté
---@param category string Catégorie (moderation/economy/etc)
---@param title string
---@param description string
---@param fields table|nil
---@param color number|nil
---@return table embed
local function CreateEmbed(category, title, description, fields, color)
    local colors = {
        moderation = 16711680, -- Rouge
        economy = 16776960,    -- Jaune
        player = 65280,        -- Vert
        staffmode = 3447003,   -- Bleu
        reports = 10181046,    -- Violet
        security = 15158332,   -- Orange foncé
        player_actions = 8421504 -- Gris
    }

    return {
        title = title,
        description = description,
        color = color or colors[category] or 0,
        fields = fields or {},
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S'),
        footer = {
            text = Config.ServerName .. ' | ' .. Config.ServerId
        }
    }
end

-- ============================================
-- LOG STAFF ACTION
-- ============================================

--- Log une action staff complète
---@param adminSource number
---@param targetSource number|nil
---@param actionType string
---@param actionCategory string
---@param payload table|nil
---@param success boolean
---@param failReason string|nil
---@param ticketId number|nil
function LogStaffAction(adminSource, targetSource, actionType, actionCategory, payload, success, failReason, ticketId)
    success = success == nil and true or success

    -- Récupération infos admin
    local adminLicense = GetPlayerLicense(adminSource)
    local adminDiscordId = GetDiscordIdentifier(adminSource)
    local adminPerms = GetPlayerPermissions(adminSource)
    local adminName = GetPlayerName(adminSource)

    -- Récupération infos target
    local targetLicense = targetSource and GetPlayerLicense(targetSource) or nil
    local targetDiscordId = targetSource and GetDiscordIdentifier(targetSource) or nil
    local targetName = targetSource and GetPlayerName(targetSource) or nil

    if payload and payload.target_identifier then
        targetLicense = payload.target_identifier
    end
    if payload and payload.target_name then
        targetName = payload.target_name
    end

    -- Payload JSON
    local payloadJson = json.encode(payload or {})

    -- 1. LOG DATABASE
    if Config.Logging.StaffLogs.Database then
        MySQL.insert('INSERT INTO `z_admin_actions` (`admin_license`, `admin_discord_id`, `admin_rank`, `target_license`, `target_discord_id`, `target_name`, `action_type`, `action_category`, `payload`, `success`, `fail_reason`, `ticket_id`, `server_id`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
            adminLicense,
            adminDiscordId,
            adminPerms.rank,
            targetLicense,
            targetDiscordId,
            targetName,
            actionType,
            actionCategory,
            payloadJson,
            success and 1 or 0,
            failReason,
            ticketId,
            Config.ServerId
        })
    end

    -- 2. LOG CONSOLE
    if Config.Logging.StaffLogs.Console then
        local status = success and '^2SUCCESS^7' or '^1FAIL^7'
        print(string.format(
            '^3[B_ADMIN2 LOG]^7 [%s] %s | Admin: %s (%s) | Target: %s | Action: %s | Payload: %s',
            status,
            actionCategory:upper(),
            adminName,
            adminPerms.rank,
            targetName or 'N/A',
            actionType,
            payloadJson
        ))
    end

    -- 3. LOG DISCORD
    if Config.Logging.StaffLogs.Discord then
        local webhook = Config.Webhooks[actionCategory]
        if webhook then
            local embed = CreateEmbed(
                actionCategory,
                (success and '✅ ' or '❌ ') .. actionType:upper(),
                string.format('**Admin:** %s `%s`\n**Rank:** %s\n**Target:** %s',
                    adminName,
                    adminLicense or 'N/A',
                    adminPerms.rank,
                    targetName or 'N/A'
                ),
                {
                    {
                        name = 'Action',
                        value = actionType,
                        inline = true
                    },
                    {
                        name = 'Statut',
                        value = success and '✅ Succès' or '❌ Échec',
                        inline = true
                    },
                    {
                        name = 'Payload',
                        value = '```json\n' .. payloadJson .. '\n```',
                        inline = false
                    }
                }
            )

            if not success and failReason then
                table.insert(embed.fields, {
                    name = 'Raison de l\'échec',
                    value = failReason,
                    inline = false
                })
            end

            SendDiscordWebhook(webhook, embed)
        end
    end
end

-- ============================================
-- LOG PLAYER ACTION
-- ============================================

--- Log une action joueur (optionnel, perf safe)
---@param source number
---@param actionType string
---@param payload table|nil
---@param suspicious boolean|nil
function LogPlayerAction(source, actionType, payload, suspicious)
    suspicious = suspicious or false

    -- Check si type activé
    local config = Config.Logging.PlayerLogs
    if not config.Database and not config.Discord then
        return
    end

    -- Check si type spécifique activé
    if actionType == 'connect' and not config.LogConnect then return end
    if actionType == 'disconnect' and not config.LogDisconnect then return end
    if actionType == 'vehicle_enter' and not config.LogVehicle then return end
    if actionType == 'weapon_fired' and not config.LogWeaponFired then return end
    if actionType == 'kill' or actionType == 'death' then
        if not config.LogKillDeath then return end
    end
    if actionType:find('inventory') and not config.LogInventory then return end
    if actionType:find('money') and not config.LogMoney then return end
    if actionType == 'command' and not config.LogCommands then return end
    if actionType == 'teleport' and not config.LogTeleport then return end
    if actionType == 'speed' and not config.LogSpeed then return end

    -- Récupération infos
    local license = GetPlayerLicense(source)
    local discordId = GetDiscordIdentifier(source)
    local playerName = GetPlayerName(source)
    local coords = GetEntityCoords(GetPlayerPed(source))
    local zone = GetZoneName(coords)
    local payloadJson = json.encode(payload or {})

    -- 1. LOG DATABASE
    if config.Database then
        MySQL.insert('INSERT INTO `z_player_actions` (`license`, `discord_id`, `player_name`, `action_type`, `payload`, `coords`, `zone`, `suspicious`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            license,
            discordId,
            playerName,
            actionType,
            payloadJson,
            string.format('%.2f, %.2f, %.2f', coords.x, coords.y, coords.z),
            zone,
            suspicious and 1 or 0
        })
    end

    -- 2. LOG CONSOLE
    if config.Console then
        local flag = suspicious and '^1[SUSPECT]^7' or ''
        print(string.format(
            '^6[B_ADMIN2 PLAYER]^7 %s %s | Player: %s | Action: %s | Payload: %s',
            flag,
            playerName,
            license or 'N/A',
            actionType,
            payloadJson
        ))
    end

    -- 3. LOG DISCORD (si activé ET si suspect OU si webhook player_actions configuré)
    if config.Discord and (suspicious or Config.Webhooks.player_actions) then
        local webhook = suspicious and Config.Webhooks.security or Config.Webhooks.player_actions
        if webhook then
            local embed = CreateEmbed(
                suspicious and 'security' or 'player_actions',
                (suspicious and '⚠️ ACTION SUSPECTE: ' or '') .. actionType:upper(),
                string.format('**Joueur:** %s `%s`\n**Zone:** %s',
                    playerName,
                    license or 'N/A',
                    zone
                ),
                {
                    {
                        name = 'Action',
                        value = actionType,
                        inline = true
                    },
                    {
                        name = 'Coords',
                        value = string.format('%.2f, %.2f, %.2f', coords.x, coords.y, coords.z),
                        inline = true
                    },
                    {
                        name = 'Payload',
                        value = '```json\n' .. payloadJson .. '\n```',
                        inline = false
                    }
                }
            )

            SendDiscordWebhook(webhook, embed)
        end
    end

    -- 4. LOG JSONL FILE (optionnel)
    if config.JSONLFile then
        local logEntry = {
            timestamp = os.time(),
            license = license,
            discord_id = discordId,
            player_name = playerName,
            action_type = actionType,
            payload = payload,
            coords = { x = coords.x, y = coords.y, z = coords.z },
            zone = zone,
            suspicious = suspicious
        }
        SaveToJSONL(logEntry)
    end
end

-- ============================================
-- HELPERS
-- ============================================

--- Récupère le nom de la zone depuis des coords
---@param coords vector3
---@return string
function GetZoneName(coords)
    -- NOTE: GetNameOfZone n'existe que client-side
    -- Server-side, on retourne juste "N/A" ou coords
    return string.format("X:%.0f Y:%.0f", coords.x, coords.y)
end

--- Sauvegarde une entrée dans un fichier JSONL
---@param entry table
function SaveToJSONL(entry)
    if not Config.Logging.JSONLPath then return end

    local file = io.open(Config.Logging.JSONLPath, 'a')
    if file then
        file:write(json.encode(entry) .. '\n')
        file:close()
    end
end

-- ============================================
-- EXPORTS
-- ============================================

exports('LogStaffAction', LogStaffAction)
exports('LogPlayerAction', LogPlayerAction)

print('^2[B_ADMIN2]^7 Système de logging chargé ✓')
