-- ============================================
-- ZX POLICE MDT - CLIENT
-- ============================================

local mdtOpen = false
local currentData = {}

-- ============================================
-- OUVRIR LA MDT
-- ============================================

function OpenPoliceMDT()
    if mdtOpen then return end
    
    ESX.TriggerServerCallback('zmdt:police:getDashboard', function(dashboard)
        mdtOpen = true
        
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            service = 'police',
            data = {
                dashboard = dashboard,
                user = {
                    name = ESX.PlayerData.name,
                    job = ESX.PlayerData.job.name,
                    job_label = ESX.PlayerData.job.label,
                    grade = ESX.PlayerData.job.grade
                }
            }
        })
    end)
end

-- ============================================
-- FERMER LA MDT
-- ============================================

function ClosePoliceMDT()
    if not mdtOpen then return end
    
    mdtOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'close'})
end

-- ============================================
-- NUI CALLBACKS
-- ============================================

RegisterNUICallback('close', function(data, cb)
    ClosePoliceMDT()
    cb('ok')
end)

-- Dashboard
RegisterNUICallback('getDashboard', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getDashboard', function(result)
        cb(result)
    end)
end)

-- CAD/Calls
RegisterNUICallback('getCalls', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getCalls', function(result)
        cb(result)
    end, data.filters)
end)

RegisterNUICallback('createCall', function(data, cb)
    TriggerServerEvent('zmdt:police:createCall', data)
    cb('ok')
end)

-- Recherche Citoyens
RegisterNUICallback('searchCitizen', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:searchCitizen', function(result)
        cb(result)
    end, data.query)
end)

RegisterNUICallback('getCitizenProfile', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getCitizenProfile', function(result)
        cb(result)
    end, data.identifier)
end)

-- Recherche Véhicules
RegisterNUICallback('searchVehicle', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:searchVehicle', function(result)
        cb(result)
    end, data.plate)
end)

-- BOLO
RegisterNUICallback('getBOLO', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getBOLO', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('createBOLO', function(data, cb)
    TriggerServerEvent('zmdt:police:createBOLO', data)
    cb('ok')
end)

-- Rapports
RegisterNUICallback('getReports', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getReports', function(result)
        cb(result)
    end, data.filters)
end)

RegisterNUICallback('createReport', function(data, cb)
    TriggerServerEvent('zmdt:police:createReport', data)
    cb('ok')
end)

-- Arrestations
RegisterNUICallback('createArrest', function(data, cb)
    TriggerServerEvent('zmdt:police:createArrest', data)
    cb('ok')
end)

-- Citations
RegisterNUICallback('createCitation', function(data, cb)
    TriggerServerEvent('zmdt:police:createCitation', data)
    cb('ok')
end)

-- Mandats
RegisterNUICallback('getWarrants', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getWarrants', function(result)
        cb(result)
    end, data.filters)
end)

RegisterNUICallback('createWarrant', function(data, cb)
    TriggerServerEvent('zmdt:police:createWarrant', data)
    cb('ok')
end)

-- Preuves
RegisterNUICallback('logEvidence', function(data, cb)
    TriggerServerEvent('zmdt:police:logEvidence', data)
    cb('ok')
end)

-- PPA
RegisterNUICallback('issuePPA', function(data, cb)
    TriggerServerEvent('zmdt:police:issuePPA', data)
    cb('ok')
end)

RegisterNUICallback('issuePPAHeavy', function(data, cb)
    TriggerServerEvent('zmdt:police:issuePPAHeavy', data)
    cb('ok')
end)

-- Véhicules Volés
RegisterNUICallback('getStolenVehicles', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getStolenVehicles', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('reportStolenVehicle', function(data, cb)
    TriggerServerEvent('zmdt:police:reportStolenVehicle', data)
    cb('ok')
end)

-- Charges Pénales
RegisterNUICallback('getCharges', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getCharges', function(result)
        cb(result)
    end)
end)

-- Unités
RegisterNUICallback('getUnits', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getUnits', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('updateUnitStatus', function(data, cb)
    TriggerServerEvent('zmdt:police:updateUnitStatus', data.status, data.statusText)
    cb('ok')
end)

-- Notes
RegisterNUICallback('addNote', function(data, cb)
    TriggerServerEvent('zmdt:police:addNote', data)
    cb('ok')
end)

-- ============================================
-- EVENTS SERVEUR
-- ============================================

-- Nouveau BOLO
RegisterNetEvent('zmdt:police:newBOLO', function(bolo)
    if mdtOpen then
        SendNUIMessage({
            action = 'newBOLO',
            data = bolo
        })
    end
    
    -- Notification
    ESX.ShowNotification('~r~[BOLO]~s~ '..bolo.subject..' ('..bolo.priority..')')
end)

-- Nouveau Call
RegisterNetEvent('zmdt:police:callCreated', function(call)
    if mdtOpen then
        SendNUIMessage({
            action = 'newCall',
            data = call
        })
    end
end)

-- Changement statut unité
RegisterNetEvent('zmdt:police:unitStatusChanged', function(data)
    if mdtOpen then
        SendNUIMessage({
            action = 'unitStatusChanged',
            data = data
        })
    end
end)

-- Notification
RegisterNetEvent('zmdt:notify', function(type, message)
    if type == 'success' then
        ESX.ShowNotification('~g~'..message)
    elseif type == 'error' then
        ESX.ShowNotification('~r~'..message)
    else
        ESX.ShowNotification(message)
    end
end)

-- ============================================
-- COMMANDES
-- ============================================

-- Panic Button
if Config.PanicButton.enabled then
    local panicCooldown = 0
    
    RegisterCommand(Config.PanicButton.command, function()
        if GetGameTimer() - panicCooldown < (Config.PanicButton.cooldown * 1000) then
            ESX.ShowNotification('~r~Panic button en cooldown')
            return
        end
        
        panicCooldown = GetGameTimer()
        
        local coords = GetEntityCoords(PlayerPedId())
        local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
        
        TriggerServerEvent('zmdt:police:panicButton', {
            coords = coords,
            street = street,
            officer = ESX.PlayerData.name
        })
        
        ESX.ShowNotification('~r~[PANIC BUTTON]~s~ Signal envoyé!')
    end)
end

-- Commandes rapides (10-8, 10-7, etc.)
for command, action in pairs(Config.QuickCommands) do
    RegisterCommand(command:gsub('/', ''), function()
        if action:find('setStatus') then
            local status = action:gsub('setStatus_', '')
            TriggerServerEvent('zmdt:police:updateUnitStatus', status, nil)
            ESX.ShowNotification('Statut changé: '..status)
        elseif action == 'openBOLO' then
            if mdtOpen then
                SendNUIMessage({action = 'openTab', tab = 'bolo'})
            end
        end
    end)
end

-- ============================================
-- EXPORTS
-- ============================================

exports('OpenPoliceMDT', OpenPoliceMDT)
exports('ClosePoliceMDT', ClosePoliceMDT)

print('^2[ZX Police MDT]^0 Client chargé')
