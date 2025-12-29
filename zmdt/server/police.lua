-- ============================================
-- SERVER POLICE
-- ============================================

-- Get calls (CAD)
ESX.RegisterServerCallback('zmdt:police:getCalls', function(source, cb)
    if not HasPermission(source, 'police.cad.view') then
        cb({})
        return
    end

    local calls = MySQL.query.await('SELECT * FROM mdt_calls WHERE status != ? ORDER BY created_at DESC LIMIT 50', {'closed'})
    cb(calls or {})
end)

-- Create call
RegisterNetEvent('zmdt:police:createCall')
AddEventHandler('zmdt:police:createCall', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.cad.create') then return end

    local callNumber = GenerateNumber('calls')

    local callId = MySQL.insert.await([[
        INSERT INTO mdt_calls (call_number, priority, call_type, location, description)
        VALUES (?, ?, ?, ?, ?)
    ]], {callNumber, data.priority, data.call_type, data.location, data.description})

    if callId then
        ShowNotification(_source, '✅ Appel créé: '..callNumber, 'success')

        -- Broadcast to all police
        local call = {
            id = callId,
            call_number = callNumber,
            priority = data.priority,
            call_type = data.call_type,
            location = data.location,
            description = data.description,
            created_at = os.date('%Y-%m-%d %H:%M:%S')
        }

        local xPlayers = ESX.GetExtendedPlayers()
        for _, player in ipairs(xPlayers) do
            for _, job in ipairs(Config.PoliceJobs) do
                if player.job.name == job then
                    TriggerClientEvent('zmdt:police:newCall', player.source, call)
                end
            end
        end

        -- Webhook
        SendWebhook('PoliceReports', {
            call_number = callNumber,
            priority = data.priority,
            location = data.location,
            created_by = xPlayer.getName()
        })
    end
end)

-- Search citizen
ESX.RegisterServerCallback('zmdt:police:searchCitizen', function(source, cb, query)
    if not HasPermission(source, 'police.search.citizen') then
        cb({})
        return
    end

    -- Chercher directement dans la table users (ESX)
    local results = MySQL.query.await([[
        SELECT
            identifier,
            firstname,
            lastname,
            dateofbirth,
            sex,
            height,
            phone_number,
            job,
            job_grade
        FROM users
        WHERE LOWER(firstname) LIKE ?
           OR LOWER(lastname) LIKE ?
           OR identifier LIKE ?
           OR phone_number LIKE ?
        LIMIT 20
    ]], {'%'..query:lower()..'%', '%'..query:lower()..'%', '%'..query..'%', '%'..query..'%'})

    cb(results or {})
end)

-- Search vehicle
ESX.RegisterServerCallback('zmdt:police:searchVehicle', function(source, cb, query)
    if not HasPermission(source, 'police.search.vehicle') then
        cb({})
        return
    end

    -- Chercher directement dans owned_vehicles (ESX)
    local results = MySQL.query.await([[
        SELECT
            v.plate,
            v.vehicle,
            v.stored,
            v.parking,
            u.firstname,
            u.lastname,
            u.identifier
        FROM owned_vehicles v
        LEFT JOIN users u ON u.identifier = v.owner
        WHERE LOWER(v.plate) LIKE ?
           OR LOWER(v.vehicle) LIKE ?
           OR LOWER(u.firstname) LIKE ?
           OR LOWER(u.lastname) LIKE ?
        LIMIT 20
    ]], {'%'..query:lower()..'%', '%'..query:lower()..'%', '%'..query:lower()..'%', '%'..query:lower()..'%'})

    cb(results or {})
end)

-- Search weapon
ESX.RegisterServerCallback('zmdt:police:searchWeapon', function(source, cb, query)
    if not HasPermission(source, 'police.search.weapon') then
        cb({})
        return
    end

    local results = MySQL.query.await([[
        SELECT * FROM mdt_weapons
        WHERE serial_number LIKE ? OR LOWER(weapon_type) LIKE ?
        LIMIT 20
    ]], {'%'..query..'%', '%'..query:lower()..'%'})

    cb(results or {})
end)

-- Create report
RegisterNetEvent('zmdt:police:createReport')
AddEventHandler('zmdt:police:createReport', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.reports.create') then return end

    local reportNumber = GenerateNumber('reports')

    local reportId = MySQL.insert.await([[
        INSERT INTO mdt_reports (report_number, report_type, title, location, incident_date, primary_officer, narrative)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {reportNumber, data.report_type, data.title, data.location, data.incident_date, xPlayer.identifier, data.narrative})

    if reportId then
        ShowNotification(_source, '✅ Rapport créé: '..reportNumber, 'success')
        LogActivity(xPlayer.identifier, 'create', 'reports', reportId, {report_number = reportNumber})
    end
end)

-- Get reports
ESX.RegisterServerCallback('zmdt:police:getReports', function(source, cb)
    if not HasPermission(source, 'police.reports.view') then
        cb({})
        return
    end

    local reports = MySQL.query.await('SELECT * FROM mdt_reports ORDER BY created_at DESC LIMIT 50')
    cb(reports or {})
end)

-- Create BOLO
RegisterNetEvent('zmdt:police:createBOLO')
AddEventHandler('zmdt:police:createBOLO', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.bolo.create') then return end

    local boloId = MySQL.insert.await([[
        INSERT INTO mdt_bolo (bolo_type, subject, description, priority, danger_level, issued_by)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], {data.bolo_type, data.subject, data.description, data.priority, data.danger_level, xPlayer.identifier})

    if boloId then
        ShowNotification(_source, '✅ BOLO créé #'..boloId, 'success')

        -- Broadcast
        local bolo = {
            id = boloId,
            bolo_type = data.bolo_type,
            subject = data.subject,
            description = data.description,
            priority = data.priority,
            danger_level = data.danger_level,
            issued_by_name = xPlayer.getName(),
            created_at = os.date('%Y-%m-%d %H:%M:%S')
        }

        local xPlayers = ESX.GetExtendedPlayers()
        for _, player in ipairs(xPlayers) do
            for _, job in ipairs(Config.PoliceJobs) do
                if player.job.name == job then
                    TriggerClientEvent('zmdt:police:newBOLO', player.source, bolo)
                end
            end
        end
    end
end)

-- Get BOLO
ESX.RegisterServerCallback('zmdt:police:getBOLO', function(source, cb)
    if not HasPermission(source, 'police.bolo.view') then
        cb({})
        return
    end

    local bolos = MySQL.query.await('SELECT * FROM mdt_bolo WHERE status = ? ORDER BY issued_at DESC', {'active'})
    cb(bolos or {})
end)

print('^2[ZMDT]^0 Police server loaded')
