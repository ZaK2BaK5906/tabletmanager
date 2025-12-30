-- ============================================
-- B_ADMIN2 - RATE LIMITING (ANTI-SPAM)
-- ============================================

RateLimitCache = {} -- { identifier = { action = { count, reset_at } } }

--- Vérifie si un joueur peut effectuer une action (rate limit)
---@param source number
---@param actionType string
---@return boolean canProceed
---@return string|nil errorMessage
function CheckRateLimit(source, actionType)
    local config = Config.RateLimits[actionType]
    if not config then
        return true -- Pas de rate limit configuré
    end

    local max, window = config[1], config[2]
    local license = GetPlayerLicense(source)
    if not license then
        return false, 'Identifier introuvable'
    end

    local now = os.time()

    -- Initialiser cache
    if not RateLimitCache[license] then
        RateLimitCache[license] = {}
    end

    local actionCache = RateLimitCache[license][actionType]

    -- Première utilisation ou reset
    if not actionCache or now >= actionCache.reset_at then
        RateLimitCache[license][actionType] = {
            count = 1,
            reset_at = now + window
        }
        return true
    end

    -- Incrémenter et vérifier limite
    actionCache.count = actionCache.count + 1

    if actionCache.count > max then
        local remaining = actionCache.reset_at - now
        return false, string.format('Rate limit dépassé. Réessayez dans %d secondes.', remaining)
    end

    -- Sauvegarder en DB (optionnel, pour persistence)
    MySQL.query('INSERT INTO `z_admin_rate_limits` (`identifier`, `action_type`, `use_count`, `reset_at`) VALUES (?, ?, ?, FROM_UNIXTIME(?)) ON DUPLICATE KEY UPDATE `use_count` = VALUES(`use_count`), `reset_at` = VALUES(`reset_at`)', {
        license,
        actionType,
        actionCache.count,
        actionCache.reset_at
    })

    return true
end

--- Reset le rate limit d'un joueur pour une action (admin)
---@param identifier string
---@param actionType string|nil Si nil, reset tout
function ResetRateLimit(identifier, actionType)
    if actionType then
        if RateLimitCache[identifier] then
            RateLimitCache[identifier][actionType] = nil
        end
        MySQL.query('DELETE FROM `z_admin_rate_limits` WHERE `identifier` = ? AND `action_type` = ?', {
            identifier, actionType
        })
    else
        RateLimitCache[identifier] = nil
        MySQL.query('DELETE FROM `z_admin_rate_limits` WHERE `identifier` = ?', {
            identifier
        })
    end
end

-- Cleanup périodique (toutes les 5 minutes)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 5 min

        local now = os.time()
        for identifier, actions in pairs(RateLimitCache) do
            for action, data in pairs(actions) do
                if now >= data.reset_at then
                    RateLimitCache[identifier][action] = nil
                end
            end
        end

        -- Cleanup DB
        MySQL.query('DELETE FROM `z_admin_rate_limits` WHERE `reset_at` < NOW()')
    end
end)

exports('CheckRateLimit', CheckRateLimit)
exports('ResetRateLimit', ResetRateLimit)
