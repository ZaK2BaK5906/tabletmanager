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
            local targetId = GetPlayerServerId(data.entity)
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
            local targetId = GetPlayerServerId(data.entity)
            -- Ouvrir menu de sélection de véhicule
            ESX.TriggerServerCallback('dealership:getVehicleStock', function(vehicles)
                if vehicles and #vehicles > 0 then
                    openVehicleAssignMenu(targetId, vehicles)
                else
                    ESX.ShowNotification('❌ Aucun véhicule en stock')
                end
            end)
        end
    }
    })
end)

-- Menu pour assigner un véhicule
function openVehicleAssignMenu(targetId, vehicles)
    local elements = {}

    for _, vehicle in ipairs(vehicles) do
        table.insert(elements, {
            label = string.format('%s ($%s) - Stock: %d', vehicle.name, vehicle.price, vehicle.stock),
            value = vehicle.model,
            vehicleName = vehicle.name
        })
    end

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'assign_vehicle', {
        title = 'Assigner un Véhicule',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        local vehicleModel = data.current.value
        local vehicleName = data.current.vehicleName

        -- Demander la plaque
        ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'vehicle_plate', {
            title = 'Plaque du véhicule (optionnel)'
        }, function(data2, menu2)
            local plate = data2.value or ''
            menu2.close()
            menu.close()

            -- Confirmer
            ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'confirm_assign', {
                title = 'Confirmer l\'assignation ?',
                align = 'top-left',
                elements = {
                    {label = '✅ Oui', value = 'yes'},
                    {label = '❌ Non', value = 'no'}
                }
            }, function(data3, menu3)
                if data3.current.value == 'yes' then
                    TriggerServerEvent('dealership:assignVehicle', targetId, vehicleModel, plate)
                end
                menu3.close()
            end, function(data3, menu3)
                menu3.close()
            end)
        end, function(data2, menu2)
            menu2.close()
        end)
    end, function(data, menu)
        menu.close()
    end)
end

print('^2[Dealership]^0 Client chargé')
