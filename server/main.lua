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

        table.insert(employeeStats, {
            identifier = identifier,
            name = name,
            commission_percent = commission,
            invoice_count = monthStats and monthStats.invoice_count or 0,
            total_ht = monthStats and tonumber(monthStats.total_ht) or 0,
            total_ttc = monthStats and tonumber(monthStats.total_ttc) or 0,
            total_commission = monthStats and tonumber(monthStats.total_commission) or 0
        })
    end

    cb(employeeStats)
end)

-- Réinitialiser les ventes (boss only)
RegisterNetEvent('tablet:resetSales', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or not IsBoss(xPlayer) then
        TriggerClientEvent('esx:showNotification', _source, '❌ Seuls les patrons peuvent réinitialiser les ventes')
        return
    end

    local job = xPlayer.job.name

    -- Compter le nombre de factures avant suppression
    local count = MySQL.scalar.await('SELECT COUNT(*) FROM tablet_invoices WHERE job = ?', {job}) or 0

    -- Supprimer toutes les factures du job
    MySQL.query('DELETE FROM tablet_invoices WHERE job = ?', {job})

    TriggerClientEvent('esx:showNotification', _source, '✅ Toutes les ventes ont été réinitialisées')

    -- Webhook
    SendWebhook('SalesReset', {
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
    MySQL.update('UPDATE tablet_invoices SET status = \'paid\', paid_at = NOW() WHERE id = ?', {invoiceId})

    -- Notifier l'employé qui a créé la facture s'il est connecté
    local employeePlayer = ESX.GetPlayerFromIdentifier(invoice.employee_identifier)
    if employeePlayer then
        TriggerClientEvent('esx:showNotification', employeePlayer.source, '💰 Facture #'..invoiceId..' payée par le client! Commission: '..tonumber(invoice.commission_amount)..'€')
        -- Rafraîchir les stats de l'employé dans sa tablette
        TriggerClientEvent('tablet:refreshStats', employeePlayer.source)
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
        TriggerClientEvent('esx:showNotification', _source, '❌ Seuls les patrons peuvent annuler des factures')
        return
    end

    local job = xPlayer.job.name

    -- Récupérer la facture pour vérifier qu'elle appartient à ce job
    local invoice = MySQL.single.await('SELECT * FROM tablet_invoices WHERE id = ? AND job = ?', {invoiceId, job})

    if not invoice then
        TriggerClientEvent('esx:showNotification', _source, '❌ Facture introuvable')
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
                        TriggerClientEvent('esx:showNotification', targetPlayer.source, '💰 Facture #'..invoiceId..' annulée - Remboursé: '..total..'€')
                    end
                elseif invoice.invoice_type == 'company' then
                    -- Rembourser l'entreprise
                    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_'..invoice.target_company, function(targetAccount)
                        if targetAccount then
                            targetAccount.addMoney(total)
                        end
                    end)
                end

                -- Mettre à jour le statut
                MySQL.update('UPDATE tablet_invoices SET status = \'cancelled\' WHERE id = ?', {invoiceId})
                TriggerClientEvent('esx:showNotification', _source, '✅ Facture #'..invoiceId..' annulée et remboursée')

                -- Notifier l'employé
                local employeePlayer = ESX.GetPlayerFromIdentifier(invoice.employee_identifier)
                if employeePlayer then
                    TriggerClientEvent('tablet:refreshStats', employeePlayer.source)
                end
            else
                TriggerClientEvent('esx:showNotification', _source, '❌ Votre société n\'a pas assez d\'argent pour rembourser')
            end
        end)
    else
        -- Si pending, juste annuler
        MySQL.update('UPDATE tablet_invoices SET status = \'cancelled\' WHERE id = ?', {invoiceId})
        TriggerClientEvent('esx:showNotification', _source, '✅ Facture #'..invoiceId..' annulée')
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

    TriggerClientEvent('esx:showNotification', _source, Config.Translations['product_added'])
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

    TriggerClientEvent('esx:showNotification', _source, Config.Translations['product_deleted'])
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

    -- Webhook
    SendWebhook('PartnershipAdded', {
        job = job,
        companyName = data.name,
        discount = tonumber(data.discount),
        addedBy = xPlayer.getName()
    })

    TriggerClientEvent('esx:showNotification', _source, Config.Translations['partnership_added'])
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
