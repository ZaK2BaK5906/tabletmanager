-- ============================================
-- CLIENT POLICE - NUI CALLBACKS
-- ============================================

-- CAD / Appels
RegisterNUICallback('police_getCalls', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getCalls', function(calls)
        cb(calls)
    end)
end)

RegisterNUICallback('police_createCall', function(data, cb)
    TriggerServerEvent('zmdt:police:createCall', data)
    cb('ok')
end)

RegisterNUICallback('police_closeCall', function(data, cb)
    TriggerServerEvent('zmdt:police:closeCall', data.callId)
    cb('ok')
end)

-- Recherches
RegisterNUICallback('police_searchCitizen', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:searchCitizen', function(results)
        cb(results)
    end, data.query)
end)

RegisterNUICallback('police_searchVehicle', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:searchVehicle', function(results)
        cb(results)
    end, data.query)
end)

RegisterNUICallback('police_searchWeapon', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:searchWeapon', function(results)
        cb(results)
    end, data.query)
end)

-- Rapports
RegisterNUICallback('police_createReport', function(data, cb)
    TriggerServerEvent('zmdt:police:createReport', data)
    cb('ok')
end)

RegisterNUICallback('police_getReports', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getReports', function(reports)
        cb(reports)
    end)
end)

-- Arrestations
RegisterNUICallback('police_createArrest', function(data, cb)
    TriggerServerEvent('zmdt:police:createArrest', data)
    cb('ok')
end)

-- BOLO
RegisterNUICallback('police_createBOLO', function(data, cb)
    TriggerServerEvent('zmdt:police:createBOLO', data)
    cb('ok')
end)

RegisterNUICallback('police_getBOLO', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getBOLO', function(bolos)
        cb(bolos)
    end)
end)

-- Preuves
RegisterNUICallback('police_createEvidence', function(data, cb)
    TriggerServerEvent('zmdt:police:createEvidence', data)
    cb('ok')
end)

-- Events serveur → client
RegisterNetEvent('zmdt:police:newCall')
AddEventHandler('zmdt:police:newCall', function(call)
    SendNUIMessage({
        action = 'police_newCall',
        call = call
    })
end)

RegisterNetEvent('zmdt:police:newBOLO')
AddEventHandler('zmdt:police:newBOLO', function(bolo)
    SendNUIMessage({
        action = 'police_newBOLO',
        bolo = bolo
    })
end)

print('^2[ZMDT]^0 Police client loaded')
