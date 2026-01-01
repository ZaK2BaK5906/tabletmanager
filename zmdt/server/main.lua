ESX = exports['es_extended']:getSharedObject()

-- ============================================
-- UTILITIES
-- ============================================

function ShowNotification(source, message, type)
    TriggerClientEvent('esx:showNotification', source, message)
end

function SendWebhook(webhookType, data)
    if not Config.Webhooks.Enabled then return end

    local webhook = Config.Webhooks[webhookType]
    if not webhook or webhook == '' then return end

    -- TODO: Implement Discord webhook
    -- PerformHttpRequest(webhook, ...)
end

-- Générer un numéro unique pour un type de document
function GenerateNumber(type)
    local format = Config.NumberFormats[type]
    if not format then return nil end

    local year = os.date('%y')
    local month = os.date('%m')
    local day = os.date('%d')

    -- Get next sequential number
    local tableName = 'mdt_'..type
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM '..tableName) or 0
    local nextNum = count + 1

    -- Format based on type
    if format:match('YYMMDD') then
        return format:gsub('YY', year):gsub('MM', month):gsub('DD', day):gsub('XXX', string.format('%03d', nextNum))
    elseif format:match('YY%-') then
        return format:gsub('YY', year):gsub('XXXXX', string.format('%05d', nextNum))
    else
        return format:gsub('XXXXX', string.format('%05d', nextNum))
    end
end

-- ============================================
-- SYNCHRONISATION ESX
-- ============================================

-- Convertir date au format MySQL (YYYY-MM-DD)
local function ConvertDateToMySQL(dateStr)
    if not dateStr then return '2000-01-01' end

    -- Si déjà au bon format (YYYY-MM-DD)
    if string.match(dateStr, '^%d%d%d%d%-%d%d%-%d%d$') then
        return dateStr
    end

    -- Format DD/MM/YYYY ou MM/DD/YYYY
    local day, month, year = string.match(dateStr, '^(%d+)/(%d+)/(%d+)$')
    if day and month and year then
        -- Si année sur 2 chiffres, ajouter 2000 ou 1900
        if #year == 2 then
            year = tonumber(year) > 50 and ('19'..year) or ('20'..year)
        end

        -- Déterminer si c'est DD/MM/YYYY ou MM/DD/YYYY
        -- Si le premier nombre > 12, c'est forcément le jour
        if tonumber(day) > 12 then
            return string.format('%04d-%02d-%02d', tonumber(year), tonumber(month), tonumber(day))
        -- Si le deuxième nombre > 12, c'est forcément le mois
        elseif tonumber(month) > 12 then
            return string.format('%04d-%02d-%02d', tonumber(year), tonumber(day), tonumber(month))
        -- Sinon on assume DD/MM/YYYY (format européen)
        else
            return string.format('%04d-%02d-%02d', tonumber(year), tonumber(month), tonumber(day))
        end
    end

    -- Format par défaut si rien ne match
    return '2000-01-01'
end

-- Sync ALL players au démarrage de la ressource
CreateThread(function()
    Wait(2000) -- Attendre que ESX soit chargé

    if Config.SyncWithESX.citizens then
        local xPlayers = ESX.GetExtendedPlayers()
        local syncCount = 0

        for _, xPlayer in ipairs(xPlayers) do
            local identifier = xPlayer.identifier
            local firstname = xPlayer.get('firstName') or 'Unknown'
            local lastname = xPlayer.get('lastName') or 'Unknown'
            local dob = ConvertDateToMySQL(xPlayer.get('dateofbirth'))
            local sex = xPlayer.get('sex') or 'M'
            local height = xPlayer.get('height') or 175

            MySQL.insert([[
                INSERT INTO mdt_citizens (identifier, firstname, lastname, dateofbirth, sex, height)
                VALUES (?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    firstname = VALUES(firstname),
                    lastname = VALUES(lastname),
                    dateofbirth = VALUES(dateofbirth),
                    sex = VALUES(sex),
                    height = VALUES(height)
            ]], {identifier, firstname, lastname, dob, sex, height})

            syncCount = syncCount + 1
        end

        print('^2[ZMDT]^0 Synchronized '..syncCount..' players to mdt_citizens')
    end
end)

-- Sync user → mdt_citizens au login
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    if not Config.SyncWithESX.citizens then return end

    local identifier = xPlayer.identifier
    local firstname = xPlayer.get('firstName') or 'Unknown'
    local lastname = xPlayer.get('lastName') or 'Unknown'
    local dob = ConvertDateToMySQL(xPlayer.get('dateofbirth'))
    local sex = xPlayer.get('sex') or 'M'
    local height = xPlayer.get('height') or 175

    MySQL.insert([[
        INSERT INTO mdt_citizens (identifier, firstname, lastname, dateofbirth, sex, height)
        VALUES (?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            firstname = VALUES(firstname),
            lastname = VALUES(lastname),
            dateofbirth = VALUES(dateofbirth),
            sex = VALUES(sex),
            height = VALUES(height)
    ]], {identifier, firstname, lastname, dob, sex, height})
end)

-- ============================================
-- CALLBACKS PRINCIPAUX
-- ============================================

-- Get initial data when opening MDT
ESX.RegisterServerCallback('zmdt:getInitialData', function(source, cb, service)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        print('[ZMDT ERROR] Player not found: ' .. source)
        cb(nil)
        return
    end

    print('[ZMDT DEBUG] Loading initial data for ' .. xPlayer.getName() .. ' (service: ' .. service .. ')')

    local data = {
        user = {
            identifier = xPlayer.identifier,
            name = xPlayer.getName(),
            job = xPlayer.job.name,
            job_label = xPlayer.job.label,
            grade = xPlayer.job.grade,
            grade_label = xPlayer.job.grade_label
        },
        permissions = {}, -- TODO: Load permissions
        service = service,
        hasMDTAccess = true
    }

    -- Service-specific data
    if service == 'police' then
        print('[ZMDT DEBUG] Loading police initial data...')

        -- Utiliser les NOUVELLES tables zx_police_*
        local success, calls = pcall(function()
            return MySQL.query.await([[
                SELECT * FROM zx_police_calls
                WHERE status IN ('pending', 'dispatched', 'on_scene')
                ORDER BY priority DESC, created_at ASC
                LIMIT 20
            ]]) or {}
        end)

        if success then
            data.activeCalls = calls
            print('[ZMDT DEBUG] Loaded ' .. #calls .. ' active calls')
        else
            data.activeCalls = {}
            print('[ZMDT ERROR] Failed to load calls: ' .. tostring(calls))
        end

        local success2, bolos = pcall(function()
            return MySQL.query.await([[
                SELECT * FROM zx_police_bolo
                WHERE status = 'active'
                ORDER BY priority DESC, issued_date DESC
                LIMIT 20
            ]]) or {}
        end)

        if success2 then
            data.activeBOLO = bolos
            print('[ZMDT DEBUG] Loaded ' .. #bolos .. ' active BOLOs')
        else
            data.activeBOLO = {}
            print('[ZMDT ERROR] Failed to load BOLOs: ' .. tostring(bolos))
        end

    elseif service == 'doj' then
        print('[ZMDT DEBUG] Loading DOJ initial data...')
        data.activeCases = {}
        -- TODO: DOJ tables not yet created

    elseif service == 'ems' then
        print('[ZMDT DEBUG] Loading EMS initial data...')
        data.activeCalls = {}
        -- TODO: EMS tables not yet created
    end

    print('[ZMDT DEBUG] Sending initial data to client. User: ' .. data.user.name .. ' | Service: ' .. service)
    cb(data)
end)

-- ============================================
-- QUICK COMMANDS
-- ============================================

-- BOLO rapide via /bolo
RegisterNetEvent('zmdt:createQuickBOLO')
AddEventHandler('zmdt:createQuickBOLO', function(description)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    -- Check permission
    -- TODO: Implement permission check

    local boloId = MySQL.insert.await([[
        INSERT INTO mdt_bolo (bolo_type, subject, description, priority, issued_by)
        VALUES ('person', 'Quick BOLO', ?, 'medium', ?)
    ]], {description, xPlayer.identifier})

    if boloId then
        ShowNotification(_source, '✅ BOLO créé #'..boloId, 'success')

        -- Broadcast to all police
        local xPlayers = ESX.GetExtendedPlayers()
        for _, player in ipairs(xPlayers) do
            for _, job in ipairs(Config.PoliceJobs) do
                if player.job.name == job then
                    TriggerClientEvent('zmdt:police:newBOLO', player.source, {
                        id = boloId,
                        subject = 'Quick BOLO',
                        description = description,
                        priority = 'medium',
                        issued_by_name = xPlayer.getName()
                    })
                end
            end
        end
    end
end)

-- Wanted rapide via /wanted
RegisterNetEvent('zmdt:createQuickWanted')
AddEventHandler('zmdt:createQuickWanted', function(targetId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if not xPlayer or not targetPlayer then
        ShowNotification(_source, Config.Notifications['not_found'], 'error')
        return
    end

    local wantedId = MySQL.insert.await([[
        INSERT INTO mdt_wanted (citizen_identifier, citizen_name, reason, priority, issued_by)
        VALUES (?, ?, 'Wanted via quick command', 'medium', ?)
    ]], {targetPlayer.identifier, targetPlayer.getName(), xPlayer.identifier})

    if wantedId then
        ShowNotification(_source, '✅ Wanted créé pour '..targetPlayer.getName(), 'success')
        ShowNotification(targetId, '🚨 Vous êtes recherché par la police', 'error')
    end
end)

-- ============================================
-- ACTIVITY LOGGING
-- ============================================

function LogActivity(userIdentifier, actionType, tableName, recordId, details)
    local jobName = 'unknown'

    local xPlayer = ESX.GetPlayerFromIdentifier(userIdentifier)
    if xPlayer then
        jobName = xPlayer.job.name
    end

    MySQL.insert([[
        INSERT INTO mdt_activity_log (action_type, table_name, record_id, user_identifier, user_job, details)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {actionType, tableName, recordId, userIdentifier, jobName, json.encode(details or {})})
end

-- ============================================
-- ACCESS LOGS
-- ============================================

function LogAccess(source, recordType, recordId, action, granted, denialReason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    -- IP is optional (NULL) - no Steam required
    MySQL.insert([[
        INSERT INTO mdt_access_logs (user_identifier, user_job, record_type, record_id, action, access_granted, denial_reason, ip_address)
        VALUES (?, ?, ?, ?, ?, ?, ?, NULL)
    ]], {xPlayer.identifier, xPlayer.job.name, recordType, recordId, action, granted and 1 or 0, denialReason})
end

-- ============================================
-- BROADCAST FUNCTIONS
-- ============================================

function BroadcastToPolice(eventName, data)
    local xPlayers = ESX.GetExtendedPlayers()
    for _, player in ipairs(xPlayers) do
        for _, job in ipairs(Config.PoliceJobs) do
            if player.job.name == job then
                TriggerClientEvent(eventName, player.source, data)
            end
        end
    end
end

function BroadcastToDOJ(eventName, data)
    local xPlayers = ESX.GetExtendedPlayers()
    for _, player in ipairs(xPlayers) do
        for _, job in ipairs(Config.DOJJobs) do
            if player.job.name == job then
                TriggerClientEvent(eventName, player.source, data)
            end
        end
    end
end

function BroadcastToEMS(eventName, data)
    local xPlayers = ESX.GetExtendedPlayers()
    for _, player in ipairs(xPlayers) do
        for _, job in ipairs(Config.EMSJobs) do
            if player.job.name == job then
                TriggerClientEvent(eventName, player.source, data)
            end
        end
    end
end

-- ============================================
-- NEARBY PLAYER INFO
-- ============================================

ESX.RegisterServerCallback('zmdt:getNearbyPlayerInfo', function(source, cb, targetId)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if not targetPlayer then
        cb(nil)
        return
    end

    cb({
        name = targetPlayer.getName(),
        identifier = targetPlayer.identifier,
        job = targetPlayer.job.name,
        job_label = targetPlayer.job.label
    })
end)

-- ============================================
-- STATS & DASHBOARD
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getStats', function(source, cb)
    if not HasPermission(source, 'police.stats.view') then
        cb(nil)
        return
    end

    local stats = {}

    -- Today stats
    stats.arrests_today = MySQL.scalar.await([[
        SELECT COUNT(*) FROM mdt_arrests
        WHERE DATE(arrest_date) = CURDATE()
    ]]) or 0

    stats.reports_today = MySQL.scalar.await([[
        SELECT COUNT(*) FROM mdt_reports
        WHERE DATE(created_at) = CURDATE()
    ]]) or 0

    stats.citations_today = MySQL.scalar.await([[
        SELECT COUNT(*) FROM mdt_citations
        WHERE DATE(created_at) = CURDATE()
    ]]) or 0

    stats.active_calls = MySQL.scalar.await([[
        SELECT COUNT(*) FROM mdt_calls
        WHERE status IN ('pending', 'dispatched', 'on_scene')
    ]]) or 0

    stats.active_bolo = MySQL.scalar.await([[
        SELECT COUNT(*) FROM mdt_bolo
        WHERE status = 'active'
    ]]) or 0

    stats.active_warrants = MySQL.scalar.await([[
        SELECT COUNT(*) FROM mdt_warrants
        WHERE status = 'active'
    ]]) or 0

    -- Week stats
    stats.arrests_week = MySQL.scalar.await([[
        SELECT COUNT(*) FROM mdt_arrests
        WHERE arrest_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ]]) or 0

    stats.reports_week = MySQL.scalar.await([[
        SELECT COUNT(*) FROM mdt_reports
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
    ]]) or 0

    cb(stats)
end)

-- ============================================
-- PANIC BUTTON
-- ============================================

ESX.RegisterServerCallback('zmdt:police:sendPanic', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    -- Check si c'est un policier
    local isPolice = false
    for _, job in ipairs(Config.PoliceJobs) do
        if xPlayer.job.name == job then
            isPolice = true
            break
        end
    end

    if not isPolice then
        cb(false)
        return
    end

    -- Broadcast panic à tous les policiers
    BroadcastToPolice('zmdt:police:panicReceived', {
        officer = xPlayer.getName(),
        location = data.location,
        coords = data.coords
    })

    SendWebhook('PoliceReports', {
        title = '🚨 PANIC BUTTON',
        officer = xPlayer.getName(),
        location = data.location,
        coords = data.coords
    })

    cb(true)
end)

-- Recevoir panic côté client
RegisterNetEvent('zmdt:police:panicReceived')
AddEventHandler('zmdt:police:panicReceived', function(data)
    -- Handled in client
end)

print('^2[ZMDT]^0 Server loaded successfully')
