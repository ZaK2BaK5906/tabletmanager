-- ============================================
-- B_ADMIN2 - SPECTATE SYSTÈME
-- ============================================

local isSpectating = false
local spectateTarget = nil
local spectateOverlayData = {}

-- ============================================
-- START/STOP SPECTATE
-- ============================================

RegisterNetEvent('badmin:startSpectate', function(targetId)
    if isSpectating then
        StopSpectate()
    end

    local target = GetPlayerPed(GetPlayerFromServerId(targetId))
    if not target or target == 0 then
        ESX.ShowNotification('❌ Impossible de spectate cette cible')
        return
    end

    isSpectating = true
    spectateTarget = targetId

    local ped = PlayerPedId()

    -- Ghost mode (invincible/invisible/no collision)
    if Config.SpectateSettings.GhostMode then
        SetEntityInvincible(ped, true)
        SetEntityVisible(ped, false, false)
        SetEntityCollision(ped, false, false)
    end

    -- Spectate
    NetworkSetInSpectatorMode(true, target)

    ESX.ShowNotification(Config.Messages.SpectateStarted)

    -- Start overlay thread
    if Config.SpectateSettings.ShowOverlay then
        Citizen.CreateThread(SpectateOverlayThread)
    end

    -- Notif NUI
    SendNUIMessage({
        action = 'spectateStart',
        targetId = targetId
    })
end)

RegisterNetEvent('badmin:stopSpectate', function()
    StopSpectate()
end)

function StopSpectate()
    if not isSpectating then return end

    isSpectating = false
    spectateTarget = nil

    local ped = PlayerPedId()

    -- Restore
    NetworkSetInSpectatorMode(false, ped)
    SetEntityInvincible(ped, false)
    SetEntityVisible(ped, true, false)
    SetEntityCollision(ped, true, true)

    ESX.ShowNotification(Config.Messages.SpectateStopped)

    -- Notif NUI
    SendNUIMessage({
        action = 'spectateStop'
    })
end

-- ============================================
-- SPECTATE OVERLAY THREAD
-- ============================================

function SpectateOverlayThread()
    while isSpectating do
        Citizen.Wait(Config.SpectateOverlayRefresh or 750)

        if not spectateTarget then break end

        local targetPed = GetPlayerPed(GetPlayerFromServerId(spectateTarget))
        if not targetPed or targetPed == 0 then
            StopSpectate()
            break
        end

        -- Récupérer données overlay
        local coords = GetEntityCoords(targetPed)
        local health = GetEntityHealth(targetPed)
        local armor = GetPedArmour(targetPed)
        local zone = GetNameOfZone(coords.x, coords.y, coords.z)
        local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))

        local vehicle = GetVehiclePedIsIn(targetPed, false)
        local vehicleData = nil
        if vehicle ~= 0 then
            local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            local plate = GetVehicleNumberPlateText(vehicle)
            local speed = GetEntitySpeed(vehicle) * 3.6 -- km/h
            vehicleData = {
                model = model,
                plate = plate,
                speed = math.floor(speed)
            }
        end

        spectateOverlayData = {
            health = health,
            armor = armor,
            zone = zone,
            street = street,
            vehicle = vehicleData,
            coords = { x = math.floor(coords.x), y = math.floor(coords.y), z = math.floor(coords.z) }
        }

        -- Envoyer à NUI
        SendNUIMessage({
            action = 'spectateUpdate',
            data = spectateOverlayData
        })
    end
end

-- ============================================
-- DRAW OVERLAY (fallback si NUI fail)
-- ============================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if isSpectating and Config.SpectateSettings.ShowOverlay then
            -- Overlay simple texte (fallback)
            local text = string.format(
                '~b~[SPECTATE]~w~ HP: ~g~%d~w~ | Armor: ~b~%d~w~ | Zone: ~y~%s~w~',
                spectateOverlayData.health or 0,
                spectateOverlayData.armor or 0,
                spectateOverlayData.zone or 'N/A'
            )

            if spectateOverlayData.vehicle then
                text = text .. string.format(' | Véhicule: ~p~%s~w~ (%d km/h)', spectateOverlayData.vehicle.model, spectateOverlayData.vehicle.speed)
            end

            SetTextFont(4)
            SetTextScale(0.4, 0.4)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextEntry('STRING')
            AddTextComponentString(text)
            DrawText(0.5, 0.05)
        end
    end
end)

print('^2[B_ADMIN2]^7 Client Spectate chargé ✓')
