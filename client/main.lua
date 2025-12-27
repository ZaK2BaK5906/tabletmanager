ESX = exports['es_extended']:getSharedObject()
local isTabletOpen = false

-- Récupérer les données du joueur
CreateThread(function()
    while ESX.GetPlayerData().job == nil do
        Wait(100)
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

-- Vérifier si le joueur est boss
function IsBoss()
    local PlayerData = ESX.GetPlayerData()
    if not PlayerData.job then return false end

    for _, grade in ipairs(Config.BossGrades) do
        if PlayerData.job.grade_name == grade then
            return true
        end
    end
    return false
end

-- Vérifier si le joueur a accès audit (DOJ)
function HasAuditAccess()
    local PlayerData = ESX.GetPlayerData()
    if not PlayerData.job then return false end

    for _, job in ipairs(Config.AuditJobs) do
        if PlayerData.job.name == job then
            return true
        end
    end
    return false
end

-- Récupérer les joueurs proches
function GetNearbyPlayers()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearbyPlayers = {}

    local players = GetActivePlayers()
    for _, playerId in ipairs(players) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)

            if distance <= Config.NearbyPlayerRadius then
                local serverID = GetPlayerServerId(playerId)
                local playerName = GetPlayerName(playerId)
                table.insert(nearbyPlayers, {
                    id = serverID,
                    name = playerName
                })
            end
        end
    end

    return nearbyPlayers
end

-- Ouvrir la tablette
function OpenTablet()
    if isTabletOpen then return end

    local PlayerData = ESX.GetPlayerData()

    -- Vérification du job
    if not PlayerData.job then
        ShowNotification(Config.Translations['no_job'], 'info')
        return
    end

    if PlayerData.job.name == 'unemployed' then
        ShowNotification(Config.Translations['no_job'], 'info')
        return
    end

    isTabletOpen = true
    local isBoss = IsBoss()
    local hasAudit = HasAuditAccess()
    local nearbyPlayers = GetNearbyPlayers()

    -- Récupérer les données du joueur
    ESX.TriggerServerCallback('tablet:getPlayerData', function(playerData)
        if not playerData then
            CloseTablet()
            return
        end

        SendNUIMessage({
            action = 'open',
            job = PlayerData.job.name,
            jobLabel = PlayerData.job.label,
            userName = GetPlayerName(PlayerId()),
            isBoss = isBoss,
            hasAuditAccess = hasAudit,
            commission = playerData.commission or Config.DefaultCommission,
            products = playerData.products or {},
            partnerships = playerData.partnerships or {},
            companies = playerData.companies or {},
            taxRate = Config.TaxRate,
            nearbyPlayers = nearbyPlayers
        })

        SetNuiFocus(true, true)
    end)
end

-- Fermer la tablette
function CloseTablet()
    if not isTabletOpen then return end

    isTabletOpen = false
    SetNuiFocus(false, false)

    -- Petit délai pour s'assurer que tout est bien fermé
    Wait(100)
    SendNUIMessage({ action = 'close' })
end

-- Commande /tablette
RegisterCommand(Config.Command, function()
    OpenTablet()
end, false)

-- Keymapping pour la tablette (bindable dans paramètres FiveM)
RegisterKeyMapping(Config.Command, 'Ouvrir la tablette de gestion', 'keyboard', '')

-- Commande /facture
RegisterCommand('facture', function()
    ESX.TriggerServerCallback('tablet:getPendingInvoices', function(invoices)
        if not invoices or #invoices == 0 then
            ShowNotification('📄 Vous n\'avez aucune facture en attente', 'info')
            return
        end

        SendNUIMessage({
            action = 'openInvoiceMenu',
            invoices = invoices
        })

        SetNuiFocus(true, true)
    end)
end, false)

-- Keymapping pour les factures (bindable dans paramètres FiveM)
RegisterKeyMapping('facture', 'Ouvrir mes factures en attente', 'keyboard', '')

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    CloseTablet()
    cb('ok')
end)

RegisterNUICallback('getQuickStats', function(data, cb)
    ESX.TriggerServerCallback('tablet:getQuickStats', function(stats)
        cb(stats)
    end)
end)

RegisterNUICallback('getInvoiceHistory', function(data, cb)
    ESX.TriggerServerCallback('tablet:getInvoiceHistory', function(invoices)
        SendNUIMessage({
            action = 'receiveInvoiceHistory',
            invoices = invoices
        })
    end)
    cb('ok')
end)

RegisterNUICallback('getStats', function(data, cb)
    ESX.TriggerServerCallback('tablet:getStats', function(stats)
        SendNUIMessage({
            action = 'receiveStats',
            stats = stats
        })
    end)
    cb('ok')
end)

RegisterNUICallback('getManagementData', function(data, cb)
    ESX.TriggerServerCallback('tablet:getManagementData', function(managementData)
        SendNUIMessage({
            action = 'receiveManagementData',
            data = managementData
        })
    end)
    cb('ok')
end)

RegisterNUICallback('getTransactionHistory', function(data, cb)
    ESX.TriggerServerCallback('tablet:getTransactionHistory', function(transactionData)
        SendNUIMessage({
            action = 'receiveTransactionHistory',
            data = transactionData
        })
    end)
    cb('ok')
end)

RegisterNUICallback('getEmployeeStats', function(data, cb)
    ESX.TriggerServerCallback('tablet:getEmployeeStats', function(employeeStats)
        SendNUIMessage({
            action = 'receiveEmployeeStats',
            stats = employeeStats
        })
    end)
    cb('ok')
end)

RegisterNUICallback('resetSales', function(data, cb)
    TriggerServerEvent('tablet:resetSales')
    cb('ok')
end)

RegisterNUICallback('resetCommissions', function(data, cb)
    print('[TABLET DEBUG] NUI Callback resetCommissions received')
    TriggerServerEvent('tablet:resetCommissions')
    cb('ok')
end)

RegisterNUICallback('resetVAT', function(data, cb)
    print('[TABLET DEBUG] NUI Callback resetVAT received')
    TriggerServerEvent('tablet:resetVAT')
    cb('ok')
end)

RegisterNUICallback('resetEmployeeCommission', function(data, cb)
    print('[TABLET DEBUG] NUI Callback resetEmployeeCommission received for:', data.identifier)
    TriggerServerEvent('tablet:resetEmployeeCommission', data.identifier)
    cb('ok')
end)

-- Notes de l'entreprise
RegisterNUICallback('getCompanyNotes', function(data, cb)
    ESX.TriggerServerCallback('tablet:getCompanyNotes', function(notes)
        SendNUIMessage({
            action = 'receiveCompanyNotes',
            notes = notes
        })
    end)
    cb('ok')
end)

RegisterNUICallback('addCompanyNote', function(data, cb)
    TriggerServerEvent('tablet:addCompanyNote', data.title, data.content)
    cb('ok')
end)

RegisterNUICallback('updateCompanyNote', function(data, cb)
    TriggerServerEvent('tablet:updateCompanyNote', data.noteId, data.title, data.content)
    cb('ok')
end)

RegisterNUICallback('deleteCompanyNote', function(data, cb)
    TriggerServerEvent('tablet:deleteCompanyNote', data.noteId)
    cb('ok')
end)

RegisterNUICallback('getAuditData', function(data, cb)
    ESX.TriggerServerCallback('tablet:getAuditData', function(auditData)
        SendNUIMessage({
            action = 'receiveAuditData',
            data = auditData
        })
    end)
    cb('ok')
end)

RegisterNUICallback('createInvoice', function(data, cb)
    TriggerServerEvent('tablet:createInvoice', data)
    cb('ok')
end)

RegisterNUICallback('addProduct', function(data, cb)
    TriggerServerEvent('tablet:addProduct', data)
    cb('ok')
end)

RegisterNUICallback('deleteProduct', function(data, cb)
    TriggerServerEvent('tablet:deleteProduct', data)
    cb('ok')
end)

RegisterNUICallback('updateCommission', function(data, cb)
    TriggerServerEvent('tablet:updateCommission', data)
    cb('ok')
end)

RegisterNUICallback('resetCommission', function(data, cb)
    TriggerServerEvent('tablet:resetCommission', data)
    cb('ok')
end)

RegisterNUICallback('addPartnership', function(data, cb)
    TriggerServerEvent('tablet:addPartnership', data)
    cb('ok')
end)

RegisterNUICallback('deletePartnership', function(data, cb)
    TriggerServerEvent('tablet:deletePartnership', data)
    cb('ok')
end)

RegisterNUICallback('cancelInvoice', function(data, cb)
    TriggerServerEvent('tablet:cancelInvoice', data.invoiceId)
    cb('ok')
end)

RegisterNUICallback('payInvoice', function(data, cb)
    TriggerServerEvent('tablet:payInvoice', data.invoiceId)
    cb('ok')
end)

RegisterNUICallback('closeInvoiceMenu', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- ============================================
-- GESTION RH - RECRUTEMENT / VIRER / PROMOUVOIR
-- ============================================

RegisterNUICallback('getNearbyPlayers', function(data, cb)
    local nearbyPlayers = GetNearbyPlayers()

    if #nearbyPlayers > 0 then
        SendNUIMessage({
            action = 'showNearbyPlayers',
            players = nearbyPlayers
        })
    else
        ShowNotification('❌ Aucun joueur à proximité', 'error')
    end

    cb('ok')
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    TriggerServerEvent('tablet:hireEmployee', data.targetId)
    cb('ok')
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    TriggerServerEvent('tablet:fireEmployee', data.identifier)
    cb('ok')
end)

RegisterNUICallback('promoteEmployee', function(data, cb)
    TriggerServerEvent('tablet:promoteEmployee', data.identifier)
    cb('ok')
end)

-- Events serveur -> client
RegisterNetEvent('tablet:updateProducts')
AddEventHandler('tablet:updateProducts', function(products)
    SendNUIMessage({
        action = 'updateProducts',
        products = products
    })
end)

RegisterNetEvent('tablet:updatePartnerships')
AddEventHandler('tablet:updatePartnerships', function(partnerships)
    SendNUIMessage({
        action = 'updatePartnerships',
        partnerships = partnerships
    })
end)

RegisterNetEvent('tablet:updateCommission')
AddEventHandler('tablet:updateCommission', function(commission)
    SendNUIMessage({
        action = 'updateCommission',
        commission = commission
    })
end)

RegisterNetEvent('tablet:invoiceCreated')
AddEventHandler('tablet:invoiceCreated', function()
    SendNUIMessage({
        action = 'invoiceCreated'
    })
end)

RegisterNetEvent('tablet:refreshInvoices')
AddEventHandler('tablet:refreshInvoices', function()
    -- Rafraîchir uniquement les factures sans fermer la tablette
    SendNUIMessage({
        action = 'refreshInvoices'
    })
end)

RegisterNetEvent('tablet:refreshStats')
AddEventHandler('tablet:refreshStats', function()
    -- Rafraîchir les statistiques dans la tablette
    SendNUIMessage({
        action = 'refreshStats'
    })
end)

RegisterNetEvent('tablet:refreshEmployeeStats')
AddEventHandler('tablet:refreshEmployeeStats', function()
    -- Rafraîchir les statistiques des employés (tableau + stats entreprise)
    SendNUIMessage({
        action = 'refreshEmployeeStats'
    })
end)

RegisterNetEvent('tablet:refreshNotes')
AddEventHandler('tablet:refreshNotes', function()
    -- Rafraîchir les notes de l'entreprise
    SendNUIMessage({
        action = 'refreshNotes'
    })
end)

-- VÉHICULES (DEALERSHIP)
RegisterNUICallback('getVehicles', function(data, cb)
    ESX.TriggerServerCallback('dealership:getVehicles', function(vehicles)
        cb(vehicles)
    end)
end)

RegisterNUICallback('orderVehicles', function(data, cb)
    TriggerServerEvent('dealership:orderVehicles', data.vehicleModel, data.quantity)
    cb('ok')
end)

-- Refresh véhicules (appelé depuis le serveur)
RegisterNetEvent('dealership:refreshVehicles')
AddEventHandler('dealership:refreshVehicles', function()
    SendNUIMessage({
        action = 'refreshVehicles'
    })
end)

-- Refresh historique transactions (appelé depuis le serveur)
RegisterNetEvent('tablet:refreshHistory')
AddEventHandler('tablet:refreshHistory', function()
    SendNUIMessage({
        action = 'refreshHistory'
    })
end)

-- Fermer avec ESC
RegisterNUICallback('escape', function(data, cb)
    CloseTablet()
    cb('ok')
end)

-- Empêcher les inputs du jeu quand la tablette est ouverte
CreateThread(function()
    while true do
        Wait(0)
        if isTabletOpen then
            DisableControlAction(0, 1, true) -- Mouse Look
            DisableControlAction(0, 2, true) -- Mouse Look
            DisableControlAction(0, 24, true) -- Attack
            DisableControlAction(0, 25, true) -- Aim
            DisableControlAction(0, 47, true) -- Weapon
            DisableControlAction(0, 58, true) -- Weapon
            DisableControlAction(0, 263, true) -- Melee
            DisableControlAction(0, 264, true) -- Melee
            DisableControlAction(0, 257, true) -- Melee
            DisableControlAction(0, 140, true) -- Melee
            DisableControlAction(0, 141, true) -- Melee
            DisableControlAction(0, 142, true) -- Melee
            DisableControlAction(0, 143, true) -- Melee
        end
    end
end)

print('^2[TabletManager]^0 Client démarré avec succès')
