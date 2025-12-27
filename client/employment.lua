-- ============================================
-- CLIENT: Système de Recrutement/Emploi
-- ============================================

local isEmploymentOpen = false

-- Commande /emploie
RegisterCommand('emploie', function()
    OpenEmploymentMenu()
end, false)

-- RegisterKeyMapping pour permettre aux joueurs de configurer leur touche
RegisterKeyMapping('emploie', 'Ouvrir le menu Emploi', 'keyboard', '')

-- Ouvrir le menu emploi
function OpenEmploymentMenu()
    if isEmploymentOpen then return end

    ESX.TriggerServerCallback('employment:getCompanies', function(data)
        if not data then return end

        isEmploymentOpen = true

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openEmployment',
            companies = data.companies,
            isBoss = data.isBoss,
            currentJob = data.currentJob,
            currentJobLabel = data.currentJobLabel,
            isRecruiting = data.isRecruiting
        })
    end)
end

-- Fermer le menu emploi
RegisterNUICallback('closeEmployment', function(data, cb)
    isEmploymentOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Soumettre une candidature
RegisterNUICallback('submitApplication', function(data, cb)
    TriggerServerEvent('employment:submitApplication', data)
    cb('ok')
end)

-- Obtenir le profil de l'entreprise (Boss)
RegisterNUICallback('getCompanyProfile', function(data, cb)
    ESX.TriggerServerCallback('employment:getCompanyProfile', function(profile)
        SendNUIMessage({
            action = 'receiveCompanyProfile',
            profile = profile
        })
    end)
    cb('ok')
end)

-- Mettre à jour le profil de l'entreprise (Boss)
RegisterNUICallback('updateCompanyProfile', function(data, cb)
    TriggerServerEvent('employment:updateCompanyProfile', data)
    cb('ok')
end)

-- Toggle recrutement (Boss)
RegisterNUICallback('toggleRecruitment', function(data, cb)
    TriggerServerEvent('employment:toggleRecruitment')
    cb('ok')
end)

-- Obtenir les candidatures (Boss)
RegisterNUICallback('getApplications', function(data, cb)
    ESX.TriggerServerCallback('employment:getApplications', function(applications)
        SendNUIMessage({
            action = 'updateApplications',
            applications = applications
        })
    end)
    cb('ok')
end)

-- Traiter une candidature (Boss)
RegisterNUICallback('processApplication', function(data, cb)
    TriggerServerEvent('employment:processApplication', data)
    cb('ok')
end)

-- Events du serveur
RegisterNetEvent('employment:showNotification')
AddEventHandler('employment:showNotification', function(message, type)
    SendNUIMessage({
        action = 'showNotification',
        message = message,
        type = type or 'info'
    })

    -- Afficher aussi avec ESX
    ESX.ShowNotification(message)
end)

RegisterNetEvent('employment:refreshCompanies')
AddEventHandler('employment:refreshCompanies', function(companies)
    if isEmploymentOpen then
        SendNUIMessage({
            action = 'updateCompanies',
            companies = companies
        })
    end
end)

RegisterNetEvent('employment:refreshApplications')
AddEventHandler('employment:refreshApplications', function(applications)
    if isEmploymentOpen then
        SendNUIMessage({
            action = 'updateApplications',
            applications = applications
        })
    end
end)
