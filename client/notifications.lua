-- ============================================
-- SYSTÈME DE NOTIFICATIONS OX_LIB
-- ============================================

function ShowNotification(message, type, duration)
    lib.notify({
        title = 'Tablette',
        description = message,
        type = type or 'info', -- 'info', 'success', 'error', 'warning'
        duration = duration or 5000,
        position = 'top-right'
    })
end

-- Event depuis le serveur
RegisterNetEvent('tablet:notify', function(message, type, duration)
    ShowNotification(message, type, duration)
end)

-- Exports pour compatibilité
exports('ShowNotification', ShowNotification)
