-- ============================================
-- B_ADMIN2 - ECONOMY ACTIONS (HIGH RISK)
-- ============================================

--- Give Money
RegisterNetEvent('badmin:giveMoney', function(targetId, account, amount, confirmed)
    local source = source
    if not HasPermission(source, 'admin.economy.give_money') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    -- Check panic mode
    local panicMode = MySQL.scalar.await('SELECT `value` FROM `z_admin_config` WHERE `key` = "panic_mode"', {})
    if panicMode == 'true' then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PanicModeActive)
        return
    end

    -- Double confirm
    if Config.Economy.RequireDoubleConfirm and not confirmed then
        TriggerClientEvent('badmin:notify', source, Config.Messages.DoubleConfirmRequired)
        return
    end

    local canProceed, err = CheckRateLimit(source, 'give_money')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('badmin:notify', source, '❌ Montant invalide')
        return
    end

    if amount > Config.Economy.MaxGiveMoney then
        TriggerClientEvent('badmin:notify', source, string.format('❌ Montant maximum: %d', Config.Economy.MaxGiveMoney))
        return
    end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then return end

    if account == 'cash' then
        xTarget.addMoney(amount)
    elseif account == 'bank' then
        xTarget.addAccountMoney('bank', amount)
    elseif account == 'black' then
        xTarget.addAccountMoney('black_money', amount)
    else
        TriggerClientEvent('badmin:notify', source, '❌ Compte invalide')
        return
    end

    TriggerClientEvent('badmin:notify', source, string.format('✅ %d$ ajouté (%s)', amount, account))
    TriggerClientEvent('badmin:notify', target, string.format('💰 Vous avez reçu %d$ (%s)', amount, account))

    LogStaffAction(source, target, 'give_money', 'economy', { account = account, amount = amount }, true)
end)

--- Remove Money
RegisterNetEvent('badmin:removeMoney', function(targetId, account, amount, confirmed)
    local source = source
    if not HasPermission(source, 'admin.economy.remove_money') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    if Config.Economy.RequireDoubleConfirm and not confirmed then
        TriggerClientEvent('badmin:notify', source, Config.Messages.DoubleConfirmRequired)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    amount = tonumber(amount)
    if not amount or amount <= 0 then
        TriggerClientEvent('badmin:notify', source, '❌ Montant invalide')
        return
    end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then return end

    if account == 'cash' then
        xTarget.removeMoney(amount)
    elseif account == 'bank' then
        xTarget.removeAccountMoney('bank', amount)
    elseif account == 'black' then
        xTarget.removeAccountMoney('black_money', amount)
    else
        TriggerClientEvent('badmin:notify', source, '❌ Compte invalide')
        return
    end

    TriggerClientEvent('badmin:notify', source, string.format('✅ %d$ retiré (%s)', amount, account))

    LogStaffAction(source, target, 'remove_money', 'economy', { account = account, amount = amount }, true)
end)

--- Give Item
RegisterNetEvent('badmin:giveItem', function(targetId, itemName, quantity)
    local source = source
    if not HasPermission(source, 'admin.economy.give_item') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local panicMode = MySQL.scalar.await('SELECT `value` FROM `z_admin_config` WHERE `key` = "panic_mode"', {})
    if panicMode == 'true' then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PanicModeActive)
        return
    end

    local canProceed, err = CheckRateLimit(source, 'give_item')
    if not canProceed then
        TriggerClientEvent('badmin:notify', source, err)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    quantity = tonumber(quantity) or 1
    if quantity > Config.Economy.MaxItemQuantity then
        TriggerClientEvent('badmin:notify', source, string.format('❌ Quantité max: %d', Config.Economy.MaxItemQuantity))
        return
    end

    -- Check whitelist (si pas owner)
    local perms = GetPlayerPermissions(source)
    if perms.rank ~= 'owner' then
        local allowed = false
        for _, item in ipairs(Config.Economy.AllowedItems) do
            if item == itemName then
                allowed = true
                break
            end
        end
        if not allowed then
            TriggerClientEvent('badmin:notify', source, '❌ Item non autorisé')
            LogStaffAction(source, target, 'give_item', 'economy', { item = itemName, quantity = quantity }, false, 'Item non autorisé')
            return
        end
    end

    local success = exports.ox_inventory:AddItem(target, itemName, quantity)
    if success then
        TriggerClientEvent('badmin:notify', source, string.format('✅ Item donné: %s x%d', itemName, quantity))
        LogStaffAction(source, target, 'give_item', 'economy', { item = itemName, quantity = quantity }, true)
    else
        TriggerClientEvent('badmin:notify', source, '❌ Échec (inventaire plein ?)')
        LogStaffAction(source, target, 'give_item', 'economy', { item = itemName, quantity = quantity }, false, 'Inventaire plein')
    end
end)

--- Give Weapon
RegisterNetEvent('badmin:giveWeapon', function(targetId, weaponName, ammo)
    local source = source
    if not HasPermission(source, 'admin.economy.give_weapon') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local panicMode = MySQL.scalar.await('SELECT `value` FROM `z_admin_config` WHERE `key` = "panic_mode"', {})
    if panicMode == 'true' then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PanicModeActive)
        return
    end

    local target = tonumber(targetId)
    if not target or GetPlayerPing(target) == 0 then
        TriggerClientEvent('badmin:notify', source, Config.Messages.PlayerNotFound)
        return
    end

    ammo = tonumber(ammo) or 0
    if ammo > Config.Economy.MaxAmmo then
        ammo = Config.Economy.MaxAmmo
    end

    -- Check whitelist
    local perms = GetPlayerPermissions(source)
    if perms.rank ~= 'owner' then
        local allowed = false
        for _, weapon in ipairs(Config.Economy.AllowedWeapons) do
            if weapon == weaponName then
                allowed = true
                break
            end
        end
        if not allowed then
            TriggerClientEvent('badmin:notify', source, '❌ Arme non autorisée')
            LogStaffAction(source, target, 'give_weapon', 'economy', { weapon = weaponName, ammo = ammo }, false, 'Arme non autorisée')
            return
        end
    end

    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget then return end

    xTarget.addWeapon(weaponName, ammo)
    TriggerClientEvent('badmin:notify', source, string.format('✅ Arme donnée: %s (%d munitions)', weaponName, ammo))

    LogStaffAction(source, target, 'give_weapon', 'economy', { weapon = weaponName, ammo = ammo }, true)
end)

--- Panic Mode (owner only)
RegisterNetEvent('badmin:togglePanicMode', function()
    local source = source
    if not HasRank(source, 'owner') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local current = MySQL.scalar.await('SELECT `value` FROM `z_admin_config` WHERE `key` = "panic_mode"', {})
    local newValue = current == 'true' and 'false' or 'true'

    MySQL.update('UPDATE `z_admin_config` SET `value` = ?, `updated_by` = ? WHERE `key` = "panic_mode"', {
        newValue, GetPlayerLicense(source)
    })

    if newValue == 'true' and Config.PanicMode.NotifyAllPlayers then
        TriggerClientEvent('badmin:notify', -1, Config.PanicMode.NotifyMessage)
    end

    TriggerClientEvent('badmin:notify', source, newValue == 'true' and '🚨 Panic Mode ACTIVÉ' or '✅ Panic Mode DÉSACTIVÉ')

    LogStaffAction(source, nil, 'panic_mode_' .. newValue, 'security', {}, true)
end)

print('^2[B_ADMIN2]^7 Actions Economy chargées ✓')
