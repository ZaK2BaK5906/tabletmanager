-- ============================================
-- SERVER POLICE - SYSTÈME COMPLET
-- ============================================

-- ============================================
-- CAD / APPELS 911
-- ============================================

-- Get active calls
ESX.RegisterServerCallback('zmdt:police:getCalls', function(source, cb)
    if not HasPermission(source, 'police.cad.view') then
        cb({})
        return
    end

    local calls = MySQL.query.await([[
        SELECT * FROM mdt_calls
        WHERE status != 'closed'
        ORDER BY
            FIELD(priority, 'critical', 'high', 'medium', 'low'),
            created_at DESC
        LIMIT 100
    ]])

    cb(calls or {})
end)

-- Get all calls (history)
ESX.RegisterServerCallback('zmdt:police:getAllCalls', function(source, cb, filters)
    if not HasPermission(source, 'police.cad.view') then
        cb({})
        return
    end

    local query = 'SELECT * FROM mdt_calls WHERE 1=1'
    local params = {}

    if filters and filters.status then
        query = query .. ' AND status = ?'
        table.insert(params, filters.status)
    end

    if filters and filters.date then
        query = query .. ' AND DATE(created_at) = ?'
        table.insert(params, filters.date)
    end

    query = query .. ' ORDER BY created_at DESC LIMIT 200'

    local calls = MySQL.query.await(query, params)
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
        INSERT INTO mdt_calls (
            call_number, priority, call_type, location,
            caller_info, description, status
        ) VALUES (?, ?, ?, ?, ?, ?, 'pending')
    ]], {
        callNumber,
        data.priority or 'medium',
        data.call_type,
        data.location,
        data.caller_info,
        data.description
    })

    if callId then
        ShowNotification(_source, '✅ Appel créé: '..callNumber, 'success')

        -- Broadcast to all police
        local call = {
            id = callId,
            call_number = callNumber,
            priority = data.priority or 'medium',
            call_type = data.call_type,
            location = data.location,
            caller_info = data.caller_info,
            description = data.description,
            status = 'pending',
            created_at = os.date('%Y-%m-%d %H:%M:%S')
        }

        BroadcastToPolice('zmdt:police:newCall', call)
        LogActivity(xPlayer.identifier, 'create', 'calls', callId, {call_number = callNumber})

        -- Webhook Discord
        SendWebhook('PoliceReports', {
            title = '🚨 Nouvel Appel 911',
            call_number = callNumber,
            priority = data.priority,
            location = data.location,
            created_by = xPlayer.getName()
        })
    end
end)

-- Update call status
RegisterNetEvent('zmdt:police:updateCall')
AddEventHandler('zmdt:police:updateCall', function(callId, status, units)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.cad.create') then return end

    local updates = {}
    local params = {}

    if status then
        table.insert(updates, 'status = ?')
        table.insert(params, status)

        if status == 'dispatched' then
            table.insert(updates, 'dispatched_at = NOW()')
        elseif status == 'closed' then
            table.insert(updates, 'closed_at = NOW()')
            table.insert(updates, 'closed_by = ?')
            table.insert(params, xPlayer.identifier)
        end
    end

    if units then
        table.insert(updates, 'units_assigned = ?')
        table.insert(params, json.encode(units))
    end

    if #updates > 0 then
        table.insert(params, callId)
        local query = 'UPDATE mdt_calls SET ' .. table.concat(updates, ', ') .. ' WHERE id = ?'
        MySQL.update.await(query, params)

        ShowNotification(_source, '✅ Appel mis à jour', 'success')
        BroadcastToPolice('zmdt:police:callUpdated', {id = callId, status = status, units = units})
    end
end)

-- Close call
RegisterNetEvent('zmdt:police:closeCall')
AddEventHandler('zmdt:police:closeCall', function(callId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.cad.create') then return end

    MySQL.update.await([[
        UPDATE mdt_calls
        SET status = 'closed', closed_at = NOW(), closed_by = ?
        WHERE id = ?
    ]], {xPlayer.identifier, callId})

    ShowNotification(_source, '✅ Appel fermé', 'success')
    BroadcastToPolice('zmdt:police:callClosed', callId)
end)

-- ============================================
-- RECHERCHE CITOYENS
-- ============================================

ESX.RegisterServerCallback('zmdt:police:searchCitizen', function(source, cb, query)
    if not HasPermission(source, 'police.search.citizen') then
        cb({})
        return
    end

    if not query or query == '' then
        cb({})
        return
    end

    -- Recherche dans la table users (ESX)
    local citizens = MySQL.query.await([[
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
    ]], {
        '%'..query:lower()..'%',
        '%'..query:lower()..'%',
        '%'..query..'%',
        '%'..query..'%'
    })

    -- Enrichir avec données MDT
    if citizens then
        for i, citizen in ipairs(citizens) do
            -- Casier criminel (nombre de charges)
            local criminal = MySQL.query.await([[
                SELECT
                    COUNT(*) as total_charges,
                    SUM(CASE WHEN charge_class = 'felony' THEN 1 ELSE 0 END) as felonies,
                    SUM(CASE WHEN charge_class = 'misdemeanor' THEN 1 ELSE 0 END) as misdemeanors
                FROM mdt_criminal_records
                WHERE citizen_identifier = ? AND status = 'active'
            ]], {citizen.identifier})

            citizen.criminal_charges = criminal[1].total_charges or 0
            citizen.felonies = criminal[1].felonies or 0
            citizen.misdemeanors = criminal[1].misdemeanors or 0

            -- Citations
            local citations = MySQL.query.await([[
                SELECT
                    COUNT(*) as total,
                    SUM(fine_amount) as total_fines
                FROM mdt_citations
                WHERE citizen_identifier = ? AND payment_status = 'unpaid'
            ]], {citizen.identifier})

            citizen.pending_citations = citations[1].total or 0
            citizen.total_unpaid_fines = citations[1].total_fines or 0

            -- Notes flaggées
            local notes = MySQL.scalar.await([[
                SELECT COUNT(*)
                FROM mdt_citizen_notes
                WHERE citizen_identifier = ? AND is_flagged = 1
            ]], {citizen.identifier})

            citizen.flagged_notes = notes or 0

            -- Véhicules
            local vehicles = MySQL.scalar.await([[
                SELECT COUNT(*)
                FROM owned_vehicles
                WHERE owner = ?
            ]], {citizen.identifier})

            citizen.owned_vehicles = vehicles or 0

            -- Wanted/BOLO actif
            local wanted = MySQL.scalar.await([[
                SELECT COUNT(*)
                FROM mdt_wanted
                WHERE citizen_identifier = ? AND status = 'active'
            ]], {citizen.identifier})

            citizen.is_wanted = (wanted or 0) > 0

            -- Warrants actifs
            local warrants = MySQL.scalar.await([[
                SELECT COUNT(*)
                FROM mdt_warrants
                WHERE citizen_identifier = ? AND status = 'active'
            ]], {citizen.identifier})

            citizen.active_warrants = warrants or 0

            -- Licenses
            local licenses = MySQL.query.await([[
                SELECT license_type, status
                FROM mdt_licenses
                WHERE citizen_identifier = ?
            ]], {citizen.identifier})

            citizen.licenses = licenses or {}
        end
    end

    cb(citizens or {})
end)

-- Get citizen full profile
ESX.RegisterServerCallback('zmdt:police:getCitizenProfile', function(source, cb, identifier)
    if not HasPermission(source, 'police.search.citizen') then
        cb(nil)
        return
    end

    -- Info de base
    local citizen = MySQL.query.await([[
        SELECT * FROM users WHERE identifier = ? LIMIT 1
    ]], {identifier})

    if not citizen or #citizen == 0 then
        cb(nil)
        return
    end

    local profile = citizen[1]

    -- Casier criminel
    profile.criminal_history = MySQL.query.await([[
        SELECT * FROM mdt_criminal_records
        WHERE citizen_identifier = ?
        ORDER BY arrest_date DESC
    ]], {identifier}) or {}

    -- Citations
    profile.citations = MySQL.query.await([[
        SELECT * FROM mdt_citations
        WHERE citizen_identifier = ?
        ORDER BY created_at DESC
    ]], {identifier}) or {}

    -- Notes
    profile.notes = MySQL.query.await([[
        SELECT n.*, u.firstname, u.lastname
        FROM mdt_citizen_notes n
        LEFT JOIN users u ON u.identifier = n.author_identifier
        WHERE n.citizen_identifier = ?
        ORDER BY n.created_at DESC
    ]], {identifier}) or {}

    -- Véhicules
    profile.vehicles = MySQL.query.await([[
        SELECT * FROM owned_vehicles
        WHERE owner = ?
    ]], {identifier}) or {}

    -- Licenses
    profile.licenses = MySQL.query.await([[
        SELECT * FROM mdt_licenses
        WHERE citizen_identifier = ?
    ]], {identifier}) or {}

    -- Wanted
    profile.wanted = MySQL.query.await([[
        SELECT * FROM mdt_wanted
        WHERE citizen_identifier = ? AND status = 'active'
    ]], {identifier}) or {}

    -- Warrants
    profile.warrants = MySQL.query.await([[
        SELECT * FROM mdt_warrants
        WHERE citizen_identifier = ? AND status = 'active'
    ]], {identifier}) or {}

    -- Arrestations
    profile.arrests = MySQL.query.await([[
        SELECT * FROM mdt_arrests
        WHERE citizen_identifier = ?
        ORDER BY arrest_date DESC
        LIMIT 20
    ]], {identifier}) or {}

    cb(profile)
end)

-- ============================================
-- NOTES CITOYENS
-- ============================================

RegisterNetEvent('zmdt:police:addCitizenNote')
AddEventHandler('zmdt:police:addCitizenNote', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.notes.create') then return end

    local noteId = MySQL.insert.await([[
        INSERT INTO mdt_citizen_notes (
            citizen_identifier, note_text, note_type,
            is_flagged, author_identifier
        ) VALUES (?, ?, ?, ?, ?)
    ]], {
        data.identifier,
        data.note_text,
        data.note_type or 'info',
        data.is_flagged or 0,
        xPlayer.identifier
    })

    if noteId then
        ShowNotification(_source, '✅ Note ajoutée', 'success')
        LogActivity(xPlayer.identifier, 'create', 'citizen_notes', noteId, {
            citizen = data.identifier
        })
    end
end)

-- ============================================
-- RECHERCHE VÉHICULES
-- ============================================

ESX.RegisterServerCallback('zmdt:police:searchVehicle', function(source, cb, query)
    if not HasPermission(source, 'police.search.vehicle') then
        cb({})
        return
    end

    local results = MySQL.query.await([[
        SELECT
            v.plate,
            v.vehicle,
            v.stored,
            v.parking,
            v.pound,
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
    ]], {
        '%'..query:lower()..'%',
        '%'..query:lower()..'%',
        '%'..query:lower()..'%',
        '%'..query:lower()..'%'
    })

    -- Enrichir avec données MDT
    if results then
        for i, vehicle in ipairs(results) do
            -- Check si volé
            local stolen = MySQL.query.await([[
                SELECT * FROM mdt_vehicle_flags
                WHERE plate = ? AND flag_type = 'stolen' AND is_active = 1
                LIMIT 1
            ]], {vehicle.plate})

            vehicle.is_stolen = stolen and #stolen > 0

            -- Check BOLO
            local bolo = MySQL.query.await([[
                SELECT * FROM mdt_bolo
                WHERE bolo_type = 'vehicle'
                AND LOWER(subject) LIKE ?
                AND status = 'active'
                LIMIT 1
            ]], {'%'..vehicle.plate:lower()..'%'})

            vehicle.has_bolo = bolo and #bolo > 0

            -- Citations impayées liées au véhicule
            local citations = MySQL.scalar.await([[
                SELECT COUNT(*) FROM mdt_citations
                WHERE vehicle_plate = ? AND payment_status = 'unpaid'
            ]], {vehicle.plate})

            vehicle.unpaid_citations = citations or 0
        end
    end

    cb(results or {})
end)

-- ============================================
-- RECHERCHE ARMES
-- ============================================

ESX.RegisterServerCallback('zmdt:police:searchWeapon', function(source, cb, query)
    if not HasPermission(source, 'police.search.weapon') then
        cb({})
        return
    end

    local results = MySQL.query.await([[
        SELECT w.*, u.firstname, u.lastname
        FROM mdt_weapons w
        LEFT JOIN users u ON u.identifier = w.owner_identifier
        WHERE serial_number LIKE ?
           OR LOWER(weapon_type) LIKE ?
           OR LOWER(make) LIKE ?
           OR LOWER(model) LIKE ?
        LIMIT 20
    ]], {
        '%'..query..'%',
        '%'..query:lower()..'%',
        '%'..query:lower()..'%',
        '%'..query:lower()..'%'
    })

    cb(results or {})
end)

-- ============================================
-- RAPPORTS
-- ============================================

-- Get reports
ESX.RegisterServerCallback('zmdt:police:getReports', function(source, cb, filters)
    if not HasPermission(source, 'police.reports.view') then
        cb({})
        return
    end

    local query = [[
        SELECT r.*, u.firstname, u.lastname
        FROM mdt_reports r
        LEFT JOIN users u ON u.identifier = r.primary_officer
        WHERE 1=1
    ]]
    local params = {}

    if filters and filters.report_type then
        query = query .. ' AND r.report_type = ?'
        table.insert(params, filters.report_type)
    end

    if filters and filters.status then
        query = query .. ' AND r.status = ?'
        table.insert(params, filters.status)
    end

    query = query .. ' ORDER BY r.created_at DESC LIMIT 100'

    local reports = MySQL.query.await(query, params)
    cb(reports or {})
end)

-- Get single report
ESX.RegisterServerCallback('zmdt:police:getReport', function(source, cb, reportId)
    if not HasPermission(source, 'police.reports.view') then
        cb(nil)
        return
    end

    local report = MySQL.query.await([[
        SELECT r.*, u.firstname, u.lastname
        FROM mdt_reports r
        LEFT JOIN users u ON u.identifier = r.primary_officer
        WHERE r.id = ?
        LIMIT 1
    ]], {reportId})

    cb(report and report[1] or nil)
end)

-- Create report
RegisterNetEvent('zmdt:police:createReport')
AddEventHandler('zmdt:police:createReport', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.reports.create') then return end

    local reportNumber = GenerateNumber('reports')

    local reportId = MySQL.insert.await([[
        INSERT INTO mdt_reports (
            report_number, report_type, title, location,
            incident_date, primary_officer, assisting_officers,
            involved_citizens, involved_vehicles, narrative, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        reportNumber,
        data.report_type,
        data.title,
        data.location,
        data.incident_date or os.date('%Y-%m-%d %H:%M:%S'),
        xPlayer.identifier,
        data.assisting_officers and json.encode(data.assisting_officers) or nil,
        data.involved_citizens and json.encode(data.involved_citizens) or nil,
        data.involved_vehicles and json.encode(data.involved_vehicles) or nil,
        data.narrative,
        data.status or 'draft'
    })

    if reportId then
        ShowNotification(_source, '✅ Rapport créé: '..reportNumber, 'success')
        LogActivity(xPlayer.identifier, 'create', 'reports', reportId, {report_number = reportNumber})

        SendWebhook('PoliceReports', {
            title = '📝 Nouveau Rapport',
            report_number = reportNumber,
            report_type = data.report_type,
            officer = xPlayer.getName()
        })

        TriggerClientEvent('zmdt:police:reportCreated', _source, {
            id = reportId,
            report_number = reportNumber
        })
    end
end)

-- Update report
RegisterNetEvent('zmdt:police:updateReport')
AddEventHandler('zmdt:police:updateReport', function(reportId, data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.reports.edit') then return end

    -- Check ownership ou supervisor
    local report = MySQL.query.await('SELECT primary_officer FROM mdt_reports WHERE id = ?', {reportId})
    if not report or #report == 0 then return end

    local canEdit = report[1].primary_officer == xPlayer.identifier or HasPermission(_source, 'police.reports.edit_all')
    if not canEdit then
        ShowNotification(_source, '❌ Vous ne pouvez modifier que vos propres rapports', 'error')
        return
    end

    MySQL.update.await([[
        UPDATE mdt_reports
        SET title = ?, narrative = ?, status = ?, updated_at = NOW()
        WHERE id = ?
    ]], {data.title, data.narrative, data.status, reportId})

    ShowNotification(_source, '✅ Rapport mis à jour', 'success')
end)

-- ============================================
-- ARRESTATIONS
-- ============================================

-- Get arrests
ESX.RegisterServerCallback('zmdt:police:getArrests', function(source, cb, filters)
    if not HasPermission(source, 'police.arrests.view') then
        cb({})
        return
    end

    local query = 'SELECT * FROM mdt_arrests WHERE 1=1'
    local params = {}

    if filters and filters.date then
        query = query .. ' AND DATE(arrest_date) = ?'
        table.insert(params, filters.date)
    end

    query = query .. ' ORDER BY arrest_date DESC LIMIT 100'

    local arrests = MySQL.query.await(query, params)
    cb(arrests or {})
end)

-- Create arrest
RegisterNetEvent('zmdt:police:createArrest')
AddEventHandler('zmdt:police:createArrest', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.arrests.create') then return end

    local arrestNumber = GenerateNumber('arrests')

    local arrestId = MySQL.insert.await([[
        INSERT INTO mdt_arrests (
            arrest_number, citizen_identifier, citizen_name,
            charges, location, arresting_officer,
            assisting_officers, miranda_read, witnesses,
            evidence_seized, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        arrestNumber,
        data.identifier,
        data.citizen_name,
        json.encode(data.charges),
        data.location,
        xPlayer.identifier,
        data.assisting_officers and json.encode(data.assisting_officers) or nil,
        data.miranda_read or 0,
        data.witnesses and json.encode(data.witnesses) or nil,
        data.evidence_seized and json.encode(data.evidence_seized) or nil,
        data.notes
    })

    if arrestId then
        -- Ajouter au casier criminel
        if data.charges then
            for _, charge in ipairs(data.charges) do
                MySQL.insert.await([[
                    INSERT INTO mdt_criminal_records (
                        citizen_identifier, record_type, charge_code,
                        charge_title, charge_class, arrest_date,
                        arresting_officer, status
                    ) VALUES (?, 'arrest', ?, ?, ?, NOW(), ?, 'active')
                ]], {
                    data.identifier,
                    charge.code,
                    charge.title,
                    charge.class,
                    xPlayer.identifier
                })
            end
        end

        ShowNotification(_source, '✅ Arrestation enregistrée: '..arrestNumber, 'success')
        LogActivity(xPlayer.identifier, 'create', 'arrests', arrestId, {
            arrest_number = arrestNumber,
            citizen = data.identifier
        })

        SendWebhook('PoliceArrests', {
            title = '🚔 Nouvelle Arrestation',
            arrest_number = arrestNumber,
            citizen = data.citizen_name,
            charges_count = data.charges and #data.charges or 0,
            officer = xPlayer.getName()
        })
    end
end)

-- ============================================
-- BOLO (Be On Lookout)
-- ============================================

-- Get active BOLOs
ESX.RegisterServerCallback('zmdt:police:getBOLO', function(source, cb)
    if not HasPermission(source, 'police.bolo.view') then
        cb({})
        return
    end

    local bolos = MySQL.query.await([[
        SELECT b.*, u.firstname, u.lastname
        FROM mdt_bolo b
        LEFT JOIN users u ON u.identifier = b.issued_by
        WHERE b.status = 'active'
        ORDER BY
            FIELD(b.priority, 'critical', 'high', 'medium', 'low'),
            b.issued_at DESC
    ]])

    cb(bolos or {})
end)

-- Create BOLO
RegisterNetEvent('zmdt:police:createBOLO')
AddEventHandler('zmdt:police:createBOLO', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.bolo.create') then return end

    local boloId = MySQL.insert.await([[
        INSERT INTO mdt_bolo (
            bolo_type, subject, description,
            priority, danger_level, zone, issued_by
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.bolo_type,
        data.subject,
        data.description,
        data.priority or 'medium',
        data.danger_level or 'medium',
        data.zone,
        xPlayer.identifier
    })

    if boloId then
        ShowNotification(_source, '✅ BOLO créé #'..boloId, 'success')

        -- Broadcast à tous les policiers
        local bolo = {
            id = boloId,
            bolo_type = data.bolo_type,
            subject = data.subject,
            description = data.description,
            priority = data.priority or 'medium',
            danger_level = data.danger_level or 'medium',
            zone = data.zone,
            issued_by_name = xPlayer.getName(),
            issued_at = os.date('%Y-%m-%d %H:%M:%S')
        }

        BroadcastToPolice('zmdt:police:newBOLO', bolo)

        SendWebhook('PoliceBOLO', {
            title = '⚠️ Nouveau BOLO',
            type = data.bolo_type,
            subject = data.subject,
            priority = data.priority,
            officer = xPlayer.getName()
        })
    end
end)

-- Close BOLO
RegisterNetEvent('zmdt:police:closeBOLO')
AddEventHandler('zmdt:police:closeBOLO', function(boloId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.bolo.create') then return end

    MySQL.update.await([[
        UPDATE mdt_bolo
        SET status = 'closed', closed_by = ?, closed_at = NOW()
        WHERE id = ?
    ]], {xPlayer.identifier, boloId})

    ShowNotification(_source, '✅ BOLO fermé', 'success')
    BroadcastToPolice('zmdt:police:boloClosed', boloId)
end)

-- ============================================
-- CITATIONS / AMENDES
-- ============================================

-- Get citations
ESX.RegisterServerCallback('zmdt:police:getCitations', function(source, cb, identifier)
    if not HasPermission(source, 'police.citations.view') then
        cb({})
        return
    end

    local query = 'SELECT * FROM mdt_citations WHERE 1=1'
    local params = {}

    if identifier then
        query = query .. ' AND citizen_identifier = ?'
        table.insert(params, identifier)
    end

    query = query .. ' ORDER BY created_at DESC LIMIT 100'

    local citations = MySQL.query.await(query, params)
    cb(citations or {})
end)

-- Create citation
RegisterNetEvent('zmdt:police:createCitation')
AddEventHandler('zmdt:police:createCitation', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.citations.create') then return end

    local citationNumber = GenerateNumber('citations')

    local citationId = MySQL.insert.await([[
        INSERT INTO mdt_citations (
            citation_number, citizen_identifier, citizen_name,
            violation_code, violation_description, fine_amount,
            points, location, issued_by, issued_by_name,
            payment_status, due_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'unpaid', DATE_ADD(NOW(), INTERVAL 30 DAY))
    ]], {
        citationNumber,
        data.identifier,
        data.citizen_name,
        data.violation_code,
        data.violation_description,
        data.fine_amount,
        data.points or 0,
        data.location,
        xPlayer.identifier,
        xPlayer.getName()
    })

    if citationId then
        ShowNotification(_source, '✅ Citation émise: '..citationNumber, 'success')

        -- Notifier le joueur si en ligne
        local targetPlayer = ESX.GetPlayerFromIdentifier(data.identifier)
        if targetPlayer then
            TriggerClientEvent('zmdt:police:receiveCitation', targetPlayer.source, {
                citation_number = citationNumber,
                violation = data.violation_description,
                fine_amount = data.fine_amount,
                officer = xPlayer.getName()
            })
        end
    end
end)

-- ============================================
-- PREUVES / EVIDENCE
-- ============================================

-- Get evidence
ESX.RegisterServerCallback('zmdt:police:getEvidence', function(source, cb, filters)
    if not HasPermission(source, 'police.evidence.view') then
        cb({})
        return
    end

    local query = 'SELECT * FROM mdt_evidence WHERE 1=1'
    local params = {}

    if filters and filters.case_id then
        query = query .. ' AND case_id = ?'
        table.insert(params, filters.case_id)
    end

    if filters and filters.report_id then
        query = query .. ' AND report_id = ?'
        table.insert(params, filters.report_id)
    end

    query = query .. ' ORDER BY seized_at DESC LIMIT 100'

    local evidence = MySQL.query.await(query, params)
    cb(evidence or {})
end)

-- Create evidence
RegisterNetEvent('zmdt:police:createEvidence')
AddEventHandler('zmdt:police:createEvidence', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.evidence.create') then return end

    local evidenceNumber = 'EV-' .. os.date('%y') .. '-' .. string.format('%05d', math.random(1, 99999))

    local evidenceId = MySQL.insert.await([[
        INSERT INTO mdt_evidence (
            evidence_number, case_id, report_id, item_type,
            description, quantity, seized_from, seized_location,
            seized_by, storage_location, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'seized')
    ]], {
        evidenceNumber,
        data.case_id,
        data.report_id,
        data.item_type,
        data.description,
        data.quantity or 1,
        data.seized_from,
        data.seized_location,
        xPlayer.identifier,
        data.storage_location or 'Evidence Locker'
    })

    if evidenceId then
        ShowNotification(_source, '✅ Preuve enregistrée: '..evidenceNumber, 'success')
        LogActivity(xPlayer.identifier, 'create', 'evidence', evidenceId, {
            evidence_number = evidenceNumber
        })
    end
end)

-- ============================================
-- PERSONNEL / UNITS
-- ============================================

-- Get active units
ESX.RegisterServerCallback('zmdt:police:getUnits', function(source, cb)
    if not HasPermission(source, 'police.cad.view') then
        cb({})
        return
    end

    local units = MySQL.query.await([[
        SELECT * FROM mdt_units
        WHERE updated_at > DATE_SUB(NOW(), INTERVAL 12 HOUR)
        ORDER BY status, unit_number
    ]])

    cb(units or {})
end)

-- Get officer status
ESX.RegisterServerCallback('zmdt:police:getOfficerStatus', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(nil)
        return
    end

    local status = MySQL.query.await([[
        SELECT * FROM mdt_officer_status
        WHERE officer_identifier = ?
        ORDER BY changed_at DESC
        LIMIT 1
    ]], {xPlayer.identifier})

    cb(status and status[1] or nil)
end)

-- Update officer status (10-codes)
RegisterNetEvent('zmdt:police:updateStatus')
AddEventHandler('zmdt:police:updateStatus', function(statusCode, location)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    MySQL.insert.await([[
        INSERT INTO mdt_officer_status (
            officer_identifier, status_code, location
        ) VALUES (?, ?, ?)
    ]], {xPlayer.identifier, statusCode, location})

    ShowNotification(_source, '✅ Status: '..statusCode, 'success')
    BroadcastToPolice('zmdt:police:statusChanged', {
        officer = xPlayer.getName(),
        status = statusCode,
        location = location
    })
end)

-- ============================================
-- CHARGES PÉNALES (Penal Codes)
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getCharges', function(source, cb, filters)
    if not HasPermission(source, 'police.search.citizen') then
        cb({})
        return
    end

    local query = 'SELECT * FROM mdt_charges WHERE 1=1'
    local params = {}

    if filters and filters.class then
        query = query .. ' AND charge_class = ?'
        table.insert(params, filters.class)
    end

    if filters and filters.search then
        query = query .. ' AND (LOWER(charge_title) LIKE ? OR charge_code LIKE ?)'
        local searchTerm = '%'..filters.search:lower()..'%'
        table.insert(params, searchTerm)
        table.insert(params, searchTerm)
    end

    query = query .. ' ORDER BY charge_class, charge_code'

    local charges = MySQL.query.await(query, params)
    cb(charges or {})
end)

-- ============================================
-- WARRANTS (Lecture seule pour Police)
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getWarrants', function(source, cb, identifier)
    if not HasPermission(source, 'police.warrants.view') then
        cb({})
        return
    end

    local query = [[
        SELECT w.*, u.firstname, u.lastname
        FROM mdt_warrants w
        LEFT JOIN users u ON u.identifier = w.citizen_identifier
        WHERE w.status = 'active'
    ]]
    local params = {}

    if identifier then
        query = query .. ' AND w.citizen_identifier = ?'
        table.insert(params, identifier)
    end

    query = query .. ' ORDER BY w.issued_at DESC'

    local warrants = MySQL.query.await(query, params)
    cb(warrants or {})
end)

-- Execute warrant
RegisterNetEvent('zmdt:police:executeWarrant')
AddEventHandler('zmdt:police:executeWarrant', function(warrantId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not HasPermission(_source, 'police.warrants.execute') then return end

    MySQL.update.await([[
        UPDATE mdt_warrants
        SET status = 'executed', executed_by = ?, executed_at = NOW()
        WHERE id = ?
    ]], {xPlayer.identifier, warrantId})

    ShowNotification(_source, '✅ Mandat exécuté', 'success')
end)

print('^2[ZMDT]^0 Police server loaded - FULL SYSTEM')
