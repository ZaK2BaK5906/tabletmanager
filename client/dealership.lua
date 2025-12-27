-- ============================================
-- CLIENT DEALERSHIP - OX_TARGET INTERACTIONS
-- ============================================

CreateThread(function()
    -- Attendre que ESX soit prêt
    while not ESX.PlayerLoaded do
        Wait(100)
    end

    -- Options ox_target pour les citoyens
    exports.ox_target:addGlobalPlayer({
    {
        name = 'tablet_create_invoice',
        icon = 'fa-solid fa-file-invoice-dollar',
        label = 'Créer une Facture',
        canInteract = function(entity, distance, coords, name, bone)
            local playerData = ESX.GetPlayerData()
            -- Tous les jobs peuvent créer des factures
            return playerData.job and playerData.job.name ~= 'unemployed'
        end,
        onSelect = function(data)
            local targetPed = data.entity
            local targetPlayerId = NetworkGetPlayerIndexFromPed(targetPed)
            local targetId = GetPlayerServerId(targetPlayerId)

            ESX.TriggerServerCallback('tablet:getPlayerInfo', function(playerInfo)
                if playerInfo then
                    -- Ouvrir la tablette sur la page facture avec infos pré-remplies
                    SendNUIMessage({
                        action = 'openForSale',
                        targetId = targetId,
                        targetName = playerInfo.name
                    })
                end
            end, targetId)
        end
    },
    {
        name = 'dealership_assign_vehicle',
        icon = 'fa-solid fa-car',
        label = 'Assigner un Véhicule',
        canInteract = function(entity, distance, coords, name, bone)
            local playerData = ESX.GetPlayerData()
            -- Seulement dealership peut assigner des véhicules
            return playerData.job and playerData.job.name == 'dealership'
        end,
        onSelect = function(data)
            local targetPed = data.entity
            local targetPlayerId = NetworkGetPlayerIndexFromPed(targetPed)
            local targetId = GetPlayerServerId(targetPlayerId)

            -- Récupérer le nom du joueur
            ESX.TriggerServerCallback('tablet:getPlayerInfo', function(playerInfo)
                if not playerInfo then
                    ESX.ShowNotification('❌ Joueur introuvable')
                    return
                end

                -- Ouvrir menu de sélection de véhicule
                ESX.TriggerServerCallback('dealership:getVehicleStock', function(vehicles)
                    if vehicles and #vehicles > 0 then
                        -- Ouvrir le menu NUI custom
                        SendNUIMessage({
                            action = 'openAssignVehicle',
                            targetId = targetId,
                            targetName = playerInfo.name,
                            vehicles = vehicles
                        })
                        SetNuiFocus(true, true)
                    else
                        ESX.ShowNotification('❌ Aucun véhicule en stock')
                    end
                end)
            end, targetId)
        end
    }
    })
end)

-- Callbacks NUI pour le menu d'assignation
RegisterNUICallback('assignVehicleConfirm', function(data, cb)
    TriggerServerEvent('dealership:assignVehicle', data.targetId, data.vehicleModel, data.plate)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('closeAssignMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

print('^2[Dealership]^0 Client chargé')
