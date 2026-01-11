local ESX = exports['es_extended']:getSharedObject()

-- Configuration
Config = {}
Config.DOJJobs = { 'doj', 'judge', 'justice' }
Config.DefaultTaxRate = 15
Config.DealerDiscount = 0.40 -- 40% discount
Config.UnemployedJobs = { 'unemployed', 'chomeur' } -- Jobs that cannot access tablet

-- Global Tax Rate (stored in database)
local globalTaxRate = Config.DefaultTaxRate

-- Initialize Database
MySQL.ready(function()
    -- Create tables if they don't exist
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_invoices (
            id INT AUTO_INCREMENT PRIMARY KEY,
            number VARCHAR(50) UNIQUE,
            company_job VARCHAR(50),
            company_name VARCHAR(100),
            client_id VARCHAR(50),
            client_name VARCHAR(100),
            amount DECIMAL(10,2),
            tax DECIMAL(10,2),
            total DECIMAL(10,2),
            description TEXT,
            with_tax TINYINT(1) DEFAULT 1,
            no_tax_reason VARCHAR(255),
            status VARCHAR(20) DEFAULT 'pending',
            created_by VARCHAR(100),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            paid_at TIMESTAMP NULL,
            INDEX idx_client (client_id),
            INDEX idx_company (company_job),
            INDEX idx_status (status)
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_tax_settings (
            id INT PRIMARY KEY DEFAULT 1,
            global_rate DECIMAL(5,2) DEFAULT 15.00,
            payment_deadline_day INT DEFAULT 25,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_commissions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            employee_id VARCHAR(50),
            employee_name VARCHAR(100),
            amount DECIMAL(10,2),
            invoice_id INT,
            status VARCHAR(20) DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            paid_at TIMESTAMP NULL
        )
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS mdt_partnerships (
            id INT AUTO_INCREMENT PRIMARY KEY,
            company_job VARCHAR(50),
            company_name VARCHAR(100),
            partner_job VARCHAR(50),
            partner_name VARCHAR(100),
            status VARCHAR(20) DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY unique_partnership (company_job, partner_job)
        )
    ]])

    -- Load global tax rate
    MySQL.scalar('SELECT global_rate FROM mdt_tax_settings WHERE id = 1', {}, function(rate)
        if rate then
            globalTaxRate = rate
        else
            -- Insert default tax rate
            MySQL.insert('INSERT INTO mdt_tax_settings (id, global_rate) VALUES (1, ?)', {
                Config.DefaultTaxRate
            })
        end
    end)
end)

-- Helper Functions
function IsAuthorized(xPlayer)
    -- Everyone with a job can access (except unemployed)
    for _, job in pairs(Config.UnemployedJobs) do
        if xPlayer.job.name == job then
            return false
        end
    end
    return true
end

function IsDOJ(xPlayer)
    for _, job in pairs(Config.DOJJobs) do
        if xPlayer.job.name == job then
            return true
        end
    end
    return false
end

function GenerateInvoiceNumber()
    local date = os.date('%Y%m%d')
    local random = math.random(1000, 9999)
    return string.format('INV-%s-%s', date, random)
end

-- Get Player Data Callback
ESX.RegisterServerCallback('mdt_premium:getPlayerData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(nil)
        return
    end

    if not IsAuthorized(xPlayer) then
        cb(nil)
        return
    end

    -- Get company account
    local companyAccount = nil
    if xPlayer.job.name then
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. xPlayer.job.name, function(account)
            companyAccount = account
        end)
    end

    Wait(100) -- Wait for account to load

    -- Get employee stats
    MySQL.query('SELECT COUNT(*) as count, SUM(total) as total FROM mdt_invoices WHERE created_by = ?', {
        xPlayer.getName()
    }, function(result)
        local stats = result[1] or { count = 0, total = 0 }

        -- Get invoices
        MySQL.query('SELECT * FROM mdt_invoices ORDER BY created_at DESC LIMIT 50', {}, function(invoices)
            -- Get vehicles for dealership
            MySQL.query('SELECT * FROM vehicles WHERE category = "super" OR category = "sports"', {}, function(vehicles)
                local vehicleList = {}
                for _, vehicle in pairs(vehicles) do
                    local dealerPrice = math.floor(vehicle.price * (1 - Config.DealerDiscount))
                    table.insert(vehicleList, {
                        id = vehicle.name,
                        model = vehicle.model,
                        name = vehicle.name,
                        category = vehicle.category,
                        price = vehicle.price,
                        dealerPrice = dealerPrice,
                        stock = math.random(0, 5) -- Mock stock for demo
                    })
                end

                -- Format data for NUI
                cb({
                    user = {
                        id = source,
                        name = xPlayer.getName(),
                        job = xPlayer.job.label,
                        grade = xPlayer.job.grade_label,
                        company = xPlayer.job.label,
                        balance = xPlayer.getAccount('bank').money,
                        canAccessDOJ = IsDOJ(xPlayer)
                    },
                    company = {
                        name = xPlayer.job.label,
                        balance = companyAccount and companyAccount.money or 0,
                        taxRate = globalTaxRate
                    },
                    invoices = invoices,
                    vehicles = vehicleList,
                    stats = {
                        invoiceCount = stats.count,
                        totalInvoiced = stats.total
                    }
                })
            end)
        end)
    end)
end)

-- Get Player Info Callback
ESX.RegisterServerCallback('mdt_premium:getPlayerInfo', function(source, cb, targetId)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if xTarget then
        cb({
            id = targetId,
            name = xTarget.getName(),
            identifier = xTarget.identifier
        })
    else
        cb(nil)
    end
end)

-- Create Invoice Callback
ESX.RegisterServerCallback('mdt_premium:createInvoice', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsAuthorized(xPlayer) then
        cb(false, 'Non autorisé')
        return
    end

    local targetId = tonumber(data.targetId)
    local amount = tonumber(data.amount)
    local description = data.description or ''

    if not targetId or not amount or amount <= 0 then
        cb(false, 'Données invalides')
        return
    end

    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget then
        cb(false, 'Joueur introuvable')
        return
    end

    -- Calculate tax
    local tax = math.floor(amount * (globalTaxRate / 100))
    local total = amount + tax

    -- Generate invoice number
    local invoiceNumber = GenerateInvoiceNumber()

    -- Insert invoice
    MySQL.insert('INSERT INTO mdt_invoices (number, company_job, company_name, client_id, client_name, amount, tax, total, description, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        invoiceNumber,
        xPlayer.job.name,
        xPlayer.job.label,
        xTarget.identifier,
        xTarget.getName(),
        amount,
        tax,
        total,
        description,
        xPlayer.getName()
    }, function(insertId)
        if insertId then
            -- Calculate commission (5% of amount)
            local commission = math.floor(amount * 0.05)
            MySQL.insert('INSERT INTO mdt_commissions (employee_id, employee_name, amount, invoice_id) VALUES (?, ?, ?, ?)', {
                xPlayer.identifier,
                xPlayer.getName(),
                commission,
                insertId
            })

            -- Notify target player they received an invoice
            TriggerClientEvent('mdt_premium:receiveInvoice', xTarget.source, {
                id = insertId,
                number = invoiceNumber,
                company = xPlayer.job.label,
                amount = amount,
                tax = tax,
                total = total,
                description = description
            })

            cb(true)
        else
            cb(false, 'Erreur base de données')
        end
    end)
end)

-- Purchase Vehicle Callback
ESX.RegisterServerCallback('mdt_premium:purchaseVehicle', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsAuthorized(xPlayer) then
        cb(false, 'Non autorisé')
        return
    end

    local vehicleModel = data.model
    local dealerPrice = tonumber(data.dealerPrice)

    if not vehicleModel or not dealerPrice then
        cb(false, 'Données invalides')
        return
    end

    -- Get company account
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. xPlayer.job.name, function(account)
        if account and account.money >= dealerPrice then
            account.removeMoney(dealerPrice)

            -- Add vehicle to company garage (cette partie dépend de votre script de garage)
            -- TriggerEvent('esx_vehicleshop:setVehicleOwned', xPlayer.identifier, vehicleModel, true)

            cb(true)
        else
            cb(false, 'Fonds insuffisants')
        end
    end)
end)

-- Pay Commission Callback
ESX.RegisterServerCallback('mdt_premium:payCommission', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsAuthorized(xPlayer) then
        cb(false, 'Non autorisé')
        return
    end

    local employeeId = data.employeeId
    local amount = tonumber(data.amount)

    if not employeeId or not amount then
        cb(false, 'Données invalides')
        return
    end

    -- Get company account
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. xPlayer.job.name, function(account)
        if account and account.money >= amount then
            account.removeMoney(amount)

            -- Give money to employee
            local xTarget = ESX.GetPlayerFromIdentifier(employeeId)
            if xTarget then
                xTarget.addAccountMoney('bank', amount)
            end

            -- Update commission status
            MySQL.update('UPDATE mdt_commissions SET status = "paid", paid_at = NOW() WHERE employee_id = ? AND status = "pending"', {
                employeeId
            })

            cb(true)
        else
            cb(false, 'Fonds insuffisants')
        end
    end)
end)

-- Pay Taxes Callback
ESX.RegisterServerCallback('mdt_premium:payTaxes', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsAuthorized(xPlayer) then
        cb(false, 'Non autorisé')
        return
    end

    local amount = tonumber(data.amount)

    if not amount or amount <= 0 then
        cb(false, 'Montant invalide')
        return
    end

    -- Get company account
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. xPlayer.job.name, function(account)
        if account and account.money >= amount then
            account.removeMoney(amount)

            -- Give to DOJ account
            TriggerEvent('esx_addonaccount:getSharedAccount', 'society_doj', function(dojAccount)
                if dojAccount then
                    dojAccount.addMoney(amount)
                end
            end)

            cb(true)
        else
            cb(false, 'Fonds insuffisants')
        end
    end)
end)

-- Update Tax Rate Callback (DOJ Only)
ESX.RegisterServerCallback('mdt_premium:updateTaxRate', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsDOJ(xPlayer) then
        cb(false, 'Accès refusé - Réservé au DOJ')
        return
    end

    local newRate = tonumber(data.taxRate)

    if not newRate or newRate < 0 or newRate > 100 then
        cb(false, 'Taux invalide')
        return
    end

    MySQL.update('UPDATE mdt_tax_settings SET global_rate = ? WHERE id = 1', {
        newRate
    }, function(affectedRows)
        if affectedRows > 0 then
            globalTaxRate = newRate
            cb(true)
        else
            cb(false, 'Erreur base de données')
        end
    end)
end)

-- Get All Companies (Jobs) Callback
ESX.RegisterServerCallback('mdt_premium:getAllCompanies', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsAuthorized(xPlayer) then
        cb(nil)
        return
    end

    -- Get all jobs from database (excluding unemployed)
    MySQL.query('SELECT name, label FROM jobs WHERE name NOT IN (?, ?)', {
        'unemployed', 'chomeur'
    }, function(jobs)
        local companies = {}
        for _, job in pairs(jobs) do
            table.insert(companies, {
                job = job.name,
                name = job.label
            })
        end
        cb(companies)
    end)
end)

-- Get Partnerships Callback
ESX.RegisterServerCallback('mdt_premium:getPartnerships', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsAuthorized(xPlayer) then
        cb(nil)
        return
    end

    MySQL.query('SELECT * FROM mdt_partnerships WHERE company_job = ? OR partner_job = ?', {
        xPlayer.job.name,
        xPlayer.job.name
    }, function(partnerships)
        cb(partnerships)
    end)
end)

-- Create Partnership Callback
ESX.RegisterServerCallback('mdt_premium:createPartnership', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsAuthorized(xPlayer) then
        cb(false, 'Non autorisé')
        return
    end

    local partnerJob = data.partnerJob
    local partnerName = data.partnerName

    if not partnerJob or not partnerName then
        cb(false, 'Données invalides')
        return
    end

    -- Cannot partner with yourself
    if partnerJob == xPlayer.job.name then
        cb(false, 'Vous ne pouvez pas faire un partenariat avec votre propre entreprise')
        return
    end

    -- Check if partnership already exists
    MySQL.scalar('SELECT id FROM mdt_partnerships WHERE (company_job = ? AND partner_job = ?) OR (company_job = ? AND partner_job = ?)', {
        xPlayer.job.name, partnerJob, partnerJob, xPlayer.job.name
    }, function(exists)
        if exists then
            cb(false, 'Partenariat déjà existant')
            return
        end

        -- Create partnership
        MySQL.insert('INSERT INTO mdt_partnerships (company_job, company_name, partner_job, partner_name) VALUES (?, ?, ?, ?)', {
            xPlayer.job.name,
            xPlayer.job.label,
            partnerJob,
            partnerName
        }, function(insertId)
            if insertId then
                cb(true)
            else
                cb(false, 'Erreur base de données')
            end
        end)
    end)
end)

-- Get Player Invoices Callback
ESX.RegisterServerCallback('mdt_premium:getPlayerInvoices', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(nil)
        return
    end

    MySQL.query('SELECT * FROM mdt_invoices WHERE client_id = ? ORDER BY created_at DESC', {
        xPlayer.identifier
    }, function(invoices)
        cb(invoices)
    end)
end)

-- Pay Invoice Callback
ESX.RegisterServerCallback('mdt_premium:payInvoice', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false, 'Joueur introuvable')
        return
    end

    local invoiceId = tonumber(data.invoiceId)

    if not invoiceId then
        cb(false, 'ID de facture invalide')
        return
    end

    -- Get invoice details
    MySQL.single('SELECT * FROM mdt_invoices WHERE id = ? AND client_id = ? AND status = "pending"', {
        invoiceId,
        xPlayer.identifier
    }, function(invoice)
        if not invoice then
            cb(false, 'Facture introuvable ou déjà payée')
            return
        end

        -- Check if player has enough money (bank account)
        local bankBalance = xPlayer.getAccount('bank').money

        if bankBalance < invoice.total then
            cb(false, 'Fonds insuffisants')
            return
        end

        -- Remove money from player (ox_banking)
        local success = exports.ox_banking:RemoveBankBalance(xPlayer.source, {
            amount = invoice.total,
            message = 'Paiement facture ' .. invoice.number
        })

        if not success then
            cb(false, 'Erreur lors du paiement')
            return
        end

        -- Add money to company (ox_banking)
        local companyAccount = 'society_' .. invoice.company_job
        exports.ox_banking:AddBankBalance(companyAccount, {
            amount = invoice.total,
            message = 'Paiement facture ' .. invoice.number .. ' par ' .. xPlayer.getName()
        })

        -- Update invoice status
        MySQL.update('UPDATE mdt_invoices SET status = "paid", paid_at = NOW() WHERE id = ?', {
            invoiceId
        }, function(affectedRows)
            if affectedRows > 0 then
                -- Notify company (if online)
                MySQL.scalar('SELECT created_by FROM mdt_invoices WHERE id = ?', {
                    invoiceId
                }, function(createdBy)
                    -- Could notify the employee who created the invoice
                    cb(true)
                end)
            else
                cb(false, 'Erreur lors de la mise à jour')
            end
        end)
    end)
end)

-- Delete Partnership Callback
ESX.RegisterServerCallback('mdt_premium:deletePartnership', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not IsAuthorized(xPlayer) then
        cb(false, 'Non autorisé')
        return
    end

    local partnershipId = tonumber(data.partnershipId)

    if not partnershipId then
        cb(false, 'ID invalide')
        return
    end

    -- Check if partnership belongs to this company
    MySQL.update('DELETE FROM mdt_partnerships WHERE id = ? AND (company_job = ? OR partner_job = ?)', {
        partnershipId,
        xPlayer.job.name,
        xPlayer.job.name
    }, function(affectedRows)
        if affectedRows > 0 then
            cb(true)
        else
            cb(false, 'Partenariat introuvable')
        end
    end)
end)

print('^2[MDT Premium] ^7Resource started successfully^0')
