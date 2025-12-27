-- ============================================
-- SYSTÈME DE NOTIFICATIONS ESX
-- ============================================

function ShowNotification(message, type, duration)
    ESX.ShowNotification(message)
end

-- Event depuis le serveur
RegisterNetEvent('tablet:notify', function(message, type, duration)
    ShowNotification(message, type, duration)
end)

-- Exports pour compatibilité
exports('ShowNotification', ShowNotification)
