-- ============================================
-- SYSTÈME DE NOTIFICATIONS OX_LIB
-- ============================================

function ShowNotification(message, type, duration)
    -- Protection: utiliser ox_lib si disponible, sinon ESX
    if lib and lib.notify then
        lib.notify({
            title = 'Tablette',
            description = message,
            type = type or 'info', -- 'info', 'success', 'error', 'warning'
            duration = duration or 5000,
            position = 'top-right'
        })
    else
        -- Fallback sur ESX si ox_lib n'est pas disponible
        ESX.ShowNotification(message)
    end
end

-- Event depuis le serveur
RegisterNetEvent('tablet:notify', function(message, type, duration)
    ShowNotification(message, type, duration)
end)

-- Exports pour compatibilité
exports('ShowNotification', ShowNotification)
