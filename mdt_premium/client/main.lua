local ESX = exports['es_extended']:getSharedObject()
local isTabletOpen = false
local PlayerData = {}

-- Get PlayerData on resource start
CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Wait(100)
    end
    PlayerData = ESX.GetPlayerData()
end)

-- Update PlayerData on job change
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- Toggle Tablet Command
RegisterCommand('mdt', function()
    ToggleTablet()
end, false)

-- Keybind (F6 par défaut, configurable)
RegisterKeyMapping('mdt', 'Ouvrir la tablette MDT', 'keyboard', 'F6')

-- Toggle Tablet Function
function ToggleTablet()
    if not PlayerData.job then return end

    -- Check if player has authorized job
    local authorizedJobs = {
        'cardealer', 'concessionnaire', 'dealership',
        'doj', 'judge', 'justice'
    }

    local hasAccess = false
    for _, job in pairs(authorizedJobs) do
        if PlayerData.job.name == job then
            hasAccess = true
            break
        end
    end

    if not hasAccess then
        ESX.ShowNotification('~r~Vous n\'avez pas accès à cette tablette')
        return
    end

    isTabletOpen = not isTabletOpen
    SetNuiFocus(isTabletOpen, isTabletOpen)

    if isTabletOpen then
        -- Send player data to NUI
        ESX.TriggerServerCallback('mdt_premium:getPlayerData', function(data)
            SendNUIMessage({
                action = 'openTablet',
                data = data
            })
        end)
    else
        SendNUIMessage({
            action = 'closeTablet'
        })
    end
end

-- Close Tablet (from NUI)
RegisterNUICallback('closeTablet', function(data, cb)
    ToggleTablet()
    cb('ok')
end)

-- Get Nearest Player
RegisterNUICallback('getNearestPlayer', function(data, cb)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer(playerCoords)

    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        local targetServerId = GetPlayerServerId(closestPlayer)
        ESX.TriggerServerCallback('mdt_premium:getPlayerInfo', function(playerInfo)
            if playerInfo then
                cb({
                    success = true,
                    player = {
                        id = targetServerId,
                        name = playerInfo.name,
                        distance = closestDistance
                    }
                })
            else
                cb({ success = false })
            end
        end, targetServerId)
    else
        ESX.ShowNotification('~r~Aucun joueur proche')
        cb({ success = false })
    end
end)

-- Get Player By ID
RegisterNUICallback('getPlayerById', function(data, cb)
    local playerId = tonumber(data.playerId)

    if not playerId then
        cb({ success = false })
        return
    end

    ESX.TriggerServerCallback('mdt_premium:getPlayerInfo', function(playerInfo)
        if playerInfo then
            cb({
                success = true,
                player = {
                    id = playerId,
                    name = playerInfo.name,
                    distance = nil
                }
            })
        else
            ESX.ShowNotification('~r~Joueur introuvable')
            cb({ success = false })
        end
    end, playerId)
end)

-- Create Invoice
RegisterNUICallback('createInvoice', function(data, cb)
    ESX.TriggerServerCallback('mdt_premium:createInvoice', function(success, message)
        if success then
            ESX.ShowNotification('~g~Facture créée avec succès')
            cb({ success = true })
        else
            ESX.ShowNotification('~r~' .. (message or 'Erreur lors de la création'))
            cb({ success = false, message = message })
        end
    end, data)
end)

-- Purchase Vehicle (Dealership)
RegisterNUICallback('purchaseVehicle', function(data, cb)
    ESX.TriggerServerCallback('mdt_premium:purchaseVehicle', function(success, message)
        if success then
            ESX.ShowNotification('~g~Véhicule acheté avec succès')
            cb({ success = true })
        else
            ESX.ShowNotification('~r~' .. (message or 'Erreur lors de l\'achat'))
            cb({ success = false, message = message })
        end
    end, data)
end)

-- Pay Commission
RegisterNUICallback('payCommission', function(data, cb)
    ESX.TriggerServerCallback('mdt_premium:payCommission', function(success, message)
        if success then
            ESX.ShowNotification('~g~Commission payée avec succès')
            cb({ success = true })
        else
            ESX.ShowNotification('~r~' .. (message or 'Erreur lors du paiement'))
            cb({ success = false, message = message })
        end
    end, data)
end)

-- Pay Taxes (DOJ)
RegisterNUICallback('payTaxes', function(data, cb)
    ESX.TriggerServerCallback('mdt_premium:payTaxes', function(success, message)
        if success then
            ESX.ShowNotification('~g~Taxes payées avec succès')
            cb({ success = true })
        else
            ESX.ShowNotification('~r~' .. (message or 'Erreur lors du paiement'))
            cb({ success = false, message = message })
        end
    end, data)
end)

-- Update Tax Rate (DOJ Only)
RegisterNUICallback('updateTaxRate', function(data, cb)
    ESX.TriggerServerCallback('mdt_premium:updateTaxRate', function(success, message)
        if success then
            ESX.ShowNotification('~g~Taux de taxe mis à jour')
            cb({ success = true })
        else
            ESX.ShowNotification('~r~' .. (message or 'Accès refusé'))
            cb({ success = false, message = message })
        end
    end, data)
end)

-- Disable controls while tablet is open
CreateThread(function()
    while true do
        Wait(0)
        if isTabletOpen then
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 257, true) -- Attack 2
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 263, true) -- Melee Attack 1
            DisableControlAction(0, 32, true) -- W
            DisableControlAction(0, 34, true) -- A
            DisableControlAction(0, 31, true) -- S
            DisableControlAction(0, 30, true) -- D
        end
    end
end)
