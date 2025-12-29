-- ============================================
-- CLIENT DOJ - NUI CALLBACKS
-- ============================================

-- Cases / Dossiers
RegisterNUICallback('doj_getCases', function(data, cb)
    ESX.TriggerServerCallback('zmdt:doj:getCases', function(cases)
        cb(cases)
    end)
end)

RegisterNUICallback('doj_createCase', function(data, cb)
    TriggerServerEvent('zmdt:doj:createCase', data)
    cb('ok')
end)

-- Charges
RegisterNUICallback('doj_fileCharges', function(data, cb)
    TriggerServerEvent('zmdt:doj:fileCharges', data)
    cb('ok')
end)

-- Mandats
RegisterNUICallback('doj_createWarrant', function(data, cb)
    TriggerServerEvent('zmdt:doj:createWarrant', data)
    cb('ok')
end)

RegisterNUICallback('doj_approveWarrant', function(data, cb)
    TriggerServerEvent('zmdt:doj:approveWarrant', data.warrantId)
    cb('ok')
end)

-- Audiences
RegisterNUICallback('doj_scheduleHearing', function(data, cb)
    TriggerServerEvent('zmdt:doj:scheduleHearing', data)
    cb('ok')
end)

-- Jugements
RegisterNUICallback('doj_createJudgment', function(data, cb)
    TriggerServerEvent('zmdt:doj:createJudgment', data)
    cb('ok')
end)

-- Events serveur → client
RegisterNetEvent('zmdt:doj:newCase')
AddEventHandler('zmdt:doj:newCase', function(case)
    SendNUIMessage({
        action = 'doj_newCase',
        case = case
    })
end)

print('^2[ZMDT]^0 DOJ client loaded')
