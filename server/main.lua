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

    -- Total commission du mois
    local commission = MySQL.scalar.await([[
        SELECT IFNULL(SUM(commission_amount), 0)
        FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
        AND MONTH(created_at) = MONTH(CURRENT_DATE())
        AND YEAR(created_at) = YEAR(CURRENT_DATE())
    ]], {job, identifier}) or 0

    -- Nombre de factures du mois
    local invoiceCount = MySQL.scalar.await([[
        SELECT COUNT(*)
        FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
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

    -- CA du mois (total des factures)
    local revenue = MySQL.scalar.await([[
        SELECT IFNULL(SUM(total), 0)
        FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
        AND MONTH(created_at) = MONTH(CURRENT_DATE())
        AND YEAR(created_at) = YEAR(CURRENT_DATE())
    ]], {job, identifier}) or 0

    -- Nombre de factures du mois
    local invoiceCount = MySQL.scalar.await([[
        SELECT COUNT(*)
        FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
        AND MONTH(created_at) = MONTH(CURRENT_DATE())
        AND YEAR(created_at) = YEAR(CURRENT_DATE())
    ]], {job, identifier}) or 0

    -- Commission totale du mois
    local commission = MySQL.scalar.await([[
        SELECT IFNULL(SUM(commission_amount), 0)
        FROM tablet_invoices
        WHERE job = ? AND employee_identifier = ?
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

    -- Commission
    local commissionPercent = GetEmployeeCommission(job, identifier)
    local commissionAmount = total * (commissionPercent / 100)

    -- Type de facture (citizen ou company)
    local invoiceType = invoiceData.type or 'citizen'
    local targetInfo = ''

    -- Traiter le paiement selon le type
    if invoiceType == 'citizen' then
        -- Facturation citoyen
        local targetId = invoiceData.targetId
        local targetPlayer = ESX.GetPlayerFromId(targetId)

        if not targetPlayer then
            TriggerClientEvent('esx:showNotification', _source, '❌ Joueur introuvable (ID: '..targetId..')')
            return
        end

        local targetMoney = targetPlayer.getAccount('bank').money

        if targetMoney < total then
            TriggerClientEvent('esx:showNotification', _source, '❌ Le client n\'a pas assez d\'argent en banque')
            return
        end

        -- Débiter le client
        targetPlayer.removeAccountMoney('bank', total)

        -- Créditer le compte société du job
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
            if account then
                account.addMoney(total)
            end
        end)

        targetInfo = targetPlayer.getName()..' (ID: '..targetId..')'

        -- Notif au client
        TriggerClientEvent('esx:showNotification', targetId, '💸 Facture payée: '..total..'€ pour '..ESX.GetJobLabel(job))
    else
        -- Facturation entreprise
        local targetCompany = invoiceData.targetCompany

        -- Débiter le compte société de l'entreprise cible
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..targetCompany, function(targetAccount)
            if not targetAccount then
                TriggerClientEvent('esx:showNotification', _source, '❌ Compte entreprise introuvable')
                return
            end

            if targetAccount.money < total then
                TriggerClientEvent('esx:showNotification', _source, '❌ L\'entreprise n\'a pas assez d\'argent')
                return
            end

            -- Débiter l'entreprise cible
            targetAccount.removeMoney(total)

            -- Créditer le compte société du job créateur
            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..job, function(account)
                if account then
                    account.addMoney(total)
                end
            end)

            -- Enregistrer le paiement
            MySQL.insert('INSERT INTO tablet_company_payments (from_job, to_company, amount, invoice_id) VALUES (?, ?, ?, ?)', {
                targetCompany, job, total, 0
            })
        end)

        targetInfo = ESX.GetJobLabel(targetCompany) or targetCompany
    end

    -- Insérer en BDD
    local invoiceId = MySQL.insert.await([[
        INSERT INTO tablet_invoices
        (job, employee_identifier, employee_name, items, subtotal, discount_percent, partnership_discount, partnership_name, tax_percent, total, commission_percent, commission_amount)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
        job,
        identifier,
        playerName,
        json.encode(invoiceData.items),
        subtotal,
        manualDiscount,
        partnershipDiscount,
        targetInfo,
        Config.TaxRate,
        total,
        commissionPercent,
        commissionAmount
    })

    -- Notification
    TriggerClientEvent('esx:showNotification', _source, '✅ Facture créée: '..total..'€ • Commission: '..commissionAmount..'€')

    -- Reload data
    TriggerClientEvent('tablet:invoiceCreated', _source)
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

    TriggerClientEvent('esx:showNotification', _source, Config.Translations['product_added'])
end)

-- Supprimer un produit (boss only)
RegisterNetEvent('tablet:deleteProduct', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    MySQL.query('DELETE FROM tablet_products WHERE id = ? AND job = ?', {
        data.id, job
    })

    -- Notify tous les employés
    local products = GetJobProducts(job)
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:updateProducts', player.source, products)
    end

    TriggerClientEvent('esx:showNotification', _source, Config.Translations['product_deleted'])
end)

-- Mettre à jour commission employé (boss only)
RegisterNetEvent('tablet:updateCommission', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    MySQL.query([[
        INSERT INTO tablet_employee_commissions (job, identifier, commission_percent)
        VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE commission_percent = ?
    ]], {
        job, data.identifier, data.commission, data.commission
    })

    -- Notifier l'employé concerné
    local targetPlayer = ESX.GetPlayerFromIdentifier(data.identifier)
    if targetPlayer then
        TriggerClientEvent('tablet:updateCommission', targetPlayer.source, data.commission)
    end

    TriggerClientEvent('esx:showNotification', _source, Config.Translations['commission_updated'])
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

    TriggerClientEvent('esx:showNotification', _source, Config.Translations['partnership_added'])
end)

-- Supprimer un partenariat (boss only)
RegisterNetEvent('tablet:deletePartnership', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then return end

    local job = xPlayer.job.name

    MySQL.query('DELETE FROM tablet_partnerships WHERE id = ? AND job = ?', {
        data.id, job
    })

    -- Notify tous les employés
    local partnerships = GetJobPartnerships(job)
    local xPlayers = ESX.GetExtendedPlayers('job', job)
    for _, player in pairs(xPlayers) do
        TriggerClientEvent('tablet:updatePartnerships', player.source, partnerships)
    end

    TriggerClientEvent('esx:showNotification', _source, Config.Translations['partnership_deleted'])
end)

-- Commande admin pour réinitialiser les données d'un job (optionnel)
RegisterCommand('tablet:reset', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    -- Vérifier permissions admin si besoin
    if xPlayer.getGroup() ~= 'admin' then
        TriggerClientEvent('esx:showNotification', source, '❌ Accès refusé')
        return
    end

    local job = args[1]
    if not job then
        TriggerClientEvent('esx:showNotification', source, 'Usage: /tablet:reset <job>')
        return
    end

    MySQL.query('DELETE FROM tablet_products WHERE job = ?', {job})
    MySQL.query('DELETE FROM tablet_invoices WHERE job = ?', {job})
    MySQL.query('DELETE FROM tablet_employee_commissions WHERE job = ?', {job})
    MySQL.query('DELETE FROM tablet_partnerships WHERE job = ?', {job})
    MySQL.query('DELETE FROM tablet_company_payments WHERE from_job = ?', {job})

    TriggerClientEvent('esx:showNotification', source, '✅ Données du job '..job..' réinitialisées')
end, true)

print('^2[TabletManager]^0 Serveur démarré avec succès')
