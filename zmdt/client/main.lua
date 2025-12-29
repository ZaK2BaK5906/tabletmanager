ESX = exports['es_extended']:getSharedObject()
local isMDTOpen = false
local currentService = nil  -- 'police', 'doj', ou 'ems'

-- ============================================
-- VÉRIFICATIONS D'ACCÈS
-- ============================================

function HasMDTAccess()
    local PlayerData = ESX.GetPlayerData()
    if not PlayerData.job then return false, nil end

    -- Check Police
    for _, job in ipairs(Config.PoliceJobs) do
        if PlayerData.job.name == job then
            return true, 'police'
        end
    end

    -- Check DOJ
    for _, job in ipairs(Config.DOJJobs) do
        if PlayerData.job.name == job then
            return true, 'doj'
        end
    end

    -- Check EMS
    for _, job in ipairs(Config.EMSJobs) do
        if PlayerData.job.name == job then
            return true, 'ems'
        end
    end

    return false, nil
end

function IsSupervisor()
    local PlayerData = ESX.GetPlayerData()
    if not PlayerData.job then return false end

    local minGrade = Config.SupervisorGrades[PlayerData.job.name]
    if minGrade and PlayerData.job.grade >= minGrade then
        return true
    end

    return false
end

-- ============================================
-- OUVRIR / FERMER MDT
-- ============================================

function OpenMDT()
    if isMDTOpen then return end

    local hasAccess, service = HasMDTAccess()
    if not hasAccess then
        ESX.ShowNotification(Config.Notifications['no_permission'])
        return
    end

    isMDTOpen = true
    currentService = service

    -- Récupérer les données initiales
    ESX.TriggerServerCallback('zmdt:getInitialData', function(data)
        if not data then
            CloseMDT()
            return
        end

        SendNUIMessage({
            action = 'open',
            service = service,
            data = data
        })

        SetNuiFocus(true, true)
    end, service)
end

function CloseMDT()
    if not isMDTOpen then return end

    isMDTOpen = false
    currentService = nil

    SendNUIMessage({
        action = 'close'
    })

    SetNuiFocus(false, false)
end

-- ============================================
-- EVENTS
-- ============================================

-- Event pour ouvrir depuis la tablette
RegisterNetEvent('zmdt:open')
AddEventHandler('zmdt:open', function()
    OpenMDT()
end)

-- Event pour fermer
RegisterNetEvent('zmdt:close')
AddEventHandler('zmdt:close', function()
    CloseMDT()
end)

-- Job change
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job

    -- Fermer le MDT si le joueur n'a plus accès
    if isMDTOpen then
        local hasAccess = HasMDTAccess()
        if not hasAccess then
            CloseMDT()
            ESX.ShowNotification('❌ Vous n\'avez plus accès au MDT')
        end
    end
end)

-- ============================================
-- NUI CALLBACKS
-- ============================================

RegisterNUICallback('close', function(data, cb)
    CloseMDT()
    cb('ok')
end)

RegisterNUICallback('escape', function(data, cb)
    CloseMDT()
    cb('ok')
end)

-- ============================================
-- COMMANDES
-- ============================================

-- Commande /mdt
RegisterCommand(Config.Commands.mdt, function()
    OpenMDT()
end, false)

RegisterKeyMapping(Config.Commands.mdt, 'Ouvrir le MDT', 'keyboard', '')

-- Commande /bolo rapide
RegisterCommand(Config.Commands.bolo, function(source, args)
    local hasAccess, service = HasMDTAccess()
    if not hasAccess or service ~= 'police' then
        ESX.ShowNotification(Config.Notifications['no_permission'])
        return
    end

    if #args < 1 then
        ESX.ShowNotification('Usage: /'..Config.Commands.bolo..' [description]')
        return
    end

    local description = table.concat(args, ' ')
    TriggerServerEvent('zmdt:createQuickBOLO', description)
end, false)

-- Commande /wanted rapide
RegisterCommand(Config.Commands.wanted, function(source, args)
    local hasAccess, service = HasMDTAccess()
    if not hasAccess or service ~= 'police' then
        ESX.ShowNotification(Config.Notifications['no_permission'])
        return
    end

    if #args < 1 then
        ESX.ShowNotification('Usage: /'..Config.Commands.wanted..' [player id]')
        return
    end

    local targetId = tonumber(args[1])
    if not targetId then
        ESX.ShowNotification(Config.Notifications['invalid_data'])
        return
    end

    TriggerServerEvent('zmdt:createQuickWanted', targetId)
end, false)

-- Commande /911 pour dispatcher
RegisterCommand(Config.Commands.dispatch, function()
    local hasAccess, service = HasMDTAccess()
    if not hasAccess then
        ESX.ShowNotification(Config.Notifications['no_permission'])
        return
    end

    if service == 'police' then
        OpenMDT()
        -- TODO: Auto-ouvrir l'onglet CAD
        SendNUIMessage({
            action = 'openTab',
            tab = 'cad'
        })
    elseif service == 'ems' then
        OpenMDT()
        SendNUIMessage({
            action = 'openTab',
            tab = 'dispatch'
        })
    end
end, false)

-- ============================================
-- DÉSACTIVER CONTRÔLES PENDANT MDT OUVERT
-- ============================================

CreateThread(function()
    while true do
        Wait(0)
        if isMDTOpen then
            DisableControlAction(0, 1, true)   -- Mouse Look
            DisableControlAction(0, 2, true)   -- Mouse Look
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            DisableControlAction(0, 47, true)  -- Weapon
            DisableControlAction(0, 58, true)  -- Weapon
            DisableControlAction(0, 263, true) -- Melee
            DisableControlAction(0, 264, true) -- Melee
            DisableControlAction(0, 257, true) -- Melee
            DisableControlAction(0, 140, true) -- Melee
            DisableControlAction(0, 141, true) -- Melee
            DisableControlAction(0, 142, true) -- Melee
            DisableControlAction(0, 143, true) -- Melee
        else
            Wait(500)
        end
    end
end)

print('^2[ZMDT]^0 Client loaded successfully')
