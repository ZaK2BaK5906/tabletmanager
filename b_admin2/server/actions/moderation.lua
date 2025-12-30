-- ============================================
-- B_ADMIN2 - MODERATION ACTIONS
-- ============================================

--- Warn Player
RegisterNetEvent('badmin:warn', function(targetId, reason, points)
    local source = source
    if not HasPermission(source, 'admin.mod.warn') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local canProceed, err = CheckRateLimit(source, 'warn')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    if not reason or reason == '' then
        TriggerClientEvent('badmin:notify', source, '❌ Raison requise')
        return
    end

    points = tonumber(points) or 1

    local targetLicense = GetPlayerLicense(target)
    local targetDiscord = GetDiscordIdentifier(target)
    local targetName = GetPlayerName(target)
    local adminLicense = GetPlayerLicense(source)
    local adminName = GetPlayerName(source)

    -- Insert warn
    local result = MySQL.insert.await('INSERT INTO `z_admin_warns` (`target_license`, `target_discord_id`, `target_name`, `admin_license`, `admin_name`, `reason`, `points`, `expires_at`) VALUES (?, ?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL ? DAY))', {
        targetLicense, targetDiscord, targetName, adminLicense, adminName, reason, points, Config.Moderation.WarnExpireDays
    })

    TriggerClientEvent('badmin:notify', target, string.format('⚠️ Vous avez reçu un avertissement: %s [+%d points]', reason, points))
    TriggerClientEvent('badmin:notify', source, '✅ Avertissement envoyé')

    LogStaffAction(source, target, 'warn', 'moderation', { reason = reason, points = points }, true)

    -- Check auto-ban
    local totalPoints = MySQL.scalar.await('SELECT SUM(`points`) FROM `z_admin_warns` WHERE `target_license` = ? AND `is_active` = 1', {
        targetLicense
    })

    if totalPoints and totalPoints >= Config.Moderation.WarnPointsThreshold then
        -- Auto-ban
        TriggerEvent('badmin:ban', source, targetId, 'permanent', 'Auto-ban: Trop de warns (' .. totalPoints .. ' points)')
    end
end)

--- Kick Player
RegisterNetEvent('badmin:kick', function(targetId, reason)
    local source = source
    if not HasPermission(source, 'admin.mod.kick') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local canProceed, err = CheckRateLimit(source, 'kick')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    if not reason or reason == '' then
        reason = 'Aucune raison spécifiée'
    end

    local targetName = GetPlayerName(target)

    DropPlayer(target, '🚫 Vous avez été kick: ' .. reason)
    TriggerClientEvent('badmin:notify', source, '✅ Joueur kick: ' .. targetName)

    LogStaffAction(source, target, 'kick', 'moderation', { reason = reason }, true)
end)

--- Ban Player (temp ou permanent)
RegisterNetEvent('badmin:ban', function(targetId, banType, reason, duration)
    local source = source

    -- Check permissions
    if banType == 'permanent' then
        if not HasPermission(source, 'admin.mod.ban.perma') then
            TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
            return
        end
    else
        if not HasPermission(source, 'admin.mod.ban.temp') then
            TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
            return
        end
    end

    local canProceed, err = CheckRateLimit(source, 'ban')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    local target = tonumber(targetId)
    local targetLicense, targetDiscord, targetName

    -- Target peut être offline (identifier)
    if target and GetPlayerPing(target) > 0 then
        targetLicense = GetPlayerLicense(target)
        targetDiscord = GetDiscordIdentifier(target)
        targetName = GetPlayerName(target)
    else
        -- Offline ban (identifier fourni)
        targetLicense = targetId
        targetName = 'Joueur Offline'
    end

    if not reason or reason == '' then
        reason = 'Aucune raison spécifiée'
    end

    local adminLicense = GetPlayerLicense(source)
    local adminName = GetPlayerName(source)

    local expiresAt = nil
    if banType == 'temp' then
        duration = tonumber(duration) or Config.Moderation.DefaultTempBanDuration
        if duration > Config.Moderation.MaxTempBanDuration then
            duration = Config.Moderation.MaxTempBanDuration
        end
        expiresAt = os.date('%Y-%m-%d %H:%M:%S', os.time() + duration)
    end

    -- Insert ban
    MySQL.insert('INSERT INTO `z_admin_bans` (`target_license`, `target_discord_id`, `target_name`, `admin_license`, `admin_name`, `reason`, `ban_type`, `expires_at`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        targetLicense, targetDiscord, targetName, adminLicense, adminName, reason, banType, expiresAt
    })

    -- Kick si en ligne
    if target and GetPlayerPing(target) > 0 then
        local banMsg = banType == 'permanent' and '🚫 Vous êtes banni définitivement: ' .. reason or string.format('🚫 Vous êtes banni jusqu\'au %s: %s', expiresAt, reason)
        DropPlayer(target, banMsg)
    end

    TriggerClientEvent('badmin:notify', source, '✅ Joueur banni (' .. banType .. ')')

    LogStaffAction(source, target, 'ban_' .. banType, 'moderation', { reason = reason, duration = duration, expires_at = expiresAt }, true)
end)

--- Unban Player
RegisterNetEvent('badmin:unban', function(identifier)
    local source = source
    if not HasPermission(source, 'admin.mod.ban.perma') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    if not identifier or identifier == '' then
        TriggerClientEvent('badmin:notify', source, '❌ Identifier requis')
        return
    end

    local adminLicense = GetPlayerLicense(source)

    MySQL.update('UPDATE `z_admin_bans` SET `is_active` = 0, `unbanned_by` = ?, `unbanned_at` = NOW() WHERE `target_license` = ? AND `is_active` = 1', {
        adminLicense, identifier
    })

    TriggerClientEvent('badmin:notify', source, '✅ Joueur débanni')

    LogStaffAction(source, nil, 'unban', 'moderation', { target_identifier = identifier }, true)
end)

--- Check ban au connect
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    deferrals.defer()

    local source = source
    local license = GetPlayerLicense(source)

    if not license then
        -- Pas de license = laisser passer (ou autre système gère ça)
        deferrals.done()
        return
    end

    Wait(100)

    -- Check ban avec protection (pcall)
    local success, ban = pcall(function()
        return MySQL.query.await('SELECT * FROM `z_admin_bans` WHERE `target_license` = ? AND `is_active` = 1 LIMIT 1', {
            license
        })
    end)

    -- Si MySQL fail ou pas prêt, laisser passer (évite blocage connexions)
    if not success then
        print('^1[B_ADMIN2]^7 Erreur check ban (MySQL pas prêt ?): ' .. tostring(ban))
        deferrals.done()
        return
    end

    if ban and ban[1] then
        local banData = ban[1]
        local now = os.time()
        local expiresAt = banData.expires_at and GetTimestamp(banData.expires_at) or nil

        -- Check si ban expiré
        if banData.ban_type == 'temp' and expiresAt and now >= expiresAt then
            pcall(function()
                MySQL.update('UPDATE `z_admin_bans` SET `is_active` = 0 WHERE `id` = ?', { banData.id })
            end)
            deferrals.done()
            return
        end

        -- Ban actif
        local banMsg = banData.ban_type == 'permanent'
            and string.format('🚫 Vous êtes banni définitivement.\nRaison: %s\nPar: %s', banData.reason, banData.admin_name)
            or string.format('🚫 Vous êtes banni jusqu\'au %s.\nRaison: %s\nPar: %s', banData.expires_at, banData.reason, banData.admin_name)

        deferrals.done(banMsg)
        return
    end

    deferrals.done()
end)

print('^2[B_ADMIN2]^7 Actions Moderation chargées ✓')
