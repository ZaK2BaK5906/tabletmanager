-- ============================================
-- B_ADMIN2 - SERVER MAIN
-- ============================================

print('^3[B_ADMIN2]^7 Chargement...')

-- ============================================
-- VEHICLE ACTIONS
-- ============================================

--- Spawn Vehicle
RegisterNetEvent('badmin:spawnVehicle', function(model)
    local source = source
    if not HasPermission(source, 'admin.vehicle.spawn') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local panicMode = MySQL.scalar.await('SELECT `value` FROM `z_admin_config` WHERE `key` = "panic_mode"', {})
    if panicMode == 'true' and Config.PanicMode.DisableVehicleSpawn then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PanicModeActive)
        return
    end

    local canProceed, err = CheckRateLimit(source, 'spawn_vehicle')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    -- Check whitelist
    local perms = GetPlayerPermissions(source)
    if perms.rank ~= 'owner' and perms.rank ~= 'superadmin' then
        local allowed = false
        for _, veh in ipairs(Config.Vehicles.AllowedVehicles) do
            if veh == model then
                allowed = true
                break
            end
        end
        if not allowed then
            TriggerClientEvent('badmin:notify', source, '❌ Véhicule non autorisé')
            return
        end
    end

    TriggerClientEvent('badmin:doSpawnVehicle', source, model)
    TriggerClientEvent('badmin:notify', source, '✅ Véhicule spawn: ' .. model)

    LogStaffAction(source, nil, 'spawn_vehicle', 'player', { model = model }, true)
end)

--- Delete Vehicle
RegisterNetEvent('badmin:deleteVehicle', function()
    local source = source
    if not HasPermission(source, 'admin.vehicle.delete') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    TriggerClientEvent('badmin:doDeleteVehicle', source)
    TriggerClientEvent('badmin:notify', source, '✅ Véhicule supprimé')

    LogStaffAction(source, nil, 'delete_vehicle', 'player', {}, true)
end)

--- Repair/Clean/Flip Vehicle
RegisterNetEvent('badmin:vehicleAction', function(action)
    local source = source
    if not HasPermission(source, 'admin.vehicle.spawn') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    TriggerClientEvent('badmin:doVehicleAction', source, action)
    TriggerClientEvent('badmin:notify', source, '✅ Véhicule ' .. action)

    LogStaffAction(source, nil, 'vehicle_' .. action, 'player', {}, true)
end)

-- ============================================
-- WORLD ACTIONS
-- ============================================

--- Set Time
RegisterNetEvent('badmin:setTime', function(hour, minute)
    local source = source
    if not HasPermission(source, 'admin.world.timeweather') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    hour = tonumber(hour) or 12
    minute = tonumber(minute) or 0

    TriggerClientEvent('badmin:syncTime', -1, hour, minute)
    TriggerClientEvent('badmin:notify', source, string.format('✅ Heure définie: %02d:%02d', hour, minute))

    LogStaffAction(source, nil, 'set_time', 'player', { hour = hour, minute = minute }, true)
end)

--- Set Weather
RegisterNetEvent('badmin:setWeather', function(weather)
    local source = source
    if not HasPermission(source, 'admin.world.timeweather') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    -- Check whitelist
    local allowed = false
    for _, w in ipairs(Config.World.AllowedWeathers) do
        if w == weather then
            allowed = true
            break
        end
    end

    if not allowed then
        TriggerClientEvent('badmin:notify', source, '❌ Météo non autorisée')
        return
    end

    TriggerClientEvent('badmin:syncWeather', -1, weather)
    TriggerClientEvent('badmin:notify', source, '✅ Météo définie: ' .. weather)

    LogStaffAction(source, nil, 'set_weather', 'player', { weather = weather }, true)
end)

-- ============================================
-- DASHBOARD DATA
-- ============================================

ESX.RegisterServerCallback('badmin:getDashboard', function(source, cb)
    if not HasPermission(source, 'admin.ui.open') then
        cb(nil)
        return
    end

    local players = GetPlayers()
    local playersOnline = #players

    local staffOnline = 0
    for _, playerId in ipairs(players) do
        if IsStaff(tonumber(playerId)) then
            staffOnline = staffOnline + 1
        end
    end

    local openReports = MySQL.scalar.await('SELECT COUNT(*) FROM `z_admin_tickets` WHERE `status` IN ("open", "assigned", "in_progress")', {})
    local recentWarns = MySQL.query.await('SELECT * FROM `z_admin_warns` ORDER BY `issued_at` DESC LIMIT 5', {})
    local recentBans = MySQL.query.await('SELECT * FROM `z_admin_bans` ORDER BY `issued_at` DESC LIMIT 5', {})

    -- Panic mode
    local panicMode = MySQL.scalar.await('SELECT `value` FROM `z_admin_config` WHERE `key` = "panic_mode"', {})

    -- Uptime (approximatif via timestamp serveur)
    local uptime = os.time() - (GlobalStartTime or os.time())

    -- Feed activité (dernières actions)
    local activityFeed = MySQL.query.await('SELECT * FROM `z_admin_actions` ORDER BY `performed_at` DESC LIMIT 10', {})

    cb({
        playersOnline = playersOnline,
        staffOnline = staffOnline,
        openReports = openReports or 0,
        recentWarns = recentWarns or {},
        recentBans = recentBans or {},
        panicMode = panicMode == 'true',
        uptime = uptime,
        activityFeed = activityFeed or {}
    })
end)

--- Get All Players (pour player manager)
ESX.RegisterServerCallback('badmin:getPlayers', function(source, cb)
    if not HasPermission(source, 'admin.ui.open') then
        cb({})
        return
    end

    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        local xPlayer = ESX.GetPlayerFromId(id)
        if xPlayer then
            local ped = GetPlayerPed(id)
            local coords = GetEntityCoords(ped)

            table.insert(players, {
                id = id,
                name = GetPlayerName(id),
                license = GetPlayerLicense(id),
                job = xPlayer.job.name,
                grade = xPlayer.job.grade,
                ping = GetPlayerPing(id),
                coords = { x = coords.x, y = coords.y, z = coords.z },
                zone = GetZoneName(coords),
                money = {
                    cash = xPlayer.getMoney(),
                    bank = xPlayer.getAccount('bank').money
                }
            })
        end
    end

    cb(players)
end)

-- ============================================
-- STAFF MODE
-- ============================================

local StaffModePlayers = {}

RegisterNetEvent('badmin:toggleStaffMode', function()
    local source = source
    if not HasPermission(source, 'admin.staffmode') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local enabled = not StaffModePlayers[source]
    StaffModePlayers[source] = enabled

    TriggerClientEvent('badmin:setStaffMode', source, enabled)
    TriggerClientEvent('badmin:notify', source, enabled and Config.Messages.StaffModeEnabled or Config.Messages.StaffModeDisabled)

    LogStaffAction(source, nil, enabled and 'staffmode_on' or 'staffmode_off', 'staffmode', {}, true)
end)

-- ============================================
-- PLAYER LOGGING (EVENTS)
-- ============================================

if Config.Logging.PlayerLogs.LogConnect then
    AddEventHandler('playerConnecting', function(name)
        local source = source
        Citizen.SetTimeout(1000, function()
            LogPlayerAction(source, 'connect', { name = name })
        end)
    end)
end

if Config.Logging.PlayerLogs.LogDisconnect then
    AddEventHandler('playerDropped', function(reason)
        local source = source
        LogPlayerAction(source, 'disconnect', { reason = reason })
    end)
end

-- ============================================
-- INIT
-- ============================================

GlobalStartTime = os.time()

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    print('^2[B_ADMIN2]^7 Ressource chargée avec succès !')
    print('^2[B_ADMIN2]^7 Serveur ID: ^3' .. Config.ServerId)
    print('^2[B_ADMIN2]^7 Webhooks Discord: ^3' .. (Config.Webhooks.moderation and 'Configurés' or 'Non configurés'))
end)
