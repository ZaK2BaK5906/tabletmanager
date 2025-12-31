-- ============================================
-- CLIENT POLICE - NUI CALLBACKS COMPLET
-- ============================================

-- ============================================
-- CAD / APPELS 911
-- ============================================

RegisterNUICallback('police_getCalls', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getCalls', function(calls)
        cb(calls)
    end)
end)

RegisterNUICallback('police_getAllCalls', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getAllCalls', function(calls)
        cb(calls)
    end, data.filters)
end)

RegisterNUICallback('police_createCall', function(data, cb)
    TriggerServerEvent('zmdt:police:createCall', data)
    cb('ok')
end)

RegisterNUICallback('police_updateCall', function(data, cb)
    TriggerServerEvent('zmdt:police:updateCall', data.callId, data.status, data.units)
    cb('ok')
end)

RegisterNUICallback('police_closeCall', function(data, cb)
    TriggerServerEvent('zmdt:police:closeCall', data.callId)
    cb('ok')
end)

-- ============================================
-- RECHERCHES
-- ============================================

RegisterNUICallback('police_searchCitizen', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:searchCitizen', function(results)
        cb(results)
    end, data.query)
end)

RegisterNUICallback('police_getCitizenProfile', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getCitizenProfile', function(profile)
        cb(profile)
    end, data.identifier)
end)

RegisterNUICallback('police_addCitizenNote', function(data, cb)
    TriggerServerEvent('zmdt:police:addCitizenNote', data)
    cb('ok')
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

-- ============================================
-- RAPPORTS
-- ============================================

RegisterNUICallback('police_getReports', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getReports', function(reports)
        cb(reports)
    end, data.filters)
end)

RegisterNUICallback('police_getReport', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getReport', function(report)
        cb(report)
    end, data.reportId)
end)

RegisterNUICallback('police_createReport', function(data, cb)
    TriggerServerEvent('zmdt:police:createReport', data)
    cb('ok')
end)

RegisterNUICallback('police_updateReport', function(data, cb)
    TriggerServerEvent('zmdt:police:updateReport', data.reportId, data)
    cb('ok')
end)

-- ============================================
-- ARRESTATIONS
-- ============================================

RegisterNUICallback('police_getArrests', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getArrests', function(arrests)
        cb(arrests)
    end, data.filters)
end)

RegisterNUICallback('police_createArrest', function(data, cb)
    TriggerServerEvent('zmdt:police:createArrest', data)
    cb('ok')
end)

-- ============================================
-- BOLO
-- ============================================

RegisterNUICallback('police_getBOLO', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getBOLO', function(bolos)
        cb(bolos)
    end)
end)

RegisterNUICallback('police_createBOLO', function(data, cb)
    TriggerServerEvent('zmdt:police:createBOLO', data)
    cb('ok')
end)

RegisterNUICallback('police_closeBOLO', function(data, cb)
    TriggerServerEvent('zmdt:police:closeBOLO', data.boloId)
    cb('ok')
end)

-- ============================================
-- CITATIONS / AMENDES
-- ============================================

RegisterNUICallback('police_getCitations', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getCitations', function(citations)
        cb(citations)
    end, data.identifier)
end)

RegisterNUICallback('police_createCitation', function(data, cb)
    TriggerServerEvent('zmdt:police:createCitation', data)
    cb('ok')
end)

-- ============================================
-- PREUVES / EVIDENCE
-- ============================================

RegisterNUICallback('police_getEvidence', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getEvidence', function(evidence)
        cb(evidence)
    end, data.filters)
end)

RegisterNUICallback('police_createEvidence', function(data, cb)
    TriggerServerEvent('zmdt:police:createEvidence', data)
    cb('ok')
end)

-- ============================================
-- PERSONNEL / UNITS
-- ============================================

RegisterNUICallback('police_getUnits', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getUnits', function(units)
        cb(units)
    end)
end)

RegisterNUICallback('police_getOfficerStatus', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getOfficerStatus', function(status)
        cb(status)
    end)
end)

RegisterNUICallback('police_updateStatus', function(data, cb)
    TriggerServerEvent('zmdt:police:updateStatus', data.statusCode, data.location)
    cb('ok')
end)

-- ============================================
-- CHARGES PÉNALES
-- ============================================

RegisterNUICallback('police_getCharges', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getCharges', function(charges)
        cb(charges)
    end, data.filters)
end)

-- ============================================
-- WARRANTS
-- ============================================

RegisterNUICallback('police_getWarrants', function(data, cb)
    ESX.TriggerServerCallback('zmdt:police:getWarrants', function(warrants)
        cb(warrants)
    end, data.identifier)
end)

RegisterNUICallback('police_executeWarrant', function(data, cb)
    TriggerServerEvent('zmdt:police:executeWarrant', data.warrantId)
    cb('ok')
end)

-- ============================================
-- JOUEURS PROCHES (pour citations/arrestations)
-- ============================================

RegisterNUICallback('police_getNearbyPlayers', function(data, cb)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyPlayers = {}

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(playerCoords - targetCoords)

        if distance < (Config.NearbyRadius or 50.0) and player ~= PlayerId() then
            local targetServerId = GetPlayerServerId(player)

            -- Demander les infos du joueur au serveur
            ESX.TriggerServerCallback('zmdt:getNearbyPlayerInfo', function(info)
                if info then
                    table.insert(nearbyPlayers, {
                        serverId = targetServerId,
                        name = info.name,
                        identifier = info.identifier,
                        distance = math.floor(distance)
                    })
                end
            end, targetServerId)
        end
    end

    -- Attendre un peu pour recevoir toutes les réponses
    Citizen.Wait(500)
    cb(nearbyPlayers)
end)

-- ============================================
-- EVENTS SERVEUR → CLIENT
-- ============================================

-- Nouvel appel 911
RegisterNetEvent('zmdt:police:newCall')
AddEventHandler('zmdt:police:newCall', function(call)
    SendNUIMessage({
        action = 'police_newCall',
        call = call
    })

    -- Notification sonore
    PlaySound(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)

    -- Notification visuelle
    ESX.ShowNotification('🚨 Nouvel Appel: ' .. call.call_type .. ' - ' .. call.location)
end)

-- Appel mis à jour
RegisterNetEvent('zmdt:police:callUpdated')
AddEventHandler('zmdt:police:callUpdated', function(data)
    SendNUIMessage({
        action = 'police_callUpdated',
        data = data
    })
end)

-- Appel fermé
RegisterNetEvent('zmdt:police:callClosed')
AddEventHandler('zmdt:police:callClosed', function(callId)
    SendNUIMessage({
        action = 'police_callClosed',
        callId = callId
    })
end)

-- Nouveau BOLO
RegisterNetEvent('zmdt:police:newBOLO')
AddEventHandler('zmdt:police:newBOLO', function(bolo)
    SendNUIMessage({
        action = 'police_newBOLO',
        bolo = bolo
    })

    PlaySound(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)

    local dangerText = ''
    if bolo.danger_level == 'armed_dangerous' then
        dangerText = ' ⚠️ ARMÉ ET DANGEREUX'
    end

    ESX.ShowNotification('⚠️ BOLO: ' .. bolo.subject .. dangerText)
end)

-- BOLO fermé
RegisterNetEvent('zmdt:police:boloClosed')
AddEventHandler('zmdt:police:boloClosed', function(boloId)
    SendNUIMessage({
        action = 'police_boloClosed',
        boloId = boloId
    })
end)

-- Status officier changé
RegisterNetEvent('zmdt:police:statusChanged')
AddEventHandler('zmdt:police:statusChanged', function(data)
    SendNUIMessage({
        action = 'police_statusChanged',
        data = data
    })
end)

-- Rapport créé
RegisterNetEvent('zmdt:police:reportCreated')
AddEventHandler('zmdt:police:reportCreated', function(data)
    ESX.ShowNotification('✅ Rapport créé: ' .. data.report_number)
end)

-- Citation reçue (pour le citoyen)
RegisterNetEvent('zmdt:police:receiveCitation')
AddEventHandler('zmdt:police:receiveCitation', function(data)
    ESX.ShowNotification('~o~Citation Reçue~s~\n' ..
        'Violation: ' .. data.violation .. '\n' ..
        'Montant: $' .. data.fine_amount .. '\n' ..
        'Officier: ' .. data.officer
    )
end)

-- ============================================
-- COMMANDES RAPIDES
-- ============================================

-- /panic - Bouton panique
RegisterCommand('panic', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)

    ESX.TriggerServerCallback('zmdt:police:sendPanic', function(success)
        if success then
            ESX.ShowNotification('🚨 SIGNAL DE DÉTRESSE ENVOYÉ')
            PlaySound(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 0, 0, 1)
        end
    end, {
        location = streetName,
        coords = coords
    })
end)

-- /10-8, /10-7, etc. (Status rapide)
for _, code in ipairs({'10-4', '10-6', '10-7', '10-8', '10-15', '10-20', '10-97', '10-99'}) do
    RegisterCommand(code, function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local streetName = GetStreetNameFromHashKey(streetHash)

        TriggerServerEvent('zmdt:police:updateStatus', code, streetName)
    end)
end

-- /bolo [texte] - BOLO rapide
RegisterCommand(Config.Commands.bolo or 'bolo', function(source, args)
    if #args == 0 then
        ESX.ShowNotification('Usage: /' .. (Config.Commands.bolo or 'bolo') .. ' [description]')
        return
    end

    local description = table.concat(args, ' ')

    TriggerServerEvent('zmdt:police:createBOLO', {
        bolo_type = 'other',
        subject = 'BOLO Rapide',
        description = description,
        priority = 'medium',
        danger_level = 'medium'
    })
end)

print('^2[ZMDT]^0 Police client loaded - FULL SYSTEM')
