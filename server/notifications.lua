-- ============================================
-- SYSTÈME DE NOTIFICATIONS ESX (SERVER)
-- ============================================

function ShowNotification(source, message, type, duration)
    TriggerClientEvent('tablet:notify', source, message, type, duration)
end

-- Exports
exports('ShowNotification', ShowNotification)
