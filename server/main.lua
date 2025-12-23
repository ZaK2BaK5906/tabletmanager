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
    local targetIdentifier = nil
    local targetCompany = nil

    -- Vérifier la cible selon le type
    if invoiceType == 'citizen' then
        -- Facturation citoyen
        local targetId = invoiceData.targetId
        local targetPlayer = ESX.GetPlayerFromId(targetId)

        if not targetPlayer then
            TriggerClientEvent('esx:showNotification', _source, '❌ Joueur introuvable (ID: '..targetId..')')
            return
        end

        targetIdentifier = targetPlayer.identifier
    else
        -- Facturation entreprise
        targetCompany = invoiceData.targetCompany

        if not targetCompany then
            TriggerClientEvent('esx:showNotification', _source, '❌ Entreprise invalide')
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
    TriggerClientEvent('esx:showNotification', _source, '✅ Facture #'..invoiceId..' créée: '..total..'€ (En attente de paiement)')

    -- Notification à la cible
    if invoiceType == 'citizen' then
        local targetPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
        if targetPlayer then
            local jobLabel = ESX.GetJobs()[job] and ESX.GetJobs()[job].label or job
            TriggerClientEvent('esx:showNotification', targetPlayer.source, '📄 Nouvelle facture reçue: '..total..'€ de '..jobLabel..' • Tapez /facture')
        end
    end

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
        TriggerClientEvent('esx:showNotification', _source, '❌ Facture introuvable ou déjà payée')
        return
    end

    local total = tonumber(invoice.total)

    -- Si facture citoyen
    if invoice.invoice_type == 'citizen' then
        -- Vérifier que c'est bien pour ce joueur
        if invoice.target_identifier ~= xPlayer.identifier then
            TriggerClientEvent('esx:showNotification', _source, '❌ Cette facture ne vous est pas destinée')
            return
        end

        -- Vérifier l'argent du joueur
        local money = tonumber(xPlayer.getAccount('bank').money) or 0
        if money < total then
            TriggerClientEvent('esx:showNotification', _source, '❌ Vous n\'avez pas assez d\'argent en banque')
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
        TriggerClientEvent('esx:showNotification', _source, '✅ Facture #'..invoiceId..' payée: '..total..'€')

    -- Si facture entreprise
    elseif invoice.invoice_type == 'company' then
        -- Vérifier que le joueur est boss de l'entreprise cible
        if xPlayer.job.name ~= invoice.target_company or not IsBoss(xPlayer) then
            TriggerClientEvent('esx:showNotification', _source, '❌ Vous devez être patron de '..invoice.target_company..' pour payer cette facture')
            return
        end

        -- Vérifier l'argent de la société
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..invoice.target_company, function(payerAccount)
            if not payerAccount then
                TriggerClientEvent('esx:showNotification', _source, '❌ Compte entreprise introuvable')
                return
            end

            if tonumber(payerAccount.money) < total then
                TriggerClientEvent('esx:showNotification', _source, '❌ Votre entreprise n\'a pas assez d\'argent')
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
            MySQL.update('UPDATE tablet_invoices SET status = \'paid\', paid_at = NOW() WHERE id = ?', {invoiceId})

            -- Notifications
            TriggerClientEvent('esx:showNotification', _source, '✅ Facture #'..invoiceId..' payée par votre entreprise: '..total..'€')

            -- Notifier l'employé créateur
            local employeePlayer = ESX.GetPlayerFromIdentifier(invoice.employee_identifier)
            if employeePlayer then
                TriggerClientEvent('esx:showNotification', employeePlayer.source, '💰 Facture #'..invoiceId..' payée par '..invoice.target_company..'! Commission: '..tonumber(invoice.commission_amount)..'€')
                -- Rafraîchir les stats de l'employé dans sa tablette
                TriggerClientEvent('tablet:refreshStats', employeePlayer.source)
            end

            -- Refresh
            TriggerClientEvent('tablet:refreshInvoices', _source)
        end)

        return -- Important: sortir ici car traitement async
    end

    -- Mettre à jour le statut de la facture (citoyen uniquement, company géré dans le callback)
    MySQL.update('UPDATE tablet_invoices SET status = \'paid\', paid_at = NOW() WHERE id = ?', {invoiceId})

    -- Notifier l'employé qui a créé la facture s'il est connecté
    local employeePlayer = ESX.GetPlayerFromIdentifier(invoice.employee_identifier)
    if employeePlayer then
        TriggerClientEvent('esx:showNotification', employeePlayer.source, '💰 Facture #'..invoiceId..' payée par le client! Commission: '..tonumber(invoice.commission_amount)..'€')
        -- Rafraîchir les stats de l'employé dans sa tablette
        TriggerClientEvent('tablet:refreshStats', employeePlayer.source)
    end

    -- Refresh la liste
    TriggerClientEvent('tablet:refreshInvoices', _source)
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
