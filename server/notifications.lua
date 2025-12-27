-- ============================================
-- SYSTÈME DE NOTIFICATIONS OX_LIB (SERVER)
-- ============================================

function ShowNotification(source, message, type, duration)
    TriggerClientEvent('tablet:notify', source, message, type, duration)
end

-- Exports
exports('ShowNotification', ShowNotification)
