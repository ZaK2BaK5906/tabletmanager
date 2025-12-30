-- ============================================
-- B_ADMIN2 - NUI CALLBACKS
-- ============================================

-- ============================================
-- NUI -> CLIENT CALLBACKS
-- ============================================

RegisterNUICallback('close', function(data, cb)
    ToggleMenu()
    cb('ok')
end)

RegisterNUICallback('getDashboard', function(data, cb)
    ESX.TriggerServerCallback('badmin:getDashboard', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('getPlayers', function(data, cb)
    ESX.TriggerServerCallback('badmin:getPlayers', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('getPlayerData', function(data, cb)
    ESX.TriggerServerCallback('badmin:getPlayerData', function(result)
        cb(result)
    end, data.playerId)
end)

RegisterNUICallback('goto', function(data, cb)
    TriggerServerEvent('badmin:goto', data.playerId)
    cb('ok')
end)

RegisterNUICallback('bring', function(data, cb)
    TriggerServerEvent('badmin:bring', data.playerId)
    cb('ok')
end)

RegisterNUICallback('freeze', function(data, cb)
    TriggerServerEvent('badmin:freeze', data.playerId, data.freeze)
    cb('ok')
end)

RegisterNUICallback('revive', function(data, cb)
    TriggerServerEvent('badmin:revive', data.playerId)
    cb('ok')
end)

RegisterNUICallback('heal', function(data, cb)
    TriggerServerEvent('badmin:heal', data.playerId)
    cb('ok')
end)

RegisterNUICallback('spectate', function(data, cb)
    TriggerEvent('badmin:startSpectate', data.playerId)
    cb('ok')
end)

RegisterNUICallback('stopSpectate', function(data, cb)
    TriggerEvent('badmin:stopSpectate')
    cb('ok')
end)

RegisterNUICallback('clearInventory', function(data, cb)
    TriggerServerEvent('badmin:clearInventory', data.playerId, data.confirmed)
    cb('ok')
end)

RegisterNUICallback('setJob', function(data, cb)
    TriggerServerEvent('badmin:setJob', data.playerId, data.job, data.grade)
    cb('ok')
end)

RegisterNUICallback('warn', function(data, cb)
    TriggerServerEvent('badmin:warn', data.playerId, data.reason, data.points)
    cb('ok')
end)

RegisterNUICallback('kick', function(data, cb)
    TriggerServerEvent('badmin:kick', data.playerId, data.reason)
    cb('ok')
end)

RegisterNUICallback('ban', function(data, cb)
    TriggerServerEvent('badmin:ban', data.playerId, data.banType, data.reason, data.duration)
    cb('ok')
end)

RegisterNUICallback('giveMoney', function(data, cb)
    TriggerServerEvent('badmin:giveMoney', data.playerId, data.account, data.amount, data.confirmed)
    cb('ok')
end)

RegisterNUICallback('removeMoney', function(data, cb)
    TriggerServerEvent('badmin:removeMoney', data.playerId, data.account, data.amount, data.confirmed)
    cb('ok')
end)

RegisterNUICallback('giveItem', function(data, cb)
    TriggerServerEvent('badmin:giveItem', data.playerId, data.item, data.quantity)
    cb('ok')
end)

RegisterNUICallback('giveWeapon', function(data, cb)
    TriggerServerEvent('badmin:giveWeapon', data.playerId, data.weapon, data.ammo)
    cb('ok')
end)

RegisterNUICallback('spawnVehicle', function(data, cb)
    TriggerServerEvent('badmin:spawnVehicle', data.model)
    cb('ok')
end)

RegisterNUICallback('deleteVehicle', function(data, cb)
    TriggerServerEvent('badmin:deleteVehicle')
    cb('ok')
end)

RegisterNUICallback('vehicleAction', function(data, cb)
    TriggerServerEvent('badmin:vehicleAction', data.action)
    cb('ok')
end)

RegisterNUICallback('setTime', function(data, cb)
    TriggerServerEvent('badmin:setTime', data.hour, data.minute)
    cb('ok')
end)

RegisterNUICallback('setWeather', function(data, cb)
    TriggerServerEvent('badmin:setWeather', data.weather)
    cb('ok')
end)

RegisterNUICallback('toggleStaffMode', function(data, cb)
    TriggerServerEvent('badmin:toggleStaffMode')
    cb('ok')
end)

RegisterNUICallback('togglePanicMode', function(data, cb)
    TriggerServerEvent('badmin:togglePanicMode')
    cb('ok')
end)

RegisterNUICallback('getTickets', function(data, cb)
    ESX.TriggerServerCallback('badmin:getTickets', function(result)
        cb(result)
    end, data.filter)
end)

RegisterNUICallback('createTicket', function(data, cb)
    TriggerServerEvent('badmin:createTicket', data)
    cb('ok')
end)

RegisterNUICallback('resolveTicket', function(data, cb)
    TriggerServerEvent('badmin:resolveTicket', data.ticketId, data.note, data.rating)
    cb('ok')
end)

print('^2[B_ADMIN2]^7 Client NUI Callbacks chargés ✓')
