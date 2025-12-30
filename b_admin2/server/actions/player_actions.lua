-- ============================================
-- B_ADMIN2 - ACTIONS PLAYER
-- ============================================

--- Goto Player
RegisterNetEvent('badmin:goto', function(targetId)
    local source = source
    if not HasPermission(source, 'admin.player.goto') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local canProceed, err = CheckRateLimit(source, 'goto')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        LogStaffAction(source, nil, 'goto', 'player', { target_id = targetId }, false, 'Joueur introuvable')
        return
    end

    local targetCoords = GetEntityCoords(GetPlayerPed(target))
    TriggerClientEvent('badmin:teleport', source, targetCoords)
    TriggerClientEvent('badmin:notify', source, '✅ Téléporté vers ' .. GetPlayerName(target))

    LogStaffAction(source, target, 'goto', 'player', { coords = targetCoords }, true)
end)

--- Bring Player
RegisterNetEvent('badmin:bring', function(targetId)
    local source = source
    if not HasPermission(source, 'admin.player.bring') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local canProceed, err = CheckRateLimit(source, 'bring')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    local adminCoords = GetEntityCoords(GetPlayerPed(source))
    TriggerClientEvent('badmin:teleport', target, adminCoords)
    TriggerClientEvent('badmin:notify', source, '✅ ' .. GetPlayerName(target) .. ' téléporté vers vous')

    LogStaffAction(source, target, 'bring', 'player', { coords = adminCoords }, true)
end)

--- Freeze/Unfreeze Player
RegisterNetEvent('badmin:freeze', function(targetId, freeze)
    local source = source
    if not HasPermission(source, 'admin.player.freeze') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local canProceed, err = CheckRateLimit(source, 'freeze')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    TriggerClientEvent('badmin:setFreeze', target, freeze)
    TriggerClientEvent('badmin:notify', source, freeze and '🧊 Joueur freeze' or '✅ Joueur unfreeze')

    LogStaffAction(source, target, freeze and 'freeze' or 'unfreeze', 'player', {}, true)
end)

--- Revive Player
RegisterNetEvent('badmin:revive', function(targetId)
    local source = source
    if not HasPermission(source, 'admin.player.revive') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local canProceed, err = CheckRateLimit(source, 'revive')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    TriggerClientEvent('badmin:doRevive', target)
    TriggerClientEvent('badmin:notify', source, '✅ Joueur revive')

    LogStaffAction(source, target, 'revive', 'player', {}, true)
end)

--- Heal Player
RegisterNetEvent('badmin:heal', function(targetId)
    local source = source
    if not HasPermission(source, 'admin.player.heal') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local canProceed, err = CheckRateLimit(source, 'heal')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    TriggerClientEvent('badmin:doHeal', target)
    TriggerClientEvent('badmin:notify', source, '✅ Joueur soigné')

    LogStaffAction(source, target, 'heal', 'player', {}, true)
end)

--- Clear Inventory
RegisterNetEvent('badmin:clearInventory', function(targetId, confirmed)
    local source = source
    if not HasPermission(source, 'admin.player.clearinv') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    if not confirmed then
        TriggerClientEvent('badmin:notify', source, Config.Messages.DoubleConfirmRequired)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    exports.ox_inventory:ClearInventory(target)
    TriggerClientEvent('badmin:notify', source, '✅ Inventaire vidé')

    LogStaffAction(source, target, 'clear_inventory', 'player', {}, true)
end)

--- Set Job
RegisterNetEvent('badmin:setJob', function(targetId, job, grade)
    local source = source
    if not HasPermission(source, 'admin.player.setjob') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then return end

    xTarget.setJob(job, tonumber(grade) or 0)
    TriggerClientEvent('badmin:notify', source, string.format('✅ Job défini: %s [%d]', job, grade))

    LogStaffAction(source, target, 'set_job', 'player', { job = job, grade = grade }, true)
end)

--- Get Player Data (pour NUI)
ESX.RegisterServerCallback('badmin:getPlayerData', function(source, cb, targetId)
    if not HasPermission(source, 'admin.ui.open') then
        cb(nil)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        cb(nil)
        return
    end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then
        cb(nil)
        return
    end

    local ped = GetPlayerPed(target)
    local coords = GetEntityCoords(ped)
    local health = GetEntityHealth(ped)
    local armor = GetPedArmour(ped)

    -- Inventaire ox_inventory
    local inventory = exports.ox_inventory:GetInventory(target)
    local weight = inventory and inventory.weight or 0
    local maxWeight = inventory and inventory.maxWeight or 0
    local items = inventory and inventory.items or {}

    -- Top items
    local topItems = {}
    for slot, item in pairs(items) do
        if item and item.count and item.count > 0 then
            table.insert(topItems, {
                name = item.name,
                label = item.label,
                count = item.count
            })
        end
    end
    table.sort(topItems, function(a, b) return a.count > b.count end)
    topItems = {table.unpack(topItems, 1, 5)} -- Top 5

    -- Loadout (armes)
    local loadout = {}
    for _, weapon in ipairs(xTarget.getLoadout()) do
        table.insert(loadout, {
            name = weapon.name,
            ammo = weapon.ammo
        })
    end

    -- Vehicle actuel
    local vehicle = GetVehiclePedIsIn(ped, false)
    local vehicleData = nil
    if vehicle and vehicle ~= 0 then
        local model = GetEntityModel(vehicle)
        local plate = GetVehicleNumberPlateText(vehicle)
        local speed = GetEntitySpeed(vehicle) * 3.6 -- km/h
        vehicleData = {
            model = model,
            plate = plate,
            speed = math.floor(speed)
        }
    end

    -- Notes staff
    local notes = MySQL.query.await('SELECT `note`, `severity`, `admin_name`, `created_at` FROM `z_admin_notes` WHERE `target_license` = ? ORDER BY `created_at` DESC LIMIT 5', {
        GetPlayerLicense(target)
    })

    -- Historique warns/bans
    local warns = MySQL.query.await('SELECT * FROM `z_admin_warns` WHERE `target_license` = ? ORDER BY `issued_at` DESC LIMIT 5', {
        GetPlayerLicense(target)
    })

    local bans = MySQL.query.await('SELECT * FROM `z_admin_bans` WHERE `target_license` = ? ORDER BY `issued_at` DESC LIMIT 5', {
        GetPlayerLicense(target)
    })

    cb({
        id = target,
        name = GetPlayerName(target),
        license = GetPlayerLicense(target),
        discord = GetDiscordIdentifier(target),
        job = xTarget.job.name,
        grade = xTarget.job.grade,
        coords = { x = coords.x, y = coords.y, z = coords.z },
        zone = GetZoneName(coords),
        health = health,
        armor = armor,
        hunger = 0, -- Fallback (TODO: intégrer esx_status si disponible)
        thirst = 0,
        money = {
            cash = xTarget.getMoney(),
            bank = xTarget.getAccount('bank').money,
            black = xTarget.getAccount('black_money') and xTarget.getAccount('black_money').money or 0
        },
        inventory = {
            weight = weight,
            maxWeight = maxWeight,
            topItems = topItems,
            loadout = loadout
        },
        vehicle = vehicleData,
        notes = notes,
        warns = warns,
        bans = bans,
        ping = GetPlayerPing(target)
    })
end)

print('^2[B_ADMIN2]^7 Actions Player chargées ✓')
