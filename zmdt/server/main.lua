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
            local dob = xPlayer.get('dateofbirth') or '2000-01-01'
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
    local dob = xPlayer.get('dateofbirth') or '2000-01-01'
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
    if not xPlayer then cb(nil) return end

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
        service = service
    }

    -- Service-specific data
    if service == 'police' then
        data.activeCalls = MySQL.query.await([[
            SELECT * FROM mdt_calls
            WHERE status IN ('pending', 'dispatched', 'on_scene')
            ORDER BY priority DESC, created_at ASC
            LIMIT 20
        ]]) or {}

        data.activeBOLO = MySQL.query.await([[
            SELECT * FROM mdt_bolo
            WHERE status = 'active'
            ORDER BY priority DESC, issued_at DESC
            LIMIT 20
        ]]) or {}

    elseif service == 'doj' then
        data.activeCases = MySQL.query.await([[
            SELECT * FROM mdt_cases
            WHERE status NOT IN ('closed', 'dismissed')
            ORDER BY created_at DESC
            LIMIT 20
        ]]) or {}

    elseif service == 'ems' then
        data.activeCalls = MySQL.query.await([[
            SELECT * FROM mdt_ems_calls
            WHERE status IN ('pending', 'dispatched', 'on_scene', 'transport')
            ORDER BY priority DESC, created_at ASC
            LIMIT 20
        ]]) or {}
    end

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

    local ip = GetPlayerEndpoint(source)

    MySQL.insert([[
        INSERT INTO mdt_access_logs (user_identifier, user_job, record_type, record_id, action, access_granted, denial_reason, ip_address)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]], {xPlayer.identifier, xPlayer.job.name, recordType, recordId, action, granted and 1 or 0, denialReason, ip})
end

print('^2[ZMDT]^0 Server loaded successfully')
