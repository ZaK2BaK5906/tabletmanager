-- ============================================
-- SYSTÈME DE GESTION VÉHICULES (DEALERSHIP)
-- ============================================

-- Obtenir les infos d'un joueur (pour pré-remplir la facture)
ESX.RegisterServerCallback('dealership:getPlayerInfo', function(source, cb, targetId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if not xPlayer or xPlayer.job.name ~= 'dealership' then
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

-- Obtenir tous les véhicules avec leur stock (dealership only)
ESX.RegisterServerCallback('dealership:getVehicles', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= 'dealership' then
        cb(nil)
        return
    end

    local vehicles = MySQL.query.await([[
        SELECT name, model, price, category, stock
        FROM vehicles
        ORDER BY category, name
    ]], {})

    cb(vehicles or {})
end)

-- Commander des véhicules (débite l'entreprise)
RegisterNetEvent('dealership:orderVehicles')
AddEventHandler('dealership:orderVehicles', function(vehicleModel, quantity)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if not xPlayer or xPlayer.job.name ~= 'dealership' then
        ShowNotification(_source, '❌ Accès refusé', 'error')
        return
    end

    -- Récupérer les infos du véhicule
    local vehicle = MySQL.single.await('SELECT * FROM vehicles WHERE model = ?', {vehicleModel})

    if not vehicle then
        ShowNotification(_source, '❌ Véhicule introuvable', 'error')
        return
    end

    local totalCost = tonumber(vehicle.price) * quantity

    -- Vérifier l'argent de la société
    local societyAccount = 'society_dealership'
    TriggerEvent('esx_addonaccount:getSharedAccount', societyAccount, function(account)
        if not account then
            ShowNotification(_source, '❌ Compte entreprise introuvable', 'error')
            return
        end

        if tonumber(account.money) < totalCost then
            ShowNotification(_source, '❌ Fonds insuffisants (Coût: $' .. totalCost .. ')', 'error')
            return
        end

        -- Débiter l'entreprise
        account.removeMoney(totalCost)

        -- Ajouter au stock
        MySQL.query('UPDATE vehicles SET stock = stock + ? WHERE model = ?', {quantity, vehicleModel})

        -- Enregistrer la commande dans l'historique
        MySQL.insert.await([[
            INSERT INTO vehicle_orders (job, vehicle_model, vehicle_name, quantity, unit_price, total_cost, ordered_by)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ]], {
            'dealership',
            vehicleModel,
            vehicle.name,
            quantity,
            tonumber(vehicle.price),
            totalCost,
            xPlayer.getName()
        })

        ShowNotification(_source, '✅ Commande effectuée: ' .. quantity .. 'x ' .. vehicle.name .. ' ($' .. totalCost .. ')', 'success')

        -- Webhook
        SendWebhook('VehicleOrder', {
            job = 'dealership',
            orderedBy = xPlayer.getName(),
            vehicleName = vehicle.name,
            quantity = quantity,
            unitPrice = tonumber(vehicle.price),
            totalCost = totalCost
        })

        -- Rafraîchir la liste pour le joueur
        TriggerClientEvent('dealership:refreshVehicles', _source)

        -- Rafraîchir l'historique pour tous les employés dealership
        local xPlayers = ESX.GetExtendedPlayers('job', 'dealership')
        for _, player in pairs(xPlayers) do
            TriggerClientEvent('tablet:refreshHistory', player.source)
        end
    end)
end)

-- Obtenir le stock de véhicules pour assignment
ESX.RegisterServerCallback('dealership:getVehicleStock', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= 'dealership' then
        cb(nil)
        return
    end

    local vehicles = MySQL.query.await([[
        SELECT name, model, price, stock
        FROM vehicles
        WHERE stock > 0
        ORDER BY name
    ]], {})

    cb(vehicles or {})
end)

-- Assigner un véhicule à un joueur (réduit le stock, donne le véhicule)
RegisterNetEvent('dealership:assignVehicle')
AddEventHandler('dealership:assignVehicle', function(targetId, vehicleModel, plate)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if not xPlayer or xPlayer.job.name ~= 'dealership' then
        ShowNotification(_source, '❌ Accès refusé', 'error')
        return
    end

    if not targetPlayer then
        ShowNotification(_source, '❌ Joueur introuvable', 'error')
        return
    end

    -- Vérifier le stock
    local vehicle = MySQL.single.await('SELECT * FROM vehicles WHERE model = ?', {vehicleModel})

    if not vehicle or tonumber(vehicle.stock) <= 0 then
        ShowNotification(_source, '❌ Véhicule en rupture de stock', 'error')
        return
    end

    -- Générer une plaque si non fournie ou vide
    if not plate or plate == '' or plate == 'nil' then
        plate = 'DLR' .. math.random(1000, 9999)
    end

    -- Réduire le stock
    MySQL.query('UPDATE vehicles SET stock = stock - 1 WHERE model = ?', {vehicleModel})

    -- Donner le véhicule au joueur (via owned_vehicles)
    MySQL.insert.await([[
        INSERT INTO owned_vehicles (owner, plate, vehicle, type, job, stored)
        VALUES (?, ?, ?, 'car', NULL, 1)
    ]], {
        targetPlayer.identifier,
        plate,
        json.encode({model = GetHashKey(vehicleModel), plate = plate})
    })

    ShowNotification(_source, '✅ Véhicule ' .. vehicle.name .. ' assigné à ' .. targetPlayer.getName(), 'success')
    ShowNotification(targetPlayer.source, '🎉 Vous avez reçu un véhicule: ' .. vehicle.name .. ' (Plaque: ' .. plate .. ')', 'success')

    -- Webhook
    SendWebhook('VehicleAssigned', {
        job = 'dealership',
        seller = xPlayer.getName(),
        buyer = targetPlayer.getName(),
        vehicleName = vehicle.name,
        plate = plate
    })
end)

print('^2[Dealership]^0 Système véhicules chargé')
