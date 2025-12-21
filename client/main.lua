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

-- Ouvrir la tablette
function OpenTablet()
    if isTabletOpen then return end

    local PlayerData = ESX.GetPlayerData()

    -- Vérification du job
    if not PlayerData.job then
        ESX.ShowNotification(Config.Translations['no_job'])
        return
    end

    if PlayerData.job.name == 'unemployed' then
        ESX.ShowNotification(Config.Translations['no_job'])
        return
    end

    isTabletOpen = true
    local isBoss = IsBoss()

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
            commission = playerData.commission or Config.DefaultCommission,
            products = playerData.products or {},
            partnerships = playerData.partnerships or {}
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

RegisterNUICallback('addPartnership', function(data, cb)
    TriggerServerEvent('tablet:addPartnership', data)
    cb('ok')
end)

RegisterNUICallback('deletePartnership', function(data, cb)
    TriggerServerEvent('tablet:deletePartnership', data)
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
