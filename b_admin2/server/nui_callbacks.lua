-- ============================================
-- B_ADMIN2 - NUI CALLBACKS
-- ============================================

-- ============================================
-- GET PLAYERS
-- ============================================

RegisterNUICallback('getPlayers', function(data, cb)
    local source = source

    if not HasPermission(source, 'admin.ui.open') then
        cb({ error = 'No permission' })
        return
    end

    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        local xPlayer = ESX.GetPlayerFromId(id)
        if xPlayer then
            local ped = GetPlayerPed(id)
            local coords = GetEntityCoords(ped)
            local perms = GetPlayerPermissions(id)

            table.insert(players, {
                id = id,
                name = GetPlayerName(id),
                license = GetPlayerLicense(id),
                job = xPlayer.job.label or xPlayer.job.name,
                ping = GetPlayerPing(id),
                coords = { x = coords.x, y = coords.y, z = coords.z },
                isStaff = perms and perms.rank ~= 'user' or false
            })
        end
    end

    cb(players)
end)

-- ============================================
-- GET PLAYER DATA
-- ============================================

RegisterNUICallback('getPlayerData', function(data, cb)
    local source = source
    local playerId = tonumber(data.playerId)

    if not HasPermission(source, 'admin.ui.open') then
        cb({ error = 'No permission' })
        return
    end

    if not playerId or GetPlayerPing(playerId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        cb({ error = 'Player not found' })
        return
    end

    local ped = GetPlayerPed(playerId)
    local coords = GetEntityCoords(ped)
    local health = GetEntityHealth(ped)
    local armor = GetPedArmour(ped)

    -- Inventaire ox_inventory
    local inventory = exports.ox_inventory:GetInventory(playerId)
    local weight = inventory and inventory.weight or 0
    local maxWeight = inventory and inventory.maxWeight or 0

    cb({
        id = playerId,
        name = GetPlayerName(playerId),
        license = GetPlayerLicense(playerId),
        discord = GetDiscordIdentifier(playerId),
        job = xPlayer.job.label or xPlayer.job.name,
        grade = xPlayer.job.grade_label or xPlayer.job.grade,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        zone = GetZoneName(coords),
        health = health,
        armor = armor,
        money = {
            cash = xPlayer.getMoney(),
            bank = xPlayer.getAccount('bank').money,
            black = xPlayer.getAccount('black_money') and xPlayer.getAccount('black_money').money or 0
        },
        inventory = {
            weight = weight,
            maxWeight = maxWeight
        },
        ping = GetPlayerPing(playerId)
    })
end)

-- ============================================
-- PLAYER ACTIONS
-- ============================================

RegisterNUICallback('goto', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)

    if not HasPermission(source, 'admin.player.goto') then
        cb({ error = 'No permission' })
        return
    end

    local canProceed, err = CheckRateLimit(source, 'goto')
    if not canProceed then
        cb({ error = err })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
    TriggerClientEvent('badmin:teleport', source, targetCoords)

    LogStaffAction(source, targetId, 'goto', 'player', { coords = targetCoords }, true)
    cb({ success = true })
end)

RegisterNUICallback('bring', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)

    if not HasPermission(source, 'admin.player.bring') then
        cb({ error = 'No permission' })
        return
    end

    local canProceed, err = CheckRateLimit(source, 'bring')
    if not canProceed then
        cb({ error = err })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    local adminCoords = GetEntityCoords(GetPlayerPed(source))
    TriggerClientEvent('badmin:teleport', targetId, adminCoords)

    LogStaffAction(source, targetId, 'bring', 'player', { coords = adminCoords }, true)
    cb({ success = true })
end)

RegisterNUICallback('spectate', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)

    if not HasPermission(source, 'admin.player.spectate') then
        cb({ error = 'No permission' })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    TriggerClientEvent('badmin:spectatePlayer', source, targetId)

    LogStaffAction(source, targetId, 'spectate', 'player', {}, true)
    cb({ success = true })
end)

RegisterNUICallback('freeze', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)
    local freeze = data.freeze

    if not HasPermission(source, 'admin.player.freeze') then
        cb({ error = 'No permission' })
        return
    end

    local canProceed, err = CheckRateLimit(source, 'freeze')
    if not canProceed then
        cb({ error = err })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    TriggerClientEvent('badmin:setFreeze', targetId, freeze)

    LogStaffAction(source, targetId, freeze and 'freeze' or 'unfreeze', 'player', {}, true)
    cb({ success = true })
end)

RegisterNUICallback('revive', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)

    if not HasPermission(source, 'admin.player.revive') then
        cb({ error = 'No permission' })
        return
    end

    local canProceed, err = CheckRateLimit(source, 'revive')
    if not canProceed then
        cb({ error = err })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    TriggerClientEvent('badmin:doRevive', targetId)

    LogStaffAction(source, targetId, 'revive', 'player', {}, true)
    cb({ success = true })
end)

RegisterNUICallback('heal', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)

    if not HasPermission(source, 'admin.player.heal') then
        cb({ error = 'No permission' })
        return
    end

    local canProceed, err = CheckRateLimit(source, 'heal')
    if not canProceed then
        cb({ error = err })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    TriggerClientEvent('badmin:doHeal', targetId)

    LogStaffAction(source, targetId, 'heal', 'player', {}, true)
    cb({ success = true })
end)

RegisterNUICallback('kick', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)
    local reason = data.reason or 'No reason'

    if not HasPermission(source, 'admin.moderation.kick') then
        cb({ error = 'No permission' })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    -- Trigger moderation kick event
    TriggerEvent('badmin:performKick', source, targetId, reason)

    cb({ success = true })
end)

RegisterNUICallback('warn', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)
    local reason = data.reason or 'No reason'
    local points = tonumber(data.points) or 1

    if not HasPermission(source, 'admin.moderation.warn') then
        cb({ error = 'No permission' })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    -- Trigger moderation warn event
    TriggerEvent('badmin:performWarn', source, targetId, reason, points)

    cb({ success = true })
end)

RegisterNUICallback('ban', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)
    local reason = data.reason or 'No reason'
    local banType = data.banType or 'temp'
    local duration = tonumber(data.duration) or 86400

    if not HasPermission(source, 'admin.moderation.ban') then
        cb({ error = 'No permission' })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    -- Trigger moderation ban event
    TriggerEvent('badmin:performBan', source, targetId, reason, banType, duration)

    cb({ success = true })
end)

RegisterNUICallback('kill', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)

    if not HasPermission(source, 'admin.player.kill') then
        cb({ error = 'No permission' })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    -- Trigger kill event
    TriggerEvent('badmin:kill', source, targetId)

    cb({ success = true })
end)

RegisterNUICallback('noclip', function(data, cb)
    local source = source
    local targetId = data.playerId and tonumber(data.playerId) or nil

    if not HasPermission(source, 'admin.player.noclip') then
        cb({ error = 'No permission' })
        return
    end

    -- Trigger noclip event (nil = pour soi-même)
    TriggerEvent('badmin:noclip', source, targetId)

    cb({ success = true })
end)

RegisterNUICallback('giveCar', function(data, cb)
    local source = source
    local targetId = tonumber(data.playerId)
    local model = data.model or 'adder'

    if not HasPermission(source, 'admin.player.givecar') then
        cb({ error = 'No permission' })
        return
    end

    if not targetId or GetPlayerPing(targetId) == 0 then
        cb({ error = 'Player not found' })
        return
    end

    -- Trigger giveCar event
    TriggerEvent('badmin:giveCar', source, targetId, model)

    cb({ success = true })
end)

-- ============================================
-- STAFF MODE
-- ============================================

RegisterNUICallback('toggleStaffMode', function(data, cb)
    local source = source

    if not HasPermission(source, 'admin.staffmode') then
        cb({ error = 'No permission' })
        return
    end

    -- Trigger the existing staff mode toggle
    TriggerEvent('badmin:toggleStaffMode', source)

    cb({ success = true })
end)

-- ============================================
-- CLOSE MENU
-- ============================================

RegisterNUICallback('close', function(data, cb)
    local source = source

    -- Close is handled client-side, just acknowledge
    cb({ success = true })
end)

print('^2[B_ADMIN2]^7 NUI Callbacks chargés ✓')
