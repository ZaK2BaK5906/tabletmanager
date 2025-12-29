-- ============================================
-- CLIENT EMS - NUI CALLBACKS
-- ============================================

-- Dispatch
RegisterNUICallback('ems_getCalls', function(data, cb)
    ESX.TriggerServerCallback('zmdt:ems:getCalls', function(calls)
        cb(calls)
    end)
end)

RegisterNUICallback('ems_createCall', function(data, cb)
    TriggerServerEvent('zmdt:ems:createCall', data)
    cb('ok')
end)

-- Patients
RegisterNUICallback('ems_searchPatient', function(data, cb)
    ESX.TriggerServerCallback('zmdt:ems:searchPatient', function(results)
        cb(results)
    end, data.query)
end)

RegisterNUICallback('ems_createPatient', function(data, cb)
    TriggerServerEvent('zmdt:ems:createPatient', data)
    cb('ok')
end)

-- ePCR / Rapports médicaux
RegisterNUICallback('ems_createEPCR', function(data, cb)
    TriggerServerEvent('zmdt:ems:createEPCR', data)
    cb('ok')
end)

RegisterNUICallback('ems_getEPCR', function(data, cb)
    ESX.TriggerServerCallback('zmdt:ems:getEPCR', function(epcr)
        cb(epcr)
    end)
end)

-- 5150 Holds
RegisterNUICallback('ems_create5150', function(data, cb)
    TriggerServerEvent('zmdt:ems:create5150', data)
    cb('ok')
end)

-- Certificats
RegisterNUICallback('ems_createCertificate', function(data, cb)
    TriggerServerEvent('zmdt:ems:createCertificate', data)
    cb('ok')
end)

-- Events serveur → client
RegisterNetEvent('zmdt:ems:newCall')
AddEventHandler('zmdt:ems:newCall', function(call)
    SendNUIMessage({
        action = 'ems_newCall',
        call = call
    })
end)

print('^2[ZMDT]^0 EMS client loaded')
