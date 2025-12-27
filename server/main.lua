ESX = exports['es_extended']:getSharedObject()

-- Vérifier si un joueur est boss
function IsBoss(xPlayer)
    for _, grade in ipairs(Config.BossGrades) do
        if xPlayer.job.grade_name == grade then
            return true
        end
    end
    return false
end

-- Obtenir les infos d'un joueur (pour pré-remplir la facture via ox_target)
ESX.RegisterServerCallback('tablet:getPlayerInfo', function(source, cb, targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if not xPlayer then
        cb(nil)
        return
    end

    if not targetPlayer then
        cb(nil)
        return
    end

    cb({
        id = targetId,
        name = targetPlayer.getName(),
        identifier = targetPlayer.identifier
    })
end)

-- Obtenir la commission d'un employé
function GetEmployeeCommission(job, identifier)
    local result = MySQL.scalar.await('SELECT commission_percent FROM tablet_employee_commissions WHERE job = ? AND identifier = ?', {
        job, identifier
    })

    if result then
        return result
    else
        -- Créer l'entrée avec la commission par défaut
        MySQL.insert('INSERT INTO tablet_employee_commissions (job, identifier, commission_percent) VALUES (?, ?, ?)', {
            job, identifier, Config.DefaultCommission
        })
        return Config.DefaultCommission
    end
end

-- Obtenir tous les produits d'un job
function GetJobProducts(job)
    return MySQL.query.await('SELECT * FROM tablet_products WHERE job = ? ORDER BY product_name', {job})
end

-- Obtenir tous les partenariats d'un job
function GetJobPartnerships(job)
    return MySQL.query.await('SELECT * FROM tablet_partnerships WHERE job = ? ORDER BY company_name', {job})
end

-- Obtenir les employés du job avec leurs commissions
function GetJobEmployees(job)
    local employees = {}
    local xPlayers = ESX.GetExtendedPlayers('job', job)

    for _, xPlayer in pairs(xPlayers) do
        local commission = GetEmployeeCommission(job, xPlayer.identifier)
        table.insert(employees, {
            identifier = xPlayer.identifier,
            name = xPlayer.getName(),
            commission_percent = commission
        })
    end

    return employees
end

-- Obtenir toutes les entreprises (jobs) disponibles
function GetAllCompanies()
    local companies = {}
    local jobs = ESX.GetJobs()

    for jobName, jobData in pairs(jobs) do
        if jobName ~= 'unemployed' then
            table.insert(companies, {
                name = jobName,
                label = jobData.label
            })
        end
    end

    return companies
end

-- Données initiales du joueur (commission + produits + partenariats + entreprises)
ESX.RegisterServerCallback('tablet:getPlayerData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    local job = xPlayer.job.name
    local identifier = xPlayer.identifier

    -- Commission du joueur
    local commission = GetEmployeeCommission(job, identifier)

    -- Produits du job
    local products = GetJobProducts(job)

    -- Partenariats du job
    local partnerships = GetJobPartnerships(job)

    -- Toutes les entreprises du serveur
    local companies = GetAllCompanies()

    cb({
        commission = commission,
        products = products,
        partnerships = partnerships,
        companies = companies
    })
end)

-- Stats rapides pour accueil
ESX.RegisterServerCallback('tablet:getQuickStats', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    local job = xPlayer.job.name
    local identifier = xPlayer.identifier

    -- Total commission du mois (seulement factures payées)
    local commission = MySQL.scalar.await([[
        SELECT IFNULL(SUM(commission_amount), 0)
        FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
        AND status = 'paid'
        AND MONTH(created_at) = MONTH(CURRENT_DATE())
        AND YEAR(created_at) = YEAR(CURRENT_DATE())
    ]], {job, identifier}) or 0

    -- Nombre de factures du mois (seulement factures payées)
    local invoiceCount = MySQL.scalar.await([[
        SELECT COUNT(*)
        FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
        AND status = 'paid'
        AND MONTH(created_at) = MONTH(CURRENT_DATE())
        AND YEAR(created_at) = YEAR(CURRENT_DATE())
    ]], {job, identifier}) or 0

    cb({
        commission = commission,
        invoiceCount = invoiceCount
    })
end)

-- Historique factures employé
ESX.RegisterServerCallback('tablet:getInvoiceHistory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    local job = xPlayer.job.name
    local identifier = xPlayer.identifier

    local invoices = MySQL.query.await([[
        SELECT * FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
        ORDER BY created_at DESC
        LIMIT 50
    ]], {job, identifier})

    cb(invoices)
end)

-- Stats employé
ESX.RegisterServerCallback('tablet:getStats', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    local job = xPlayer.job.name
    local identifier = xPlayer.identifier

    -- CA du mois (total des factures payées)
    local revenue = MySQL.scalar.await([[
        SELECT IFNULL(SUM(total), 0)
        FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
        AND status = 'paid'
        AND MONTH(created_at) = MONTH(CURRENT_DATE())
        AND YEAR(created_at) = YEAR(CURRENT_DATE())
    ]], {job, identifier}) or 0

    -- Nombre de factures du mois (seulement factures payées)
    local invoiceCount = MySQL.scalar.await([[
        SELECT COUNT(*)
        FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
        AND status = 'paid'
        AND MONTH(created_at) = MONTH(CURRENT_DATE())
        AND YEAR(created_at) = YEAR(CURRENT_DATE())
    ]], {job, identifier}) or 0

    -- Commission totale du mois (seulement factures payées)
    local commission = MySQL.scalar.await([[
        SELECT IFNULL(SUM(commission_amount), 0)
        FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
        AND status = 'paid'
        AND MONTH(created_at) = MONTH(CURRENT_DATE())
        AND YEAR(created_at) = YEAR(CURRENT_DATE())
    ]], {job, identifier}) or 0

    cb({
        revenue = revenue,
        invoiceCount = invoiceCount,
        commission = commission
    })
end)

-- Données de gestion (boss only)
ESX.RegisterServerCallback('tablet:getManagementData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsBoss(xPlayer) then cb(nil) return end

    local job = xPlayer.job.name

    local products = GetJobProducts(job)
    local partnerships = GetJobPartnerships(job)
    local employees = GetJobEmployees(job)

    cb({
        products = products,
        partnerships = partnerships,
        employees = employees
    })
end)

-- Stats détaillées des employés (boss only)
ESX.RegisterServerCallback('tablet:getEmployeeStats', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsBoss(xPlayer) then cb(nil) return end

    local job = xPlayer.job.name

    -- Récupérer tous les employés du job avec leurs stats
    local employeeStats = {}
    local xPlayers = ESX.GetExtendedPlayers('job', job)

    for _, player in pairs(xPlayers) do
        local identifier = player.identifier
        local name = player.getName()

        -- Stats du mois en cours
        local monthStats = MySQL.single.await([[
            SELECT
                COUNT(*) as invoice_count,
                IFNULL(SUM(CASE WHEN status = 'paid' THEN subtotal ELSE 0 END), 0) as total_ht,
                IFNULL(SUM(CASE WHEN status = 'paid' THEN total ELSE 0 END), 0) as total_ttc,
                IFNULL(SUM(CASE WHEN status = 'paid' THEN commission_amount ELSE 0 END), 0) as total_commission
            FROM tablet_invoices
            WHERE job = ? AND employee_identifier = ?
            AND MONTH(created_at) = MONTH(CURRENT_DATE())
            AND YEAR(created_at) = YEAR(CURRENT_DATE())
        ]], {job, identifier})

        -- Commission actuelle
        local commission = GetEmployeeCommission(job, identifier)

        -- Récupérer la date de dernier reset pour cet employé
        local resetData = MySQL.single.await([[
            SELECT commission_reset_date
            FROM employee_financial_tracking
            WHERE job = ? AND employee_identifier = ?
        ]], {job, identifier})

        local resetDate = (resetData and resetData.commission_reset_date) or '1970-01-01'

        -- Commissions en attente depuis le dernier reset
        local pendingCommission = MySQL.scalar.await([[
            SELECT COALESCE(SUM(commission_amount), 0)
            FROM tablet_invoices
            WHERE job = ? AND employee_identifier = ? AND status = 'paid'
            AND commission_amount > 0
            AND paid_at > ?
        ]], {job, identifier, resetDate}) or 0

        table.insert(employeeStats, {
            identifier = identifier,
            name = name,
            commission_percent = commission,
            invoice_count = monthStats and monthStats.invoice_count or 0,
            total_ht = monthStats and tonumber(monthStats.total_ht) or 0,
            total_ttc = monthStats and tonumber(monthStats.total_ttc) or 0,
            total_commission = monthStats and tonumber(monthStats.total_commission) or 0,
            pending_commission = tonumber(pendingCommission)
        })
    end

    -- Stats globales de l'entreprise (période en cours)
    local companyStats = MySQL.single.await([[
        SELECT
            IFNULL(SUM(CASE WHEN status = 'paid' THEN total ELSE 0 END), 0) as total_revenue,
            IFNULL(SUM(CASE WHEN status = 'paid' THEN commission_amount ELSE 0 END), 0) as total_commissions
        FROM tablet_invoices
        WHERE job = ?
    ]], {job})

    -- Total des achats véhicules (dealership uniquement)
    local totalVehiclePurchases = 0
    if job == 'dealership' then
        totalVehiclePurchases = MySQL.scalar.await([[
            SELECT IFNULL(SUM(total_cost), 0)
            FROM vehicle_orders
            WHERE job = ?
        ]], {job}) or 0
    end

    -- Calcul du bénéfice net
    local totalRevenue = companyStats and tonumber(companyStats.total_revenue) or 0
    local totalCommissions = companyStats and tonumber(companyStats.total_commissions) or 0
    local totalProfit = totalRevenue - totalCommissions - tonumber(totalVehiclePurchases)

    cb({
        employees = employeeStats,
        totalVehiclePurchases = tonumber(totalVehiclePurchases),
        totalProfit = totalProfit
    })
end)

-- Réinitialiser les ventes (boss only)
RegisterNetEvent('tablet:resetSales', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then
        ShowNotification(_source, '❌ Seuls les patrons peuvent réinitialiser les ventes', 'error')
        return
    end

    local job = xPlayer.job.name

    -- Compter le nombre de factures et commandes avant suppression
    local invoiceCount = MySQL.scalar.await('SELECT COUNT(*) FROM tablet_invoices WHERE job = ?', {job}) or 0
    local vehicleOrderCount = 0

    if job == 'dealership' then
        vehicleOrderCount = MySQL.scalar.await('SELECT COUNT(*) FROM vehicle_orders WHERE job = ?', {job}) or 0
    end

    -- Supprimer toutes les factures du job
    MySQL.query('DELETE FROM tablet_invoices WHERE job = ?', {job})

    -- Supprimer toutes les commandes véhicules si dealership
    if job == 'dealership' then
        MySQL.query('DELETE FROM vehicle_orders WHERE job = ?', {job})
    end

    ShowNotification(_source, '✅ Toutes les ventes ont été réinitialisées', 'success')

    -- Webhook
    SendWebhook('SalesReset', {
        job = job,
        resetBy = xPlayer.getName(),
        affectedInvoices = invoiceCount,
        affectedVehicleOrders = vehicleOrderCount
    })

    -- Rafraîchir les stats pour tous les employés du job
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:refreshStats', player.source)
    end
end)

-- Historique des transactions (boss only)
ESX.RegisterServerCallback('tablet:getTransactionHistory', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsBoss(xPlayer) then cb(nil) return end

    local job = xPlayer.job.name
    local societyAccount = 'society_' .. job

    -- Récupérer le solde DIRECTEMENT depuis addon_account_data
    local accountData = MySQL.single.await('SELECT money FROM addon_account_data WHERE account_name = ? AND owner IS NULL', {societyAccount})
    local balance = accountData and tonumber(accountData.money) or 0

    -- Récupérer les dates de reset (avec gestion si colonnes n'existent pas encore)
    local resetDates = {}
    local hasResetColumns = pcall(function()
        resetDates = MySQL.single.await([[
            SELECT commission_reset_date, vat_reset_date
            FROM company_profiles
            WHERE job_name = ?
        ]], {job}) or {}
    end)

    local commissionResetDate = (hasResetColumns and resetDates.commission_reset_date) or '1970-01-01'
    local vatResetDate = (hasResetColumns and resetDates.vat_reset_date) or '1970-01-01'

    -- Récupérer factures payées (crédits)
    local paidInvoices = MySQL.query.await([[
        SELECT
            total as amount,
            paid_at as date,
            CONCAT('Facture #', id, ' - ', customer_name) as label
        FROM tablet_invoices
        WHERE job = ? AND status = 'paid'
        ORDER BY paid_at DESC
        LIMIT 100
    ]], {job}) or {}

    local transactions = {}

    for _, invoice in ipairs(paidInvoices) do
        table.insert(transactions, {
            type = 'credit',
            amount = tonumber(invoice.amount),
            date = invoice.date,
            label = invoice.label
        })
    end

    -- Récupérer commissions payées (débits)
    local commissions = MySQL.query.await([[
        SELECT
            commission_amount as amount,
            paid_at as date,
            CONCAT('Commission - ', employee_name) as label
        FROM tablet_invoices
        WHERE job = ? AND status = 'paid' AND commission_amount > 0
        ORDER BY paid_at DESC
        LIMIT 100
    ]], {job}) or {}

    for _, comm in ipairs(commissions) do
        table.insert(transactions, {
            type = 'debit',
            amount = tonumber(comm.amount),
            date = comm.date,
            label = comm.label
        })
    end

    -- Récupérer commandes de véhicules (débits) - dealership only
    if job == 'dealership' then
        local vehicleOrders = MySQL.query.await([[
            SELECT
                total_cost as amount,
                ordered_at as date,
                CONCAT('Commande - ', quantity, 'x ', vehicle_name) as label
            FROM vehicle_orders
            WHERE job = ?
            ORDER BY ordered_at DESC
            LIMIT 100
        ]], {job}) or {}

        for _, order in ipairs(vehicleOrders) do
            table.insert(transactions, {
                type = 'debit',
                amount = tonumber(order.amount),
                date = order.date,
                label = order.label
            })
        end
    end

    -- Trier par date
    table.sort(transactions, function(a, b)
        return (a.date or '') > (b.date or '')
    end)

    -- Calculer totaux
    local totalCredits = 0
    local totalDebits = 0

    for _, trans in ipairs(transactions) do
        if trans.type == 'credit' then
            totalCredits = totalCredits + trans.amount
        else
            totalDebits = totalDebits + trans.amount
        end
    end

    -- Calculer estimations depuis dernier reset (seulement si colonnes existent)
    local pendingCommissions = 0
    local pendingVAT = 0
    local projectedBalance = balance

    print('[TABLET DEBUG] hasResetColumns:', hasResetColumns)
    print('[TABLET DEBUG] commission_reset_date:', commissionResetDate)
    print('[TABLET DEBUG] vat_reset_date:', vatResetDate)

    if hasResetColumns then
        -- Total commissions depuis reset
        pendingCommissions = MySQL.scalar.await([[
            SELECT COALESCE(SUM(commission_amount), 0)
            FROM tablet_invoices
            WHERE job = ? AND status = 'paid'
            AND commission_amount > 0
            AND paid_at > ?
        ]], {job, commissionResetDate}) or 0

        print('[TABLET DEBUG] pendingCommissions calculated:', pendingCommissions)

        -- Total VAT (16.75%) depuis reset
        local allInvoicesForVAT = MySQL.query.await([[
            SELECT total
            FROM tablet_invoices
            WHERE job = ? AND status = 'paid'
            AND paid_at > ?
        ]], {job, vatResetDate}) or {}

        print('[TABLET DEBUG] Invoices for VAT count:', #allInvoicesForVAT)

        for _, inv in ipairs(allInvoicesForVAT) do
            pendingVAT = pendingVAT + (tonumber(inv.total) * 0.1675)
        end

        print('[TABLET DEBUG] pendingVAT calculated:', pendingVAT)

        -- Solde prévisionnel après primes et VAT
        projectedBalance = balance - pendingCommissions - pendingVAT
        print('[TABLET DEBUG] projectedBalance:', projectedBalance)
    end

    cb({
        balance = balance,
        transactions = transactions,
        totalCredits = totalCredits,
        totalDebits = totalDebits,
        pendingCommissions = pendingCommissions,
        pendingVAT = pendingVAT,
        projectedBalance = projectedBalance
    })
end)

-- Reset TOUTES les factures de l'entreprise (boss only) - utilisé par les boutons dans Historique
RegisterNetEvent('tablet:resetCommissions')
AddEventHandler('tablet:resetCommissions', function()
    local _source = source
    print('[TABLET DEBUG] Reset ALL invoices event received from source:', _source)

    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then
        print('[TABLET DEBUG] Reset rejected - not boss')
        return
    end

    local job = xPlayer.job.name
    print('[TABLET DEBUG] Deleting ALL invoices for job:', job)

    -- Compter le nombre de factures avant suppression
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM tablet_invoices WHERE job = ?', {job}) or 0

    -- Supprimer TOUTES les factures du job
    MySQL.query('DELETE FROM tablet_invoices WHERE job = ?', {job})

    print('[TABLET DEBUG] Deleted', count, 'invoices')
    ShowNotification(_source, '✅ Toutes les factures ont été supprimées (' .. count .. ')', 'success')

    -- Webhook
    SendWebhook('CommissionReset', {
        job = job,
        resetBy = xPlayer.getName(),
        affectedInvoices = count
    })

    -- Rafraîchir les stats pour tous les employés du job
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:refreshStats', player.source)
    end
end)

-- Reset VAT = même chose que reset commissions (supprime toutes les factures)
RegisterNetEvent('tablet:resetVAT')
AddEventHandler('tablet:resetVAT', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    -- Compter le nombre de factures avant suppression
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM tablet_invoices WHERE job = ?', {job}) or 0

    -- Supprimer TOUTES les factures du job
    MySQL.query('DELETE FROM tablet_invoices WHERE job = ?', {job})

    ShowNotification(_source, '✅ Toutes les factures ont été supprimées (' .. count .. ')', 'success')

    -- Webhook
    SendWebhook('VATReset', {
        job = job,
        resetBy = xPlayer.getName(),
        affectedInvoices = count
    })

    -- Rafraîchir les stats pour tous les employés du job
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:refreshStats', player.source)
    end
end)

-- Reset factures individuelles d'un employé (boss only) - supprime ses factures
RegisterNetEvent('tablet:resetEmployeeCommission')
AddEventHandler('tablet:resetEmployeeCommission', function(employeeIdentifier)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    print('[TABLET DEBUG] Deleting invoices for employee:', employeeIdentifier, 'in job:', job)

    -- Compter le nombre de factures avant suppression
    local count = MySQL.scalar.await([[
        SELECT COUNT(*) FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
    ]], {job, employeeIdentifier}) or 0

    -- Supprimer TOUTES les factures de cet employé
    MySQL.query([[
        DELETE FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
    ]], {job, employeeIdentifier})

    print('[TABLET DEBUG] Deleted', count, 'invoices for employee')
    ShowNotification(_source, '✅ Factures de l\'employé supprimées (' .. count .. ')', 'success')

    -- Webhook
    SendWebhook('EmployeeCommissionReset', {
        job = job,
        employee = employeeIdentifier,
        resetBy = xPlayer.getName(),
        affectedInvoices = count
    })

    -- Rafraîchir les stats pour tous les employés du job
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:refreshStats', player.source)
    end
end)

-- Données audit pour DOJ (accès complet à toutes les sociétés)
ESX.RegisterServerCallback('tablet:getAuditData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    -- Vérifier l'accès audit
    local hasAccess = false
    for _, job in ipairs(Config.AuditJobs) do
        if xPlayer.job.name == job then
            hasAccess = true
            break
        end
    end

    if not hasAccess then
        cb(nil)
        return
    end

    -- Récupérer toutes les sociétés avec leurs stats
    local societies = {}
    local jobs = ESX.GetJobs()

    for jobName, jobData in pairs(jobs) do
        if jobName ~= 'unemployed' then
            -- Stats du mois
            local stats = MySQL.single.await([[
                SELECT
                    COUNT(*) as total_invoices,
                    IFNULL(SUM(CASE WHEN status = 'paid' THEN total ELSE 0 END), 0) as revenue,
                    IFNULL(SUM(CASE WHEN status = 'paid' THEN commission_amount ELSE 0 END), 0) as commissions,
                    IFNULL(SUM(CASE WHEN status = 'pending' THEN total ELSE 0 END), 0) as pending_amount
                FROM tablet_invoices
                WHERE job = ?
                AND MONTH(created_at) = MONTH(CURRENT_DATE())
                AND YEAR(created_at) = YEAR(CURRENT_DATE())
            ]], {jobName})

            -- Argent de la société
            local societyMoney = 0
            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..jobName, function(account)
                if account then
                    societyMoney = account.money
                end
            end)

            table.insert(societies, {
                job = jobName,
                label = jobData.label,
                total_invoices = stats and stats.total_invoices or 0,
                revenue = stats and tonumber(stats.revenue) or 0,
                commissions = stats and tonumber(stats.commissions) or 0,
                pending_amount = stats and tonumber(stats.pending_amount) or 0,
                society_money = societyMoney
            })
        end
    end

    cb(societies)
end)

-- Créer une facture
RegisterNetEvent('tablet:createInvoice', function(invoiceData)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local job = xPlayer.job.name
    local identifier = xPlayer.identifier
    local playerName = xPlayer.getName()

    -- Calculer les totaux
    local subtotal = 0
    for _, item in ipairs(invoiceData.items) do
        subtotal = subtotal + item.total
    end

    local manualDiscount = invoiceData.manualDiscount or 0
    local partnershipDiscount = 0
    local partnershipName = nil

    if invoiceData.partnership then
        partnershipDiscount = invoiceData.partnership.discount
        partnershipName = invoiceData.partnership.name
    end

    local totalDiscount = manualDiscount + partnershipDiscount
    local discountAmount = subtotal * (totalDiscount / 100)
    local afterDiscount = subtotal - discountAmount
    local taxAmount = afterDiscount * (Config.TaxRate / 100)
    local total = afterDiscount + taxAmount

    -- Commission (calculée sur le HT, pas le TTC)
    local commissionPercent = GetEmployeeCommission(job, identifier)
    local commissionAmount = afterDiscount * (commissionPercent / 100)

    -- Type de facture (citizen ou company)
    local invoiceType = invoiceData.type or 'citizen'
    local targetIdentifier = nil
    local targetCompany = nil

    -- Vérifier la cible selon le type
    if invoiceType == 'citizen' then
        -- Facturation citoyen
        local targetId = invoiceData.targetId
        local targetPlayer = ESX.GetPlayerFromId(targetId)

        if not targetPlayer then
            ShowNotification(_source, '❌ Joueur introuvable (ID: '..targetId..')', 'error')
            return
        end

        targetIdentifier = targetPlayer.identifier
    else
        -- Facturation entreprise
        targetCompany = invoiceData.targetCompany

        if not targetCompany then
            ShowNotification(_source, '❌ Entreprise invalide', 'error')
            return
        end
    end

    -- Créer la facture en statut PENDING (pas de paiement immédiat)
    local invoiceId = MySQL.insert.await([[
        INSERT INTO tablet_invoices
        (job, employee_identifier, employee_name, items, subtotal, discount_percent, partnership_discount, partnership_name, tax_percent, total, commission_percent, commission_amount, invoice_type, target_identifier, target_company, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ]], {
        job,
        identifier,
        playerName,
        json.encode(invoiceData.items),
        subtotal,
        manualDiscount,
        partnershipDiscount,
        partnershipName,
        Config.TaxRate,
        total,
        commissionPercent,
        commissionAmount,
        invoiceType,
        targetIdentifier,
        targetCompany
    })

    -- Notification au créateur
    ShowNotification(_source, '✅ Facture #'..invoiceId..' créée: '..total..'$ (En attente de paiement)', 'success')

    -- Notification à la cible
    if invoiceType == 'citizen' then
        local targetPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
        if targetPlayer then
            local jobLabel = ESX.GetJobs()[job] and ESX.GetJobs()[job].label or job
            ShowNotification(targetPlayer.source, '📄 Nouvelle facture reçue: '..total..'$ de '..jobLabel..' • Tapez /facture', 'info')
        end
    elseif invoiceType == 'company' and targetCompany then
        -- Notifier tous les patrons de l'entreprise cible en ligne
        local jobLabel = ESX.GetJobs()[job] and ESX.GetJobs()[job].label or job
        local xPlayers = ESX.GetExtendedPlayers()
        for _, targetPlayer in ipairs(xPlayers) do
            if targetPlayer.job.name == targetCompany and IsBoss(targetPlayer) then
                ShowNotification(targetPlayer.source, '📄 Nouvelle facture entreprise reçue: '..total..'$ de '..jobLabel..' • Tapez /facture', 'warning')
            end
        end
    end

    -- Webhook
    local jobLabel = ESX.GetJobs()[job] and ESX.GetJobs()[job].label or job
    SendWebhook('InvoiceCreated', {
        invoiceId = invoiceId,
        job = job,
        jobLabel = jobLabel,
        employeeName = playerName,
        total = total,
        commissionAmount = commissionAmount,
        commissionPercent = commissionPercent,
        invoiceType = invoiceType,
        targetName = invoiceData.targetName,
        targetCompany = targetCompany
    })

    -- Reload data
    TriggerClientEvent('tablet:invoiceCreated', _source)
end)

-- Récupérer les factures en attente d'un joueur
ESX.RegisterServerCallback('tablet:getPendingInvoices', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    local identifier = xPlayer.identifier
    local job = xPlayer.job.name
    local invoices = {}

    -- Factures citoyennes en attente pour ce joueur
    local citizenInvoices = MySQL.query.await([[
        SELECT * FROM tablet_invoices
        WHERE target_identifier = ? AND status = 'pending'
        ORDER BY created_at DESC
    ]], {identifier})

    for _, invoice in ipairs(citizenInvoices) do
        table.insert(invoices, invoice)
    end

    -- Factures entreprise en attente (si boss)
    if IsBoss(xPlayer) then
        local companyInvoices = MySQL.query.await([[
            SELECT * FROM tablet_invoices
            WHERE target_company = ? AND status = 'pending'
            ORDER BY created_at DESC
        ]], {job})

        for _, invoice in ipairs(companyInvoices) do
            table.insert(invoices, invoice)
        end
    end

    cb(invoices)
end)

-- Payer une facture
RegisterNetEvent('tablet:payInvoice', function(invoiceId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    -- Récupérer la facture
    local invoice = MySQL.single.await('SELECT * FROM tablet_invoices WHERE id = ? AND status = \'pending\'', {invoiceId})

    if not invoice then
        ShowNotification(_source, '❌ Facture introuvable ou déjà payée', 'error')
        return
    end

    local total = tonumber(invoice.total)

    -- Si facture citoyen
    if invoice.invoice_type == 'citizen' then
        -- Vérifier que c'est bien pour ce joueur
        if invoice.target_identifier ~= xPlayer.identifier then
            ShowNotification(_source, '❌ Cette facture ne vous est pas destinée', 'error')
            return
        end

        -- Vérifier l'argent du joueur
        local money = tonumber(xPlayer.getAccount('bank').money) or 0
        if money < total then
            ShowNotification(_source, '❌ Vous n\'avez pas assez d\'argent en banque', 'error')
            return
        end

        -- Débiter le joueur
        xPlayer.removeAccountMoney('bank', total)

        -- Créditer le compte société du job
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..invoice.job, function(account)
            if account then
                account.addMoney(total)
            end
        end)

        -- Notifications
        ShowNotification(_source, '✅ Facture #'..invoiceId..' payée: '..total..'$', 'success')

    -- Si facture entreprise
    elseif invoice.invoice_type == 'company' then
        -- Vérifier que le joueur est boss de l'entreprise cible
        if xPlayer.job.name ~= invoice.target_company or not IsBoss(xPlayer) then
            ShowNotification(_source, '❌ Vous devez être patron de '..invoice.target_company..' pour payer cette facture', 'error')
            return
        end

        -- Vérifier l'argent de la société
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..invoice.target_company, function(payerAccount)
            if not payerAccount then
                ShowNotification(_source, '❌ Compte entreprise introuvable', 'error')
                return
            end

            if tonumber(payerAccount.money) < total then
                ShowNotification(_source, '❌ Votre entreprise n\'a pas assez d\'argent', 'error')
                return
            end

            -- Débiter l'entreprise payeuse
            payerAccount.removeMoney(total)

            -- Créditer l'entreprise créatrice
            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..invoice.job, function(receiverAccount)
                if receiverAccount then
                    receiverAccount.addMoney(total)
                end
            end)

            -- Mettre à jour le statut
            MySQL.update.await('UPDATE tablet_invoices SET status = \'paid\', paid_at = NOW() WHERE id = ?', {invoiceId})

            -- Notifications
            ShowNotification(_source, '✅ Facture #'..invoiceId..' payée par votre entreprise: '..total..'$', 'success')

            -- Notifier l'employé créateur
            local employeePlayer = ESX.GetPlayerFromIdentifier(invoice.employee_identifier)
            if employeePlayer then
                ShowNotification(employeePlayer.source, '💰 Facture #'..invoiceId..' payée par '..invoice.target_company..'! Commission: '..tonumber(invoice.commission_amount)..'$', 'info')
                -- Rafraîchir les stats de l'employé dans sa tablette
                TriggerClientEvent('tablet:refreshStats', employeePlayer.source)
                -- Rafraîchir la liste des factures de l'employé
                TriggerClientEvent('tablet:refreshInvoices', employeePlayer.source)
            end

            -- Notifier les patrons de l'entreprise créatrice
            local xPlayers = ESX.GetExtendedPlayers()
            for _, bossPlayer in ipairs(xPlayers) do
                if bossPlayer.job.name == invoice.job and IsBoss(bossPlayer) and bossPlayer.identifier ~= invoice.employee_identifier then
                    ShowNotification(bossPlayer.source, '💰 Facture #'..invoiceId..' payée: '..total..'$ de '..invoice.target_company, 'success')
                    TriggerClientEvent('tablet:refreshInvoices', bossPlayer.source)
                end
            end

            -- Webhook
            SendWebhook('InvoicePaid', {
                invoiceId = invoiceId,
                job = invoice.job,
                total = tonumber(total),
                commissionAmount = tonumber(invoice.commission_amount),
                societyAmount = tonumber(total),
                paidBy = invoice.target_company
            })

            -- Refresh
            TriggerClientEvent('tablet:refreshInvoices', _source)
        end)

        return -- Important: sortir ici car traitement async
    end

    -- Mettre à jour le statut de la facture (citoyen uniquement, company géré dans le callback)
    MySQL.update.await('UPDATE tablet_invoices SET status = \'paid\', paid_at = NOW() WHERE id = ?', {invoiceId})

    -- Notifier l'employé qui a créé la facture s'il est connecté
    local employeePlayer = ESX.GetPlayerFromIdentifier(invoice.employee_identifier)
    if employeePlayer then
        ShowNotification(employeePlayer.source, '💰 Facture #'..invoiceId..' payée par le client! Commission: '..tonumber(invoice.commission_amount)..'$', 'info')
        -- Rafraîchir les stats de l'employé dans sa tablette
        TriggerClientEvent('tablet:refreshStats', employeePlayer.source)
        -- Rafraîchir la liste des factures de l'employé
        TriggerClientEvent('tablet:refreshInvoices', employeePlayer.source)
    end

    -- Notifier les patrons de l'entreprise créatrice
    local xPlayers = ESX.GetExtendedPlayers()
    for _, bossPlayer in ipairs(xPlayers) do
        if bossPlayer.job.name == invoice.job and IsBoss(bossPlayer) and bossPlayer.identifier ~= invoice.employee_identifier then
            ShowNotification(bossPlayer.source, '💰 Facture #'..invoiceId..' payée: '..total..'$', 'success')
            TriggerClientEvent('tablet:refreshInvoices', bossPlayer.source)
        end
    end

    -- Webhook
    SendWebhook('InvoicePaid', {
        invoiceId = invoiceId,
        job = invoice.job,
        total = tonumber(invoice.total),
        commissionAmount = tonumber(invoice.commission_amount),
        societyAmount = tonumber(invoice.total) - tonumber(invoice.commission_amount),
        paidBy = xPlayer.getName()
    })

    -- Refresh la liste
    TriggerClientEvent('tablet:refreshInvoices', _source)
end)

-- Annuler/Supprimer une facture (boss only)
RegisterNetEvent('tablet:cancelInvoice', function(invoiceId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then
        ShowNotification(_source, '❌ Seuls les patrons peuvent annuler des factures', 'error')
        return
    end

    local job = xPlayer.job.name

    -- Récupérer la facture pour vérifier qu'elle appartient à ce job
    local invoice = MySQL.single.await('SELECT * FROM tablet_invoices WHERE id = ? AND job = ?', {invoiceId, job})

    if not invoice then
        ShowNotification(_source, '❌ Facture introuvable', 'error')
        return
    end

    -- Si la facture est déjà payée, rembourser
    if invoice.status == 'paid' then
        local total = tonumber(invoice.total)

        -- Débiter le compte société du job
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
            if account and account.money >= total then
                account.removeMoney(total)

                -- Rembourser selon le type
                if invoice.invoice_type == 'citizen' then
                    -- Rembourser le citoyen
                    local targetPlayer = ESX.GetPlayerFromIdentifier(invoice.target_identifier)
                    if targetPlayer then
                        targetPlayer.addAccountMoney('bank', total)
                        ShowNotification(targetPlayer.source, '💰 Facture #'..invoiceId..' annulée - Remboursé: '..total..'$', 'info')
                    end
                elseif invoice.invoice_type == 'company' then
                    -- Rembourser l'entreprise
                    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..invoice.target_company, function(targetAccount)
                        if targetAccount then
                            targetAccount.addMoney(total)
                        end
                    end)

                    -- Notifier les patrons de l'entreprise remboursée
                    local xPlayers = ESX.GetExtendedPlayers()
                    for _, bossPlayer in ipairs(xPlayers) do
                        if bossPlayer.job.name == invoice.target_company and IsBoss(bossPlayer) then
                            ShowNotification(bossPlayer.source, '💰 Facture #'..invoiceId..' annulée - Remboursé: '..total..'$', 'info')
                        end
                    end
                end

                -- Mettre à jour le statut
                MySQL.update.await('UPDATE tablet_invoices SET status = \'cancelled\' WHERE id = ?', {invoiceId})
                ShowNotification(_source, '✅ Facture #'..invoiceId..' annulée et remboursée', 'success')

                -- Notifier l'employé créateur
                local employeePlayer = ESX.GetPlayerFromIdentifier(invoice.employee_identifier)
                if employeePlayer then
                    ShowNotification(employeePlayer.source, '❌ Votre facture #'..invoiceId..' a été annulée et remboursée', 'error')
                    TriggerClientEvent('tablet:refreshStats', employeePlayer.source)
                    TriggerClientEvent('tablet:refreshInvoices', employeePlayer.source)
                end
            else
                ShowNotification(_source, '❌ Votre société n\'a pas assez d\'argent pour rembourser', 'error')
            end
        end)
    else
        -- Si pending, juste annuler
        MySQL.update.await('UPDATE tablet_invoices SET status = \'cancelled\' WHERE id = ?', {invoiceId})
        ShowNotification(_source, '✅ Facture #'..invoiceId..' annulée', 'success')

        -- Notifier l'employé créateur
        local employeePlayer = ESX.GetPlayerFromIdentifier(invoice.employee_identifier)
        if employeePlayer then
            ShowNotification(employeePlayer.source, '❌ Votre facture #'..invoiceId..' a été annulée', 'warning')
            TriggerClientEvent('tablet:refreshInvoices', employeePlayer.source)
        end

        -- Notifier la cible
        if invoice.invoice_type == 'citizen' then
            local targetPlayer = ESX.GetPlayerFromIdentifier(invoice.target_identifier)
            if targetPlayer then
                ShowNotification(targetPlayer.source, '✅ Facture #'..invoiceId..' annulée', 'info')
            end
        elseif invoice.invoice_type == 'company' then
            local xPlayers = ESX.GetExtendedPlayers()
            for _, bossPlayer in ipairs(xPlayers) do
                if bossPlayer.job.name == invoice.target_company and IsBoss(bossPlayer) then
                    ShowNotification(bossPlayer.source, '✅ Facture #'..invoiceId..' annulée', 'info')
                end
            end
        end
    end

    -- Rafraîchir pour tous les employés du job
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:refreshStats', player.source)
    end

    -- Webhook
    SendWebhook('InvoiceCancelled', {
        invoiceId = invoiceId,
        job = job,
        total = tonumber(invoice.total),
        previousStatus = invoice.status,
        cancelledBy = xPlayer.getName()
    })
end)

-- Ajouter un produit (boss only)
RegisterNetEvent('tablet:addProduct', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    MySQL.insert('INSERT INTO tablet_products (job, product_name, price) VALUES (?, ?, ?)', {
        job, data.name, data.price
    })

    -- Notify tous les employés du job
    local products = GetJobProducts(job)
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:updateProducts', player.source, products)
    end

    -- Webhook
    SendWebhook('ProductAdded', {
        job = job,
        productName = data.name,
        price = tonumber(data.price),
        addedBy = xPlayer.getName()
    })

    ShowNotification(_source, Config.Translations['product_added'], 'info')
end)

-- Supprimer un produit (boss only)
RegisterNetEvent('tablet:deleteProduct', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    -- Récupérer les infos du produit avant suppression
    local product = MySQL.single.await('SELECT * FROM tablet_products WHERE id = ? AND job = ?', {data.id, job})

    MySQL.query('DELETE FROM tablet_products WHERE id = ? AND job = ?', {
        data.id, job
    })

    -- Notify tous les employés
    local products = GetJobProducts(job)
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:updateProducts', player.source, products)
    end

    -- Webhook
    if product then
        SendWebhook('ProductDeleted', {
            job = job,
            productName = product.product_name,
            price = tonumber(product.price),
            deletedBy = xPlayer.getName()
        })
    end

    ShowNotification(_source, Config.Translations['product_deleted'], 'info')
end)

-- Mettre à jour commission employé (boss only)
RegisterNetEvent('tablet:updateCommission', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    -- Récupérer l'ancienne commission
    local oldCommission = MySQL.scalar.await('SELECT commission_percent FROM tablet_employee_commissions WHERE job = ? AND identifier = ?', {job, data.identifier}) or Config.DefaultCommission

    MySQL.query([[
        INSERT INTO tablet_employee_commissions (job, identifier, commission_percent)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE commission_percent = ?
    ]], {
        job, data.identifier, data.commission, data.commission
    })

    -- Notifier l'employé concerné
    local targetPlayer = ESX.GetPlayerFromIdentifier(data.identifier)
    local employeeName = 'Employé'
    if targetPlayer then
        TriggerClientEvent('tablet:updateCommission', targetPlayer.source, data.commission)
        employeeName = targetPlayer.getName()
    end

    -- Webhook
    SendWebhook('CommissionUpdated', {
        job = job,
        employeeName = employeeName,
        oldCommission = tonumber(oldCommission),
        newCommission = tonumber(data.commission),
        modifiedBy = xPlayer.getName()
    })

    ShowNotification(_source, Config.Translations['commission_updated'], 'info')
end)

-- Réinitialiser commission employé (boss only)
RegisterNetEvent('tablet:resetCommission', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    -- Récupérer l'ancienne commission
    local oldCommission = MySQL.scalar.await('SELECT commission_percent FROM tablet_employee_commissions WHERE job = ? AND identifier = ?', {job, data.identifier}) or Config.DefaultCommission

    -- Supprimer l'entrée pour forcer le retour à la valeur par défaut
    MySQL.query('DELETE FROM tablet_employee_commissions WHERE job = ? AND identifier = ?', {job, data.identifier})

    -- Notifier l'employé concerné
    local targetPlayer = ESX.GetPlayerFromIdentifier(data.identifier)
    local employeeName = 'Employé'
    if targetPlayer then
        TriggerClientEvent('tablet:updateCommission', targetPlayer.source, Config.DefaultCommission)
        employeeName = targetPlayer.getName()
    end

    -- Webhook
    SendWebhook('CommissionReset', {
        job = job,
        employeeName = employeeName,
        oldCommission = tonumber(oldCommission),
        newCommission = Config.DefaultCommission,
        resetBy = xPlayer.getName()
    })

    ShowNotification(_source, '✅ Commission réinitialisée à '..Config.DefaultCommission..'%', 'success')

    -- Rafraîchir les données
    BroadcastUpdate(_source, job, 'employees')
end)

-- Ajouter un partenariat (boss only)
RegisterNetEvent('tablet:addPartnership', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    MySQL.insert('INSERT INTO tablet_partnerships (job, company_name, discount_percent) VALUES (?, ?, ?)', {
        job, data.name, data.discount
    })

    -- Notify tous les employés
    local partnerships = GetJobPartnerships(job)
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:updatePartnerships', player.source, partnerships)
    end

    -- Webhook
    SendWebhook('PartnershipAdded', {
        job = job,
        companyName = data.name,
        discount = tonumber(data.discount),
        addedBy = xPlayer.getName()
    })

    ShowNotification(_source, Config.Translations['partnership_added'], 'info')
end)

-- Supprimer un partenariat (boss only)
RegisterNetEvent('tablet:deletePartnership', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    -- Récupérer les infos du partenariat avant suppression
    local partnership = MySQL.single.await('SELECT * FROM tablet_partnerships WHERE id = ? AND job = ?', {data.id, job})

    MySQL.query('DELETE FROM tablet_partnerships WHERE id = ? AND job = ?', {
        data.id, job
    })

    -- Notify tous les employés
    local partnerships = GetJobPartnerships(job)
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:updatePartnerships', player.source, partnerships)
    end

    -- Webhook
    if partnership then
        SendWebhook('PartnershipDeleted', {
            job = job,
            companyName = partnership.company_name,
            deletedBy = xPlayer.getName()
        })
    end

    ShowNotification(_source, Config.Translations['partnership_deleted'], 'info')
end)

-- Commande admin pour réinitialiser les données d'un job (optionnel)
RegisterCommand('tablet:reset', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    -- Vérifier permissions admin si besoin
    if xPlayer.getGroup() ~= 'admin' then
        ShowNotification(source, '❌ Accès refusé', 'error')
        return
    end

    local job = args[1]
    if not job then
        ShowNotification(source, 'Usage: /tablet:reset <job>', 'info')
        return
    end

    MySQL.query('DELETE FROM tablet_products WHERE job = ?', {job})
    MySQL.query('DELETE FROM tablet_invoices WHERE job = ?', {job})
    MySQL.query('DELETE FROM tablet_employee_commissions WHERE job = ?', {job})
    MySQL.query('DELETE FROM tablet_partnerships WHERE job = ?', {job})
    MySQL.query('DELETE FROM tablet_company_payments WHERE from_job = ?', {job})

    ShowNotification(source, '✅ Données du job '..job..' réinitialisées', 'success')
end, true)

print('^2[TabletManager]^0 Serveur démarré avec succès')
