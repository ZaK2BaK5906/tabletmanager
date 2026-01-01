-- ============================================
-- ZX POLICE MDT - BACKEND COMPLET
-- ============================================

-- Note: Les webhooks sont chargés via fxmanifest.lua
-- Accès via la variable globale Webhooks définie dans server/webhooks.lua

-- ============================================
-- UTILITAIRES
-- ============================================

local function GenerateNumber(format)
    local date = os.date('*t')
    local year = string.format('%02d', date.year % 100)
    local month = string.format('%02d', date.month)
    local day = string.format('%02d', date.day)
    
    -- Trouver le prochain numéro incrémental
    local pattern = format:gsub('%%y', year):gsub('%%m', month):gsub('%%d', day):gsub('%%n', '___')
    local result = MySQL.query.await('SELECT MAX(CAST(SUBSTRING_INDEX(call_number, "-", -1) AS UNSIGNED)) as max_num FROM zx_police_calls WHERE call_number LIKE ?', {pattern:gsub('___', '%')})
    local nextNum = (result[1] and result[1].max_num or 0) + 1
    
    return format:gsub('%%y', year):gsub('%%m', month):gsub('%%d', day):gsub('%%n', string.format('%03d', nextNum))
end

local function HasPermission(source, permission)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end
    
    local perms = Config.Permissions.police[xPlayer.job.grade]
    if not perms then return false end
    
    return perms[permission] == true or perms.all == true
end

-- ============================================
-- DASHBOARD
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getDashboard', function(source, cb)
    local stats = {}
    
    -- Appels actifs
    stats.activeCalls = MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_calls WHERE status IN ("pending","dispatched","on_scene")', {})
    stats.activeCalls = stats.activeCalls[1].count
    
    -- Unités actives
    stats.activeUnits = MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_units WHERE status != "10-7"', {})
    stats.activeUnits = stats.activeUnits[1].count
    
    -- Arrestations récentes (24h)
    stats.recentArrests = MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_arrests WHERE arrest_date >= DATE_SUB(NOW(), INTERVAL 24 HOUR)', {})
    stats.recentArrests = stats.recentArrests[1].count
    
    -- BOLO actifs
    stats.activeBOLO = MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_bolo WHERE status = "active"', {})
    stats.activeBOLO = stats.activeBOLO[1].count
    
    -- Personnes recherchées
    stats.wantedPersons = MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_wanted WHERE status = "active"', {})
    stats.wantedPersons = stats.wantedPersons[1].count
    
    -- Mandats actifs
    stats.activeWarrants = MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_warrants WHERE status IN ("pending","active")', {})
    stats.activeWarrants = stats.activeWarrants[1].count
    
    cb(stats)
end)

-- ============================================
-- CAD / 911 CALLS
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getCalls', function(source, cb, filters)
    local query = 'SELECT * FROM zx_police_calls'
    local conditions = {}
    local params = {}
    
    if filters and filters.status then
        table.insert(conditions, 'status = ?')
        table.insert(params, filters.status)
    end
    
    if #conditions > 0 then
        query = query .. ' WHERE ' .. table.concat(conditions, ' AND ')
    end
    
    query = query .. ' ORDER BY created_at DESC LIMIT 50'
    
    local calls = MySQL.query.await(query, params)
    cb(calls or {})
end)

RegisterNetEvent('zmdt:police:createCall', function(data)
    local source = source
    if not HasPermission(source, 'cad') then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local callNumber = GenerateNumber(Config.AutoNumbering.calls)
    
    MySQL.insert([[
        INSERT INTO zx_police_calls (call_number, priority, call_type, location, postal, caller_name, caller_phone, description, created_by, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ]], {
        callNumber,
        data.priority,
        data.call_type,
        data.location,
        data.postal,
        data.caller_name,
        data.caller_phone,
        data.description,
        xPlayer.identifier
    }, function(id)
        TriggerClientEvent('zmdt:police:callCreated', -1, {
            id = id,
            call_number = callNumber,
            priority = data.priority,
            call_type = data.call_type,
            location = data.location,
            description = data.description
        })
    end)
end)

-- ============================================
-- RECHERCHE CITOYENS
-- ============================================

ESX.RegisterServerCallback('zmdt:police:searchCitizen', function(source, cb, query)
    if not HasPermission(source, 'search_citizens') then cb({}) return end
    
    local citizens = MySQL.query.await([[
        SELECT 
            u.identifier,
            u.firstname,
            u.lastname,
            u.dateofbirth,
            u.sex,
            u.height,
            u.phone_number,
            u.job,
            u.job_grade
        FROM users u
        WHERE LOWER(u.firstname) LIKE ? 
           OR LOWER(u.lastname) LIKE ?
           OR u.identifier LIKE ?
           OR u.phone_number LIKE ?
        LIMIT 20
    ]], {'%'..query:lower()..'%', '%'..query:lower()..'%', '%'..query..'%', '%'..query..'%'})
    
    cb(citizens or {})
end)

-- ============================================
-- PROFIL CITOYEN COMPLET
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getCitizenProfile', function(source, cb, identifier)
    if not HasPermission(source, 'citizen_profile') then cb(nil) return end
    
    -- Infos de base
    local citizen = MySQL.query.await('SELECT * FROM users WHERE identifier = ?', {identifier})
    if not citizen[1] then cb(nil) return end
    
    local profile = citizen[1]
    
    -- Comptes bancaires (si configuré)
    if Config.CitizenSearch.show_bank_accounts then
        profile.bank_accounts = MySQL.query.await('SELECT * FROM bank_accounts WHERE owner = ?', {identifier}) or {}
    end
    
    -- Véhicules
    if Config.CitizenSearch.show_vehicles then
        profile.vehicles = MySQL.query.await([[
            SELECT plate, vehicle, stored, pound
            FROM owned_vehicles 
            WHERE owner = ?
        ]], {identifier}) or {}
    end
    
    -- Arrestations
    if Config.CitizenSearch.show_arrests then
        profile.arrests = MySQL.query.await([[
            SELECT * FROM zx_police_arrests 
            WHERE citizen_identifier = ?
            ORDER BY arrest_date DESC
            LIMIT 10
        ]], {identifier}) or {}
    end
    
    -- Citations
    if Config.CitizenSearch.show_citations then
        profile.citations = MySQL.query.await([[
            SELECT * FROM zx_police_citations
            WHERE citizen_identifier = ?
            ORDER BY created_at DESC
            LIMIT 10
        ]], {identifier}) or {}
    end
    
    -- Notes
    if Config.CitizenSearch.show_notes then
        profile.notes = MySQL.query.await([[
            SELECT * FROM zx_police_notes
            WHERE citizen_identifier = ?
            ORDER BY created_at DESC
        ]], {identifier}) or {}
    end
    
    -- Mandats
    if Config.CitizenSearch.show_warrants then
        profile.warrants = MySQL.query.await([[
            SELECT * FROM zx_police_warrants
            WHERE citizen_identifier = ? AND status IN ('pending','active')
        ]], {identifier}) or {}
    end
    
    -- PPA
    profile.ppa = MySQL.query.await([[
        SELECT * FROM zx_police_ppa
        WHERE citizen_identifier = ? AND status = 'active'
    ]], {identifier}) or {}
    
    profile.ppa_heavy = MySQL.query.await([[
        SELECT * FROM zx_police_ppa_heavy
        WHERE citizen_identifier = ? AND status = 'active'
    ]], {identifier}) or {}
    
    cb(profile)
end)

-- ============================================
-- RECHERCHE VÉHICULES
-- ============================================

ESX.RegisterServerCallback('zmdt:police:searchVehicle', function(source, cb, plate)
    if not HasPermission(source, 'search_vehicles') then cb(nil) return end
    
    -- Chercher dans owned_vehicles
    local vehicle = MySQL.query.await([[
        SELECT 
            ov.plate,
            ov.vehicle,
            ov.owner,
            ov.stored,
            ov.pound,
            u.firstname,
            u.lastname,
            u.phone_number
        FROM owned_vehicles ov
        LEFT JOIN users u ON u.identifier = ov.owner
        WHERE ov.plate LIKE ?
        LIMIT 1
    ]], {'%'..plate..'%'})
    
    if not vehicle[1] then cb(nil) return end
    
    local result = vehicle[1]
    
    -- Vérifier si volé
    local stolen = MySQL.query.await([[
        SELECT * FROM zx_police_stolen_vehicles 
        WHERE plate = ? AND status = 'stolen'
    ]], {result.plate})
    
    result.is_stolen = stolen and #stolen > 0 or false
    result.stolen_info = stolen and stolen[1] or nil
    
    cb(result)
end)

-- ============================================
-- ARRESTATIONS
-- ============================================

RegisterNetEvent('zmdt:police:createArrest', function(data)
    local source = source
    if not HasPermission(source, 'arrests_create') then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local arrestNumber = GenerateNumber(Config.AutoNumbering.arrests)
    
    MySQL.insert([[
        INSERT INTO zx_police_arrests (
            arrest_number, citizen_identifier, citizen_name, charges, total_fine, 
            total_jail_time, location, postal, arresting_officer, arresting_officer_name, 
            assisting_officers, miranda_read, notes
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        arrestNumber,
        data.citizen_identifier,
        data.citizen_name,
        json.encode(data.charges),
        data.total_fine,
        data.total_jail_time,
        data.location,
        data.postal,
        xPlayer.identifier,
        xPlayer.getName(),
        json.encode(data.assisting_officers or {}),
        data.miranda_read and 1 or 0,
        data.notes
    }, function(id)
        -- Webhook
        Webhooks.Send('arrests', 'arrest_created', {
            arrest_number = arrestNumber,
            citizen_name = data.citizen_name,
            officer_name = xPlayer.getName(),
            charges_text = data.charges_text,
            total_fine = data.total_fine,
            total_jail_time = data.total_jail_time,
            location = data.location
        })
        
        TriggerClientEvent('zmdt:notify', source, 'success', 'Arrestation créée: '..arrestNumber)
    end)
end)

-- ============================================
-- RAPPORTS
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getReports', function(source, cb, filters)
    if not HasPermission(source, 'reports_view') then cb({}) return end
    
    local reports = MySQL.query.await([[
        SELECT * FROM zx_police_reports
        ORDER BY created_at DESC
        LIMIT 50
    ]], {})
    
    cb(reports or {})
end)

RegisterNetEvent('zmdt:police:createReport', function(data)
    local source = source
    if not HasPermission(source, 'reports_create') then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local reportNumber = GenerateNumber(Config.AutoNumbering.reports)
    
    MySQL.insert([[
        INSERT INTO zx_police_reports (
            report_number, report_type, title, location, postal, incident_date,
            primary_officer, primary_officer_name, assisting_officers, 
            involved_citizens, involved_vehicles, narrative, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'draft')
    ]], {
        reportNumber,
        data.report_type,
        data.title,
        data.location,
        data.postal,
        data.incident_date,
        xPlayer.identifier,
        xPlayer.getName(),
        json.encode(data.assisting_officers or {}),
        json.encode(data.involved_citizens or {}),
        json.encode(data.involved_vehicles or {}),
        data.narrative
    }, function(id)
        Webhooks.Send('reports', 'report_created', {
            report_number = reportNumber,
            title = data.title,
            report_type = data.report_type,
            officer_name = xPlayer.getName(),
            location = data.location
        })
        
        TriggerClientEvent('zmdt:notify', source, 'success', 'Rapport créé: '..reportNumber)
    end)
end)

-- ============================================
-- CITATIONS
-- ============================================

RegisterNetEvent('zmdt:police:createCitation', function(data)
    local source = source
    if not HasPermission(source, 'citations_create') then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local citationNumber = GenerateNumber(Config.AutoNumbering.citations)
    
    MySQL.insert([[
        INSERT INTO zx_police_citations (
            citation_number, citizen_identifier, citizen_name, violation_code,
            violation_description, fine_amount, points, location, postal,
            vehicle_plate, issued_by, issued_by_name, payment_status, due_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'unpaid', DATE_ADD(NOW(), INTERVAL 30 DAY))
    ]], {
        citationNumber,
        data.citizen_identifier,
        data.citizen_name,
        data.violation_code,
        data.violation_description,
        data.fine_amount,
        data.points or 0,
        data.location,
        data.postal,
        data.vehicle_plate,
        xPlayer.identifier,
        xPlayer.getName()
    }, function(id)
        Webhooks.Send('citations', 'citation_issued', {
            citation_number = citationNumber,
            citizen_name = data.citizen_name,
            officer_name = xPlayer.getName(),
            violation_code = data.violation_code,
            violation_description = data.violation_description,
            fine_amount = data.fine_amount,
            points = data.points or 0
        })
        
        TriggerClientEvent('zmdt:notify', source, 'success', 'Citation émise: '..citationNumber)
    end)
end)

-- ============================================
-- BOLO
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getBOLO', function(source, cb)
    if not HasPermission(source, 'bolo_view') then cb({}) return end
    
    local bolos = MySQL.query.await([[
        SELECT * FROM zx_police_bolo
        WHERE status = 'active'
        ORDER BY priority DESC, issued_at DESC
    ]], {})
    
    cb(bolos or {})
end)

RegisterNetEvent('zmdt:police:createBOLO', function(data)
    local source = source
    if not HasPermission(source, 'bolo_create') then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    
    MySQL.insert([[
        INSERT INTO zx_police_bolo (
            bolo_type, subject, description, last_seen_location, last_seen_postal,
            priority, danger_level, plate, issued_by, issued_by_name, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active')
    ]], {
        data.bolo_type,
        data.subject,
        data.description,
        data.last_seen_location,
        data.last_seen_postal,
        data.priority,
        data.danger_level,
        data.plate,
        xPlayer.identifier,
        xPlayer.getName()
    }, function(id)
        Webhooks.Send('bolo', 'bolo_created', {
            bolo_type = data.bolo_type,
            subject = data.subject,
            description = data.description,
            priority = data.priority,
            danger_level = data.danger_level,
            issued_by_name = xPlayer.getName()
        })
        
        -- Broadcast à toutes les unités
        TriggerClientEvent('zmdt:police:newBOLO', -1, {
            id = id,
            bolo_type = data.bolo_type,
            subject = data.subject,
            priority = data.priority
        })
    end)
end)

-- ============================================
-- MANDATS
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getWarrants', function(source, cb, filters)
    if not HasPermission(source, 'warrants_view') then cb({}) return end
    
    local warrants = MySQL.query.await([[
        SELECT * FROM zx_police_warrants
        WHERE status IN ('pending','active')
        ORDER BY issued_at DESC
    ]], {})
    
    cb(warrants or {})
end)

RegisterNetEvent('zmdt:police:createWarrant', function(data)
    local source = source
    if not HasPermission(source, 'warrants_create') then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local warrantNumber = GenerateNumber(Config.AutoNumbering.warrants)
    
    MySQL.insert([[
        INSERT INTO zx_police_warrants (
            warrant_number, warrant_type, citizen_identifier, citizen_name,
            address, charges, probable_cause, issued_by, issued_by_name,
            expiry_date, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY), 'pending')
    ]], {
        warrantNumber,
        data.warrant_type,
        data.citizen_identifier,
        data.citizen_name,
        data.address,
        json.encode(data.charges or {}),
        data.probable_cause,
        xPlayer.identifier,
        xPlayer.getName()
    }, function(id)
        Webhooks.Send('warrants', 'warrant_issued', {
            warrant_number = warrantNumber,
            warrant_type = data.warrant_type,
            citizen_name = data.citizen_name,
            address = data.address,
            issued_by_name = xPlayer.getName(),
            status = 'pending'
        })
        
        TriggerClientEvent('zmdt:notify', source, 'success', 'Mandat créé: '..warrantNumber)
    end)
end)

-- ============================================
-- PREUVES
-- ============================================

RegisterNetEvent('zmdt:police:logEvidence', function(data)
    local source = source
    if not HasPermission(source, 'evidence_create') then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local evidenceNumber = GenerateNumber(Config.AutoNumbering.evidence)
    
    MySQL.insert([[
        INSERT INTO zx_police_evidence (
            evidence_number, report_id, arrest_id, item_type, item_description,
            quantity, seized_from_identifier, seized_from_name, seized_location,
            seized_postal, seized_by, seized_by_name, storage_location, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'seized')
    ]], {
        evidenceNumber,
        data.report_id,
        data.arrest_id,
        data.item_type,
        data.item_description,
        data.quantity or 1,
        data.seized_from_identifier,
        data.seized_from_name,
        data.seized_location,
        data.seized_postal,
        xPlayer.identifier,
        xPlayer.getName(),
        data.storage_location or 'Evidence Locker'
    }, function(id)
        Webhooks.Send('evidence', 'evidence_logged', {
            evidence_number = evidenceNumber,
            item_type = data.item_type,
            item_description = data.item_description,
            seized_from_name = data.seized_from_name,
            officer_name = xPlayer.getName(),
            storage_location = data.storage_location or 'Evidence Locker'
        })
        
        TriggerClientEvent('zmdt:notify', source, 'success', 'Preuve enregistrée: '..evidenceNumber)
    end)
end)

-- ============================================
-- PPA / PERMIS PORT D'ARME
-- ============================================

RegisterNetEvent('zmdt:police:issuePPA', function(data)
    local source = source
    if not HasPermission(source, 'ppa_issue') then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local ppaNumber = GenerateNumber(Config.AutoNumbering.ppa)
    
    local expiryDate = os.date('%Y-%m-%d', os.time() + (Config.PPA.validity.standard * 86400))
    
    MySQL.insert([[
        INSERT INTO zx_police_ppa (
            permit_number, citizen_identifier, citizen_name, permit_type,
            permit_class, authorized_weapons, restrictions, status,
            issued_date, expiry_date, issued_by, issued_by_name,
            background_check_date, training_completed
        ) VALUES (?, ?, ?, ?, ?, ?, ?, 'active', CURDATE(), ?, ?, ?, CURDATE(), ?)
    ]], {
        ppaNumber,
        data.citizen_identifier,
        data.citizen_name,
        data.permit_type,
        data.permit_class,
        json.encode(data.authorized_weapons or {}),
        data.restrictions,
        expiryDate,
        xPlayer.identifier,
        xPlayer.getName(),
        data.training_completed and 1 or 0
    }, function(id)
        Webhooks.Send('ppa', 'ppa_issued', {
            permit_number = ppaNumber,
            citizen_name = data.citizen_name,
            permit_type = data.permit_type,
            permit_class = data.permit_class,
            expiry_date = expiryDate,
            issued_by_name = xPlayer.getName()
        })
        
        TriggerClientEvent('zmdt:notify', source, 'success', 'PPA délivré: '..ppaNumber)
    end)
end)

-- PPA LOURD
RegisterNetEvent('zmdt:police:issuePPAHeavy', function(data)
    local source = source
    if not HasPermission(source, 'ppa_heavy_issue') then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    local ppaNumber = GenerateNumber(Config.AutoNumbering.ppa_heavy)
    
    local expiryDate = os.date('%Y-%m-%d', os.time() + (Config.PPA.validity.heavy * 86400))
    
    MySQL.insert([[
        INSERT INTO zx_police_ppa_heavy (
            permit_number, citizen_identifier, citizen_name, weapon_category,
            specific_weapons, justification, status, issued_date, expiry_date,
            issued_by, issued_by_name, conditions, background_check_level,
            yearly_review_required, last_review_date
        ) VALUES (?, ?, ?, ?, ?, ?, 'pending', CURDATE(), ?, ?, ?, ?, 'enhanced', 1, CURDATE())
    ]], {
        ppaNumber,
        data.citizen_identifier,
        data.citizen_name,
        data.weapon_category,
        json.encode(data.specific_weapons or {}),
        data.justification,
        expiryDate,
        xPlayer.identifier,
        xPlayer.getName(),
        data.conditions
    }, function(id)
        Webhooks.Send('ppa', 'ppa_heavy_issued', {
            permit_number = ppaNumber,
            citizen_name = data.citizen_name,
            weapon_category = data.weapon_category,
            justification = data.justification,
            expiry_date = expiryDate,
            issued_by_name = xPlayer.getName(),
            approved_by_judge = false
        })
        
        TriggerClientEvent('zmdt:notify', source, 'success', 'PPA Lourd créé (en attente approbation juge): '..ppaNumber)
    end)
end)

-- ============================================
-- VÉHICULES VOLÉS
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getStolenVehicles', function(source, cb)
    if not HasPermission(source, 'stolen_vehicles') then cb({}) return end
    
    local stolen = MySQL.query.await([[
        SELECT * FROM zx_police_stolen_vehicles
        WHERE status = 'stolen'
        ORDER BY stolen_date DESC
    ]], {})
    
    cb(stolen or {})
end)

RegisterNetEvent('zmdt:police:reportStolenVehicle', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    MySQL.insert([[
        INSERT INTO zx_police_stolen_vehicles (
            plate, vehicle_model, vehicle_hash, owner_identifier, owner_name,
            stolen_location, stolen_postal, reported_by, report_id, status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'stolen')
    ]], {
        data.plate,
        data.vehicle_model,
        data.vehicle_hash,
        data.owner_identifier,
        data.owner_name,
        data.stolen_location,
        data.stolen_postal,
        xPlayer.identifier,
        data.report_id
    })
end)

-- ============================================
-- CHARGES PÉNALES
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getCharges', function(source, cb)
    if not HasPermission(source, 'charges') then cb({}) return end
    
    local charges = MySQL.query.await([[
        SELECT * FROM zx_police_charges
        WHERE is_active = 1
        ORDER BY charge_category, charge_code
    ]], {})
    
    cb(charges or {})
end)

-- ============================================
-- UNITÉS / PATROUILLES
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getUnits', function(source, cb)
    if not HasPermission(source, 'units') then cb({}) return end
    
    local units = MySQL.query.await([[
        SELECT * FROM zx_police_units
        ORDER BY unit_number
    ]], {})
    
    cb(units or {})
end)

RegisterNetEvent('zmdt:police:updateUnitStatus', function(status, statusText)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    MySQL.query.await([[
        UPDATE zx_police_units
        SET status = ?, status_text = ?, updated_at = NOW()
        WHERE officer_identifier = ?
    ]], {status, statusText, xPlayer.identifier})
    
    -- Broadcast aux autres unités
    TriggerClientEvent('zmdt:police:unitStatusChanged', -1, {
        officer = xPlayer.identifier,
        status = status,
        statusText = statusText
    })
end)

-- ============================================
-- NOTES / INTEL
-- ============================================

RegisterNetEvent('zmdt:police:addNote', function(data)
    local source = source
    if not HasPermission(source, 'notes_create') then return end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    
    MySQL.insert([[
        INSERT INTO zx_police_notes (
            citizen_identifier, note_text, note_type, is_flagged,
            is_confidential, author_identifier, author_name
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ]], {
        data.citizen_identifier,
        data.note_text,
        data.note_type,
        data.is_flagged and 1 or 0,
        data.is_confidential and 1 or 0,
        xPlayer.identifier,
        xPlayer.getName()
    })
end)

print('^2[ZX Police MDT]^0 Backend chargé - 17 onglets opérationnels')
