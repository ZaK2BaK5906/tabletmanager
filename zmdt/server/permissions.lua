-- ============================================
-- SYSTÈME DE PERMISSIONS
-- ============================================

-- Cache des permissions (rafraîchi toutes les 5 minutes)
local permissionsCache = {}
local cacheExpiry = {}
local CACHE_TTL = 300000 -- 5 minutes

-- Vérifier si un joueur a une permission
function HasPermission(source, permissionKey)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    local identifier = xPlayer.identifier

    -- Check cache
    local cacheKey = identifier..'_'..permissionKey
    if permissionsCache[cacheKey] and cacheExpiry[cacheKey] > GetGameTimer() then
        return permissionsCache[cacheKey]
    end

    -- Check user-specific permission first (highest priority)
    local userPerm = MySQL.scalar.await([[
        SELECT up.granted
        FROM mdt_user_permissions up
        JOIN mdt_permissions_list p ON p.id = up.permission_id
        WHERE up.user_identifier = ? AND p.permission_key = ?
        AND (up.expires_at IS NULL OR up.expires_at > NOW())
    ]], {identifier, permissionKey})

    if userPerm ~= nil then
        local hasPermission = userPerm == 1
        permissionsCache[cacheKey] = hasPermission
        cacheExpiry[cacheKey] = GetGameTimer() + CACHE_TTL
        return hasPermission
    end

    -- Check job permission (default)
    local jobPerm = MySQL.scalar.await([[
        SELECT jp.granted
        FROM mdt_job_permissions jp
        JOIN mdt_permissions_list p ON p.id = jp.permission_id
        WHERE jp.job_name = ?
        AND (jp.job_grade IS NULL OR jp.job_grade = ?)
        AND p.permission_key = ?
    ]], {xPlayer.job.name, xPlayer.job.grade, permissionKey})

    local hasPermission = jobPerm == 1

    -- Cache result
    permissionsCache[cacheKey] = hasPermission
    cacheExpiry[cacheKey] = GetGameTimer() + CACHE_TTL

    return hasPermission
end

-- Vérifier si une action est bloquée par le patron
function IsActionBlocked(source, actionKey)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return true end

    local isBlocked = MySQL.scalar.await([[
        SELECT is_blocked
        FROM mdt_blocked_actions
        WHERE job_name = ?
        AND (job_grade IS NULL OR job_grade = ?)
        AND action_key = ?
    ]], {xPlayer.job.name, xPlayer.job.grade, actionKey})

    return isBlocked == 1
end

-- Vérifier l'accès à un dossier spécifique
function CanAccessRecord(source, recordType, recordId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false, 'User not found' end

    local identifier = xPlayer.identifier
    local job = xPlayer.job.name

    -- Check access restrictions
    local restriction = MySQL.single.await([[
        SELECT ar.*, cl.level_rank
        FROM mdt_access_restrictions ar
        JOIN mdt_confidentiality_levels cl ON cl.id = ar.confidentiality_level_id
        WHERE ar.record_type = ? AND ar.record_id = ?
        AND (ar.expires_at IS NULL OR ar.expires_at > NOW())
    ]], {recordType, recordId})

    if not restriction then
        -- No restriction = public access
        return true, nil
    end

    -- Parse JSON arrays
    local restrictedJobs = restriction.restricted_from_jobs and json.decode(restriction.restricted_from_jobs) or {}
    local restrictedUsers = restriction.restricted_from_users and json.decode(restriction.restricted_from_users) or {}
    local allowedJobs = restriction.allowed_jobs and json.decode(restriction.allowed_jobs) or {}
    local allowedUsers = restriction.allowed_users and json.decode(restriction.allowed_users) or {}

    -- Check if explicitly restricted
    for _, rJob in ipairs(restrictedJobs) do
        if rJob == job then
            return false, 'Job blocked by access restriction'
        end
    end

    for _, rUser in ipairs(restrictedUsers) do
        if rUser == identifier then
            return false, 'User blocked by access restriction'
        end
    end

    -- Check if in allowlist (if allowlist is set, ONLY those can access)
    if #allowedJobs > 0 then
        local found = false
        for _, aJob in ipairs(allowedJobs) do
            if aJob == job then
                found = true
                break
            end
        end
        if not found then
            return false, 'Not in allowed jobs list'
        end
    end

    if #allowedUsers > 0 then
        local found = false
        for _, aUser in ipairs(allowedUsers) do
            if aUser == identifier then
                found = true
                break
            end
        end
        if not found then
            return false, 'Not in allowed users list'
        end
    end

    -- Check if shared with this user/job
    local share = MySQL.single.await([[
        SELECT permission_level
        FROM mdt_share_permissions
        WHERE record_type = ? AND record_id = ?
        AND shared_with_job = ?
        AND (shared_with_user IS NULL OR shared_with_user = ?)
        AND (expires_at IS NULL OR expires_at > NOW())
    ]], {recordType, recordId, job, identifier})

    if share then
        return true, nil -- Shared = access granted
    end

    -- If confidentiality level is very high, deny by default
    if restriction.level_rank >= 3 then
        return false, 'Confidential record - access denied'
    end

    return true, nil
end

-- Récupérer toutes les permissions d'un user
function GetUserPermissions(identifier)
    local permissions = MySQL.query.await([[
        SELECT DISTINCT p.permission_key, p.permission_type
        FROM mdt_user_effective_permissions uep
        JOIN mdt_permissions_list p ON p.permission_key = uep.permission_key
        WHERE uep.identifier = ? AND uep.has_permission = 1
    ]], {identifier})

    return permissions or {}
end

-- Clear cache for a user (when permissions change)
function ClearPermissionsCache(identifier)
    for key, _ in pairs(permissionsCache) do
        if key:match('^'..identifier..'_') then
            permissionsCache[key] = nil
            cacheExpiry[key] = nil
        end
    end
end

-- Exports
exports('HasPermission', HasPermission)
exports('IsActionBlocked', IsActionBlocked)
exports('CanAccessRecord', CanAccessRecord)
exports('GetUserPermissions', GetUserPermissions)
exports('ClearPermissionsCache', ClearPermissionsCache)

print('^2[ZMDT]^0 Permissions system loaded')
