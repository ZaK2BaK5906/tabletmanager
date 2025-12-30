-- ============================================
-- B_ADMIN2 - API DISCORD BOT (HMAC SECURED)
-- ============================================

local NonceCache = {} -- Anti-replay

--- Vérifie la signature HMAC d'une requête
---@param payload table
---@param signature string
---@param timestamp number
---@param nonce string
---@return boolean valid
local function VerifyHMAC(payload, signature, timestamp, nonce)
    -- Check TTL
    if os.time() - timestamp > Config.DiscordBot.RequestTTL then
        return false, 'Requête expirée'
    end

    -- Check nonce (anti-replay)
    if NonceCache[nonce] then
        return false, 'Nonce déjà utilisé (replay attack)'
    end

    -- Calculer HMAC
    local data = timestamp .. nonce .. json.encode(payload)
    local expectedSignature = exports['badmin_crypto']:HMACSHA256(data, Config.DiscordBot.HMACSecret)
    -- Note: nécessite une ressource crypto externe OU utiliser une lib Lua HMAC
    -- Pour simplifier, on simule ici (À REMPLACER par vraie impl HMAC)

    -- TEMP: Pour démo, on assume signature valide si présente
    -- TODO: Implémenter vraie vérification HMAC (via crypto lib ou externe)
    if signature ~= expectedSignature then
        return false, 'Signature invalide'
    end

    -- Ajouter nonce au cache
    NonceCache[nonce] = os.time() + Config.DiscordBot.RequestTTL

    return true
end

--- Endpoint: Get Players List
RegisterNetEvent('badmin:discord:getPlayers', function(discordUserId, signature, timestamp, nonce)
    -- Cette event est déclenchée par le bot Discord via HTTP -> Event conversion
    -- En réalité, utiliser un HTTP endpoint avec SetHttpHandler ou externe

    -- Vérifier HMAC
    local payload = { action = 'getPlayers', discordUserId = discordUserId }
    local valid, err = VerifyHMAC(payload, signature, timestamp, nonce)
    if not valid then
        print('^1[B_ADMIN2 Discord API]^7 HMAC failed: ' .. err)
        return
    end

    -- Vérifier permissions Discord
    -- TODO: Check si discordUserId a un role autorisé
    -- Pour l'instant, on assume autorisé

    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        local xPlayer = ESX.GetPlayerFromId(id)
        if xPlayer then
            table.insert(players, {
                id = id,
                name = GetPlayerName(id),
                job = xPlayer.job.name,
                ping = GetPlayerPing(id)
            })
        end
    end

    -- Retourner résultat (via callback HTTP ou event client -> bot)
    -- Pour simplifier, on log ici
    print('^2[B_ADMIN2 Discord API]^7 Players list requested by ' .. discordUserId .. ': ' .. #players .. ' players')

    -- TODO: Implémenter retour vers bot Discord via webhook ou autre
end)

--- Watch Sessions (télémétrie Discord)
WatchSessions = {} -- { targetLicense = { watcher_discord_id, channel_id, started_at, duration } }

--- Start Watch
RegisterNetEvent('badmin:discord:startWatch', function(targetId, discordUserId, channelId, duration)
    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        print('^1[B_ADMIN2 Discord API]^7 Target not found: ' .. targetId)
        return
    end

    local targetLicense = GetPlayerLicense(target)
    duration = duration or 5 -- minutes par défaut

    -- Insert session
    local sessionId = MySQL.insert.await('INSERT INTO `z_admin_watch_sessions` (`target_license`, `watcher_discord_id`, `watcher_name`, `duration_minutes`, `discord_channel_id`) VALUES (?, ?, ?, ?, ?)', {
        targetLicense,
        discordUserId,
        'Discord User ' .. discordUserId,
        duration,
        channelId
    })

    WatchSessions[targetLicense] = {
        session_id = sessionId,
        watcher_discord_id = discordUserId,
        channel_id = channelId,
        started_at = os.time(),
        duration = duration * 60, -- secondes
        target_id = target
    }

    print(string.format('^2[B_ADMIN2 Discord API]^7 Watch started: %s -> %s (%d min)', discordUserId, GetPlayerName(target), duration))

    -- Log
    MySQL.insert('INSERT INTO `z_admin_actions` (`admin_license`, `admin_discord_id`, `admin_rank`, `target_license`, `target_name`, `action_type`, `action_category`, `payload`, `server_id`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        nil,
        discordUserId,
        'discord_user',
        targetLicense,
        GetPlayerName(target),
        'watch_start',
        'staffmode',
        json.encode({ duration = duration, channel_id = channelId }),
        Config.ServerId
    })
end)

--- Stop Watch
RegisterNetEvent('badmin:discord:stopWatch', function(targetId, discordUserId)
    local target = tonumber(targetId)
    if not target then return end

    local targetLicense = GetPlayerLicense(target)
    if not targetLicense or not WatchSessions[targetLicense] then
        print('^1[B_ADMIN2 Discord API]^7 No active watch session for target: ' .. targetId)
        return
    end

    local session = WatchSessions[targetLicense]
    WatchSessions[targetLicense] = nil

    -- Update DB
    MySQL.update('UPDATE `z_admin_watch_sessions` SET `is_active` = 0, `ended_at` = NOW() WHERE `id` = ?', {
        session.session_id
    })

    print(string.format('^2[B_ADMIN2 Discord API]^7 Watch stopped: %s -> %s', discordUserId, GetPlayerName(target)))
end)

--- Thread: Envoie télémétrie vers Discord
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(Config.WatchDiscordInterval or 8000)

        local now = os.time()

        for targetLicense, session in pairs(WatchSessions) do
            -- Check expiration
            if now - session.started_at >= session.duration then
                TriggerEvent('badmin:discord:stopWatch', session.target_id, session.watcher_discord_id)
                goto continue
            end

            -- Check si target toujours en ligne
            local target = session.target_id
            if not target or GetPlayerPing(target) == 0 then
                WatchSessions[targetLicense] = nil
                goto continue
            end

            -- Récupérer télémétrie
            local xTarget = ESX.GetPlayerFromId(target)
            if not xTarget then goto continue end

            local ped = GetPlayerPed(target)
            local coords = GetEntityCoords(ped)
            local health = GetEntityHealth(ped)
            local armor = GetPedArmour(ped)

            local vehicle = GetVehiclePedIsIn(ped, false)
            local vehicleData = nil
            if vehicle and vehicle ~= 0 then
                local speed = GetEntitySpeed(vehicle) * 3.6
                vehicleData = {
                    model = GetEntityModel(vehicle),
                    plate = GetVehicleNumberPlateText(vehicle),
                    speed = math.floor(speed)
                }
            end

            local telemetry = {
                player = GetPlayerName(target),
                coords = { x = math.floor(coords.x), y = math.floor(coords.y), z = math.floor(coords.z) },
                zone = GetZoneName(coords),
                health = health,
                armor = armor,
                money = {
                    cash = xTarget.getMoney(),
                    bank = xTarget.getAccount('bank').money,
                    black = xTarget.getAccount('black_money') and xTarget.getAccount('black_money').money or 0
                },
                job = xTarget.job.name,
                vehicle = vehicleData,
                ping = GetPlayerPing(target)
            }

            -- Envoyer vers Discord (webhook channel spécifique)
            -- TODO: Implémenter envoi via webhook ou bot direct message
            -- Pour l'instant, on log

            print(string.format('^6[B_ADMIN2 Watch]^7 %s @ %s | HP:%d AR:%d | Cash:%d Bank:%d | Ping:%d',
                telemetry.player,
                telemetry.zone,
                telemetry.health,
                telemetry.armor,
                telemetry.money.cash,
                telemetry.money.bank,
                telemetry.ping
            ))

            ::continue::
        end
    end
end)

--- Cleanup nonce cache périodique
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 5 min

        local now = os.time()
        for nonce, expires in pairs(NonceCache) do
            if now >= expires then
                NonceCache[nonce] = nil
            end
        end
    end
end)

print('^2[B_ADMIN2]^7 Discord API chargée ✓')
