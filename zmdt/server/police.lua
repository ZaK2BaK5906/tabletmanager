-- ============================================
-- ZX POLICE MDT - BACKEND COMPLET
-- ============================================

-- Import ESX
ESX = exports['es_extended']:getSharedObject()

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

    -- Pour les grades > 4, utiliser les permissions du grade 4 (accès total)
    local grade = xPlayer.job.grade
    if grade > 4 then
        grade = 4
    end

    local perms = Config.Permissions.police[grade]
    if not perms then
        print('[ZMDT DEBUG] No permissions found for grade:', xPlayer.job.grade)
        return false
    end

    local hasPermission = perms[permission] == true or perms.all == true
    print('[ZMDT DEBUG] HasPermission for', xPlayer.getName(), 'grade', xPlayer.job.grade, 'permission', permission, '=', hasPermission)

    return hasPermission
end

-- ============================================
-- DASHBOARD
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getDashboard', function(source, cb)
    local stats = {}

    print('[ZMDT DEBUG] getDashboard called for source: ' .. source)

    -- Appels actifs
    local success, result = pcall(function()
        return MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_calls WHERE status IN ("pending","dispatched","on_scene")', {})
    end)
    stats.activeCalls = (success and result and result[1] and result[1].count) or 0

    -- Unités actives
    success, result = pcall(function()
        return MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_units WHERE status != "10-7"', {})
    end)
    stats.activeUnits = (success and result and result[1] and result[1].count) or 0

    -- Arrestations récentes (24h)
    success, result = pcall(function()
        return MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_arrests WHERE arrest_date >= DATE_SUB(NOW(), INTERVAL 24 HOUR)', {})
    end)
    stats.recentArrests = (success and result and result[1] and result[1].count) or 0

    -- BOLO actifs
    success, result = pcall(function()
        return MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_bolo WHERE status = "active"', {})
    end)
    stats.activeBOLO = (success and result and result[1] and result[1].count) or 0

    -- Personnes recherchées
    success, result = pcall(function()
        return MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_wanted WHERE status = "active"', {})
    end)
    stats.wantedPersons = (success and result and result[1] and result[1].count) or 0

    -- Mandats actifs
    success, result = pcall(function()
        return MySQL.query.await('SELECT COUNT(*) as count FROM zx_police_warrants WHERE status IN ("pending","active")', {})
    end)
    stats.activeWarrants = (success and result and result[1] and result[1].count) or 0

    print('[ZMDT DEBUG] Dashboard stats:', json.encode(stats))
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

    local success, calls = pcall(function()
        return MySQL.query.await(query, params)
    end)

    if not success then
        print('[ZMDT ERROR] getCalls failed:', calls)
        cb({})
        return
    end

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
    print('[ZMDT DEBUG] searchCitizen called with query:', query)

    if not HasPermission(source, 'search_citizens') then
        print('[ZMDT DEBUG] No permission for search_citizens')
        cb({})
        return
    end

    -- Si pas de query, retourner tous les citoyens (limité à 50)
    if not query or query == '' then
        local success, citizens = pcall(function()
            return MySQL.query.await('SELECT identifier, firstname, lastname, dateofbirth, sex, height, phone_number, job, job_grade FROM users LIMIT 50', {})
        end)

        if not success then
            print('[ZMDT ERROR] searchCitizen (all) failed:', citizens)
            cb({})
            return
        end

        print('[ZMDT DEBUG] Found', #(citizens or {}), 'citizens (all)')
        cb(citizens or {})
        return
    end

    local success, citizens = pcall(function()
        return MySQL.query.await([[
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
    end)

    if not success then
        print('[ZMDT ERROR] searchCitizen failed:', citizens)
        cb({})
        return
    end

    print('[ZMDT DEBUG] Found', #(citizens or {}), 'citizens matching:', query)
    cb(citizens or {})
end)

-- ============================================
-- PROFIL CITOYEN COMPLET
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getCitizenProfile', function(source, cb, identifier)
    if not HasPermission(source, 'citizen_profile') then
        cb(nil)
        return
    end

    -- Infos de base
    local success, citizen = pcall(function()
        return MySQL.query.await('SELECT * FROM users WHERE identifier = ?', {identifier})
    end)

    if not success or not citizen or not citizen[1] then
        print('[ZMDT ERROR] getCitizenProfile failed or citizen not found:', identifier)
        cb(nil)
        return
    end

    local profile = citizen[1]

    -- Comptes bancaires (si configuré)
    if Config.CitizenSearch.show_bank_accounts then
        local s, r = pcall(function()
            return MySQL.query.await('SELECT * FROM bank_accounts WHERE owner = ?', {identifier})
        end)
        profile.bank_accounts = (s and r) or {}
    end

    -- Véhicules
    if Config.CitizenSearch.show_vehicles then
        local s, r = pcall(function()
            return MySQL.query.await('SELECT plate, vehicle, stored, pound FROM owned_vehicles WHERE owner = ?', {identifier})
        end)
        profile.vehicles = (s and r) or {}
    end

    -- Arrestations
    if Config.CitizenSearch.show_arrests then
        local s, r = pcall(function()
            return MySQL.query.await('SELECT * FROM zx_police_arrests WHERE citizen_identifier = ? ORDER BY arrest_date DESC LIMIT 10', {identifier})
        end)
        profile.arrests = (s and r) or {}
    end

    -- Citations
    if Config.CitizenSearch.show_citations then
        local s, r = pcall(function()
            return MySQL.query.await('SELECT * FROM zx_police_citations WHERE citizen_identifier = ? ORDER BY created_at DESC LIMIT 10', {identifier})
        end)
        profile.citations = (s and r) or {}
    end

    -- Notes
    if Config.CitizenSearch.show_notes then
        local s, r = pcall(function()
            return MySQL.query.await('SELECT * FROM zx_police_notes WHERE citizen_identifier = ? ORDER BY created_at DESC', {identifier})
        end)
        profile.notes = (s and r) or {}
    end

    -- Mandats
    if Config.CitizenSearch.show_warrants then
        local s, r = pcall(function()
            return MySQL.query.await('SELECT * FROM zx_police_warrants WHERE citizen_identifier = ? AND status IN ("pending","active")', {identifier})
        end)
        profile.warrants = (s and r) or {}
    end

    -- PPA
    local s1, r1 = pcall(function()
        return MySQL.query.await('SELECT * FROM zx_police_ppa WHERE citizen_identifier = ? AND status = "active"', {identifier})
    end)
    profile.ppa = (s1 and r1) or {}

    local s2, r2 = pcall(function()
        return MySQL.query.await('SELECT * FROM zx_police_ppa_heavy WHERE citizen_identifier = ? AND status = "active"', {identifier})
    end)
    profile.ppa_heavy = (s2 and r2) or {}

    cb(profile)
end)

-- ============================================
-- RECHERCHE VÉHICULES
-- ============================================

ESX.RegisterServerCallback('zmdt:police:searchVehicle', function(source, cb, plate)
    if not HasPermission(source, 'search_vehicles') then
        cb(nil)
        return
    end

    local success, vehicle = pcall(function()
        return MySQL.query.await([[
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
    end)

    if not success or not vehicle or not vehicle[1] then
        print('[ZMDT ERROR] searchVehicle failed or not found:', plate)
        cb(nil)
        return
    end

    local result = vehicle[1]

    -- Vérifier si volé
    local success2, stolen = pcall(function()
        return MySQL.query.await([[
            SELECT * FROM zx_police_stolen_vehicles
            WHERE plate = ? AND status = 'stolen'
        ]], {result.plate})
    end)

    result.is_stolen = (success2 and stolen and #stolen > 0) or false
    result.stolen_info = (success2 and stolen and stolen[1]) or nil

    cb(result)
end)

-- ============================================
-- ARRESTATIONS
-- ============================================

RegisterNetEvent('zmdt:police:createArrest', function(data)
    local source = source
    print('[ZMDT DEBUG] createArrest called for source:', source)

    if not HasPermission(source, 'arrests_create') then
        print('[ZMDT DEBUG] No permission for arrests_create')
        TriggerClientEvent('zmdt:notify', source, 'error', '❌ Vous n\'avez pas la permission de créer des arrestations')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        print('[ZMDT ERROR] xPlayer not found')
        return
    end

    local arrestNumber = GenerateNumber(Config.AutoNumbering.arrests)
    print('[ZMDT DEBUG] Creating arrest:', arrestNumber)

    local success, insertId = pcall(function()
        return MySQL.insert.await([[
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
        })
    end)

    if not success then
        print('[ZMDT ERROR] Failed to create arrest:', insertId)
        TriggerClientEvent('zmdt:notify', source, 'error', '❌ Erreur lors de la création de l\'arrestation')
        return
    end

    print('[ZMDT DEBUG] Arrest created successfully:', arrestNumber)

    -- Webhook
    pcall(function()
        Webhooks.Send('arrests', 'arrest_created', {
            arrest_number = arrestNumber,
            citizen_name = data.citizen_name,
            officer_name = xPlayer.getName(),
            charges_text = data.charges_text,
            total_fine = data.total_fine,
            total_jail_time = data.total_jail_time,
            location = data.location
        })
    end)

    TriggerClientEvent('zmdt:notify', source, 'success', '✅ Arrestation créée: '..arrestNumber)
end)

-- ============================================
-- RAPPORTS
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getReports', function(source, cb, filters)
    if not HasPermission(source, 'reports_view') then
        cb({})
        return
    end

    local success, reports = pcall(function()
        return MySQL.query.await([[
            SELECT * FROM zx_police_reports
            ORDER BY created_at DESC
            LIMIT 50
        ]], {})
    end)

    if not success then
        print('[ZMDT ERROR] getReports failed:', reports)
        cb({})
        return
    end

    cb(reports or {})
end)

RegisterNetEvent('zmdt:police:createReport', function(data)
    local source = source
    print('[ZMDT DEBUG] createReport called for source:', source)

    if not HasPermission(source, 'reports_create') then
        print('[ZMDT DEBUG] No permission for reports_create')
        TriggerClientEvent('zmdt:notify', source, 'error', '❌ Vous n\'avez pas la permission de créer des rapports')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        print('[ZMDT ERROR] xPlayer not found')
        return
    end

    local reportNumber = GenerateNumber(Config.AutoNumbering.reports)
    print('[ZMDT DEBUG] Creating report:', reportNumber)

    local success, insertId = pcall(function()
        return MySQL.insert.await([[
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
        })
    end)

    if not success then
        print('[ZMDT ERROR] Failed to create report:', insertId)
        TriggerClientEvent('zmdt:notify', source, 'error', '❌ Erreur lors de la création du rapport')
        return
    end

    print('[ZMDT DEBUG] Report created successfully:', reportNumber)

    -- Webhook
    pcall(function()
        Webhooks.Send('reports', 'report_created', {
            report_number = reportNumber,
            title = data.title,
            report_type = data.report_type,
            officer_name = xPlayer.getName(),
            location = data.location
        })
    end)

    TriggerClientEvent('zmdt:notify', source, 'success', '✅ Rapport créé: '..reportNumber)
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
    if not HasPermission(source, 'bolo_view') then
        cb({})
        return
    end

    local success, bolos = pcall(function()
        return MySQL.query.await([[
            SELECT * FROM zx_police_bolo
            WHERE status = 'active'
            ORDER BY priority DESC, issued_at DESC
        ]], {})
    end)

    if not success then
        print('[ZMDT ERROR] getBOLO failed:', bolos)
        cb({})
        return
    end

    cb(bolos or {})
end)

RegisterNetEvent('zmdt:police:createBOLO', function(data)
    local source = source
    print('[ZMDT DEBUG] createBOLO called for source:', source)

    if not HasPermission(source, 'bolo_create') then
        print('[ZMDT DEBUG] No permission for bolo_create')
        TriggerClientEvent('zmdt:notify', source, 'error', '❌ Vous n\'avez pas la permission de créer des BOLO')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        print('[ZMDT ERROR] xPlayer not found')
        return
    end

    print('[ZMDT DEBUG] Creating BOLO:', data.subject)

    local success, insertId = pcall(function()
        return MySQL.insert.await([[
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
        })
    end)

    if not success then
        print('[ZMDT ERROR] Failed to create BOLO:', insertId)
        TriggerClientEvent('zmdt:notify', source, 'error', '❌ Erreur lors de la création du BOLO')
        return
    end

    print('[ZMDT DEBUG] BOLO created successfully, ID:', insertId)

    -- Webhook
    pcall(function()
        Webhooks.Send('bolo', 'bolo_created', {
            bolo_type = data.bolo_type,
            subject = data.subject,
            description = data.description,
            priority = data.priority,
            danger_level = data.danger_level,
            issued_by_name = xPlayer.getName()
        })
    end)

    -- Broadcast à toutes les unités
    TriggerClientEvent('zmdt:police:newBOLO', -1, {
        id = insertId,
        bolo_type = data.bolo_type,
        subject = data.subject,
        priority = data.priority
    })

    TriggerClientEvent('zmdt:notify', source, 'success', '✅ BOLO créé avec succès')
end)

-- ============================================
-- MANDATS
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getWarrants', function(source, cb, filters)
    print('[ZMDT DEBUG] getWarrants called for source:', source)

    if not HasPermission(source, 'warrants_view') then
        print('[ZMDT DEBUG] No permission for warrants_view')
        cb({})
        return
    end

    local success, warrants = pcall(function()
        return MySQL.query.await([[
            SELECT * FROM zx_police_warrants
            WHERE status IN ('pending','active')
            ORDER BY issued_at DESC
        ]], {})
    end)

    if not success then
        print('[ZMDT ERROR] getWarrants failed:', warrants)
        cb({})
        return
    end

    print('[ZMDT DEBUG] Found', #(warrants or {}), 'warrants')
    cb(warrants or {})
end)

RegisterNetEvent('zmdt:police:createWarrant', function(data)
    local source = source
    print('[ZMDT DEBUG] createWarrant called for source:', source)

    if not HasPermission(source, 'warrants_create') then
        print('[ZMDT DEBUG] No permission for warrants_create')
        TriggerClientEvent('zmdt:notify', source, 'error', '❌ Vous n\'avez pas la permission de créer des mandats (Grade 3+ requis)')
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        print('[ZMDT ERROR] xPlayer not found')
        return
    end

    local warrantNumber = GenerateNumber(Config.AutoNumbering.warrants)
    print('[ZMDT DEBUG] Creating warrant:', warrantNumber)

    local success, insertId = pcall(function()
        return MySQL.insert.await([[
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
        })
    end)

    if not success then
        print('[ZMDT ERROR] Failed to create warrant:', insertId)
        TriggerClientEvent('zmdt:notify', source, 'error', '❌ Erreur lors de la création du mandat')
        return
    end

    print('[ZMDT DEBUG] Warrant created successfully:', warrantNumber)

    -- Webhook
    pcall(function()
        Webhooks.Send('warrants', 'warrant_issued', {
            warrant_number = warrantNumber,
            warrant_type = data.warrant_type,
            citizen_name = data.citizen_name,
            address = data.address,
            issued_by_name = xPlayer.getName(),
            status = 'pending'
        })
    end)

    TriggerClientEvent('zmdt:notify', source, 'success', '✅ Mandat créé: '..warrantNumber)
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
    if not HasPermission(source, 'stolen_vehicles') then
        cb({})
        return
    end

    local success, stolen = pcall(function()
        return MySQL.query.await([[
            SELECT * FROM zx_police_stolen_vehicles
            WHERE status = 'stolen'
            ORDER BY stolen_date DESC
        ]], {})
    end)

    if not success then
        print('[ZMDT ERROR] getStolenVehicles failed:', stolen)
        cb({})
        return
    end

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
    if not HasPermission(source, 'charges') then
        cb({})
        return
    end

    local success, charges = pcall(function()
        return MySQL.query.await([[
            SELECT * FROM zx_police_charges
            WHERE is_active = 1
            ORDER BY charge_category, charge_code
        ]], {})
    end)

    if not success then
        print('[ZMDT ERROR] getCharges failed:', charges)
        cb({})
        return
    end

    print('[ZMDT DEBUG] Found', #(charges or {}), 'charges')
    cb(charges or {})
end)

-- ============================================
-- UNITÉS / PATROUILLES
-- ============================================

ESX.RegisterServerCallback('zmdt:police:getUnits', function(source, cb)
    if not HasPermission(source, 'units') then
        cb({})
        return
    end

    local success, units = pcall(function()
        return MySQL.query.await([[
            SELECT * FROM zx_police_units
            ORDER BY unit_number
        ]], {})
    end)

    if not success then
        print('[ZMDT ERROR] getUnits failed:', units)
        cb({})
        return
    end

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
