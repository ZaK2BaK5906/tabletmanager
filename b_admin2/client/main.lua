-- ============================================
-- B_ADMIN2 - CLIENT MAIN
-- ============================================

local menuOpen = false

-- ============================================
-- NOTIFICATIONS
-- ============================================

RegisterNetEvent('badmin:notify', function(message)
    ESX.ShowNotification(message)
end)

-- ============================================
-- MENU TOGGLE
-- ============================================

-- Touche F10 (si pas de conflit)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, 57) then -- F10 = 57
            TriggerServerEvent('badmin:requestOpen')
        end
    end
end)

-- Commande alternative
RegisterCommand('badmin', function()
    TriggerServerEvent('badmin:requestOpen')
end, false)

RegisterCommand('admin', function()
    TriggerServerEvent('badmin:requestOpen')
end, false)

-- Event serveur pour ouvrir (après check permissions)
RegisterNetEvent('badmin:openMenu', function()
    OpenMenu()
end)

function OpenMenu()
    if menuOpen then return end
    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'toggle',
        visible = true
    })
    ESX.ShowNotification(Config.Messages.MenuOpened or '📋 Menu admin ouvert')
end

function CloseMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'toggle',
        visible = false
    })
    ESX.ShowNotification(Config.Messages.MenuClosed or '📋 Menu admin fermé')
end

function ToggleMenu()
    if menuOpen then
        CloseMenu()
    else
        TriggerServerEvent('badmin:requestOpen')
    end
end

-- ============================================
-- TELEPORT
-- ============================================

RegisterNetEvent('badmin:teleport', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    ESX.ShowNotification('📍 Téléporté')
end)

-- ============================================
-- FREEZE
-- ============================================

RegisterNetEvent('badmin:setFreeze', function(freeze)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, freeze)
    ESX.ShowNotification(freeze and '🧊 Vous êtes freeze' or '✅ Vous êtes unfreeze')
end)

-- ============================================
-- REVIVE
-- ============================================

RegisterNetEvent('badmin:doRevive', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    -- ESX revive (si disponible)
    if ESX and ESX.PlayerData then
        TriggerEvent('esx_ambulancejob:revive')
    end

    -- Fallback manuel
    SetEntityHealth(ped, 200)
    ClearPedTasksImmediately(ped)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)

    ESX.ShowNotification('💚 Vous avez été revive')
end)

-- ============================================
-- HEAL
-- ============================================

RegisterNetEvent('badmin:doHeal', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ESX.ShowNotification('💊 Vous avez été soigné')
end)

-- ============================================
-- VEHICLE SPAWN
-- ============================================

RegisterNetEvent('badmin:doSpawnVehicle', function(model)
    local hash = GetHashKey(model)

    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(10)
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    SetPedIntoVehicle(ped, vehicle, -1)
    SetVehicleNumberPlateText(vehicle, 'ADMIN')

    SetModelAsNoLongerNeeded(hash)
    ESX.ShowNotification('🚗 Véhicule spawn: ' .. model)
end)

-- ============================================
-- VEHICLE DELETE
-- ============================================

RegisterNetEvent('badmin:doDeleteVehicle', function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        -- Véhicule proche
        local coords = GetEntityCoords(ped)
        vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, Config.Vehicles.DeleteRadius or 5.0, 0, 71)
    end

    if vehicle ~= 0 then
        DeleteVehicle(vehicle)
        ESX.ShowNotification('🗑️ Véhicule supprimé')
    else
        ESX.ShowNotification('❌ Aucun véhicule proche')
    end
end)

-- ============================================
-- VEHICLE ACTIONS
-- ============================================

RegisterNetEvent('badmin:doVehicleAction', function(action)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle == 0 then
        ESX.ShowNotification('❌ Vous devez être dans un véhicule')
        return
    end

    if action == 'repair' then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleUndriveable(vehicle, false)
        ESX.ShowNotification('🔧 Véhicule réparé')
    elseif action == 'clean' then
        SetVehicleDirtLevel(vehicle, 0.0)
        WashDecalsFromVehicle(vehicle, 1.0)
        ESX.ShowNotification('✨ Véhicule nettoyé')
    elseif action == 'flip' then
        local coords = GetEntityCoords(vehicle)
        local heading = GetEntityHeading(vehicle)
        SetEntityCoords(vehicle, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
        SetEntityRotation(vehicle, 0.0, 0.0, heading, 2, true)
        ESX.ShowNotification('🔄 Véhicule retourné')
    end
end)

-- ============================================
-- TIME/WEATHER SYNC
-- ============================================

RegisterNetEvent('badmin:syncTime', function(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
end)

RegisterNetEvent('badmin:syncWeather', function(weather)
    SetWeatherTypeNowPersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypePersist(weather)
end)

-- ============================================
-- NOCLIP
-- ============================================

local noclipEnabled = false
local noclipSpeed = 1.0

RegisterNetEvent('badmin:toggleNoclip', function()
    noclipEnabled = not noclipEnabled

    local ped = PlayerPedId()

    if noclipEnabled then
        ESX.ShowNotification('👻 Noclip activé')
    else
        ESX.ShowNotification('✅ Noclip désactivé')
        -- Reset physics
        FreezeEntityPosition(ped, false)
        SetEntityCollision(ped, true, true)
        SetEntityVisible(ped, true, false)
    end
end)

-- Thread noclip
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if noclipEnabled then
            local ped = PlayerPedId()
            local x, y, z = table.unpack(GetEntityCoords(ped, true))
            local dx, dy, dz = GetCamDirection()
            local speed = noclipSpeed

            -- Modifier la vitesse avec Shift/Ctrl
            if IsControlPressed(0, 21) then -- Shift = plus rapide
                speed = speed * 3.0
            end
            if IsControlPressed(0, 36) then -- Ctrl = plus lent
                speed = speed * 0.3
            end

            -- Désactiver la physique
            FreezeEntityPosition(ped, true)
            SetEntityCollision(ped, false, false)
            SetEntityVisible(ped, false, false)

            -- Mouvement
            if IsControlPressed(0, 32) then -- W = avant
                x = x + dx * speed
                y = y + dy * speed
                z = z + dz * speed
            end
            if IsControlPressed(0, 33) then -- S = arrière
                x = x - dx * speed
                y = y - dy * speed
                z = z - dz * speed
            end
            if IsControlPressed(0, 34) then -- A = gauche
                x = x + (-dy) * speed
                y = y + dx * speed
            end
            if IsControlPressed(0, 35) then -- D = droite
                x = x + dy * speed
                y = y + (-dx) * speed
            end
            if IsControlPressed(0, 44) then -- Q = monter
                z = z + speed
            end
            if IsControlPressed(0, 46) then -- E = descendre
                z = z - speed
            end

            SetEntityCoordsNoOffset(ped, x, y, z, true, true, true)
        else
            Citizen.Wait(500)
        end
    end
end)

function GetCamDirection()
    local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
    local pitch = GetGameplayCamRelativePitch()

    local x = -math.sin(heading * math.pi / 180.0)
    local y = math.cos(heading * math.pi / 180.0)
    local z = math.sin(pitch * math.pi / 180.0)

    local len = math.sqrt(x * x + y * y + z * z)
    if len ~= 0 then
        x = x / len
        y = y / len
        z = z / len
    end

    return x, y, z
end

-- ============================================
-- KILL PLAYER
-- ============================================

RegisterNetEvent('badmin:doKill', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
    ESX.ShowNotification('💀 Vous avez été tué')
end)

-- ============================================
-- KEYS MAPPING
-- ============================================

Keys = {
    ['F10'] = 57,
    ['ESC'] = 322,
    ['E'] = 38
}

print('^2[B_ADMIN2]^7 Client Main chargé ✓')
