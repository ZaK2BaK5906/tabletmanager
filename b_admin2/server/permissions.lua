-- ============================================
-- B_ADMIN2 - SYSTÈME DE PERMISSIONS RBAC
-- ============================================

PermissionsCache = {} -- Cache { license = { rank, flags, expires } }
DiscordCache = {}     -- Cache Discord identifiers

-- ============================================
-- UTILITAIRES
-- ============================================

--- Récupère l'identifier Discord d'un joueur
---@param source number
---@return string|nil
function GetDiscordIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in pairs(identifiers) do
        if string.match(id, 'discord:') then
            return id
        end
    end
    return nil
end

--- Récupère la license d'un joueur
---@param source number
---@return string|nil
function GetPlayerLicense(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in pairs(identifiers) do
        if string.match(id, 'license:') then
            return id
        end
    end
    return nil
end

--- Récupère l'index d'un rank (pour héritage)
---@param rank string
---@return number
local function GetRankIndex(rank)
    for i, r in ipairs(Config.Ranks) do
        if r == rank then
            return i
        end
    end
    return 0
end

--- Vérifie si rankA >= rankB (héritage)
---@param rankA string
---@param rankB string
---@return boolean
local function IsRankSuperiorOrEqual(rankA, rankB)
    return GetRankIndex(rankA) >= GetRankIndex(rankB)
end

-- ============================================
-- RÉCUPÉRATION PERMISSIONS DISCORD
-- ============================================

--- Récupère le rank Discord d'un joueur via roles
---@param source number
---@return string|nil rank
local function GetDiscordRank(source)
    local discord = GetDiscordIdentifier(source)
    if not discord then return nil end

    -- Check cache
    local cached = DiscordCache[discord]
    if cached and cached.expires > os.time() then
        return cached.rank
    end

    -- Check user overrides (prioritaire)
    if Config.DiscordUserOverrides[discord] then
        local override = Config.DiscordUserOverrides[discord]
        DiscordCache[discord] = {
            rank = override.rank,
            expires = os.time() + Config.PermissionCacheTTL
        }
        return override.rank
    end

    -- Check roles
    local discordId = string.gsub(discord, 'discord:', '')
    local roles = exports.badmin_discord:GetPlayerRoles(source) -- Assume external resource si besoin

    -- Fallback: récupérer roles via identifiers (si pas d'export externe)
    -- Ici on simule avec Config.DiscordRoles (à adapter selon votre méthode)

    for roleId, rank in pairs(Config.DiscordRoles) do
        -- Vérifier si le joueur a ce role (nécessite intégration Discord)
        -- Pour l'instant, on fait un fallback simple
        -- TODO: Intégrer récupération roles Discord via API ou autre ressource
    end

    -- Fallback: pas de rank Discord trouvé
    DiscordCache[discord] = {
        rank = nil,
        expires = os.time() + Config.PermissionCacheTTL
    }

    return nil
end

-- ============================================
-- RÉCUPÉRATION PERMISSIONS PLAYER
-- ============================================

--- Récupère les permissions d'un joueur (DB + Discord)
---@param source number
---@return table { rank: string, flags: table }
function GetPlayerPermissions(source)
    local license = GetPlayerLicense(source)
    if not license then
        return { rank = 'none', flags = {} }
    end

    -- Check cache
    local cached = PermissionsCache[license]
    if cached and cached.expires > os.time() then
        return cached
    end

    local permissions = { rank = 'none', flags = {} }

    -- 1. Check DB
    local result = MySQL.query.await('SELECT `rank`, `flags`, `is_active`, `expires_at` FROM `z_admin_permissions` WHERE `identifier` = ? LIMIT 1', {
        license
    })

    if result and result[1] then
        local dbPerms = result[1]
        if dbPerms.is_active == 1 then
            -- Check expiration
            if not dbPerms.expires_at or os.time() < GetTimestamp(dbPerms.expires_at) then
                permissions.rank = dbPerms.rank
                permissions.flags = json.decode(dbPerms.flags or '[]')
            end
        end
    end

    -- 2. Check Discord (si pas de DB ou si Discord rank supérieur)
    local discordRank = GetDiscordRank(source)
    if discordRank then
        if permissions.rank == 'none' or IsRankSuperiorOrEqual(discordRank, permissions.rank) then
            permissions.rank = discordRank
        end
    end

    -- 3. Fallback ACE (optionnel)
    if Config.UseFallbackACE and permissions.rank == 'none' then
        if IsPlayerAceAllowed(source, Config.ACEPermission) then
            permissions.rank = 'admin' -- Rank par défaut pour ACE
        end
    end

    -- 4. Ajouter flags du rank (héritage)
    local rankFlags = {}
    for i = 1, GetRankIndex(permissions.rank) do
        local rank = Config.Ranks[i]
        if Config.RankFlags[rank] then
            for _, flag in ipairs(Config.RankFlags[rank]) do
                rankFlags[flag] = true
            end
        end
    end

    -- Merger avec flags custom (DB)
    for _, flag in ipairs(permissions.flags) do
        rankFlags[flag] = true
    end

    -- Convertir en array
    local finalFlags = {}
    for flag, _ in pairs(rankFlags) do
        table.insert(finalFlags, flag)
    end

    permissions.flags = finalFlags

    -- Cache
    PermissionsCache[license] = {
        rank = permissions.rank,
        flags = permissions.flags,
        expires = os.time() + Config.PermissionCacheTTL
    }

    return permissions
end

-- ============================================
-- VÉRIFICATION PERMISSIONS
-- ============================================

--- Vérifie si un joueur a un flag spécifique
---@param source number
---@param flag string
---@return boolean
function HasPermission(source, flag)
    local perms = GetPlayerPermissions(source)

    -- Owner a tout (wildcard)
    if perms.rank == 'owner' then
        return true
    end

    -- Check wildcard
    for _, f in ipairs(perms.flags) do
        if f == '*' then
            return true
        end
        if f == flag then
            return true
        end
    end

    return false
end

--- Vérifie si un joueur a un rank minimum
---@param source number
---@param requiredRank string
---@return boolean
function HasRank(source, requiredRank)
    local perms = GetPlayerPermissions(source)
    return IsRankSuperiorOrEqual(perms.rank, requiredRank)
end

--- Vérifie si un joueur est staff
---@param source number
---@return boolean
function IsStaff(source)
    local perms = GetPlayerPermissions(source)
    return perms.rank ~= 'none'
end

-- ============================================
-- GESTION PERMISSIONS (ADMIN COMMANDS)
-- ============================================

--- Ajoute/modifie les permissions d'un joueur en DB
---@param identifier string
---@param rank string
---@param customFlags table|nil
---@param adminSource number
---@return boolean success
function SetPlayerPermission(identifier, rank, customFlags, adminSource)
    if not identifier or not rank then return false end

    local adminLicense = GetPlayerLicense(adminSource)
    local discordId = nil

    -- Récupérer discord_id si possible
    local target = GetPlayerFromIdentifier(identifier)
    if target then
        discordId = GetDiscordIdentifier(target)
    end

    local flagsJson = json.encode(customFlags or {})

    local result = MySQL.query.await([[
        INSERT INTO `z_admin_permissions` (`identifier`, `rank`, `flags`, `discord_id`, `assigned_by`)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            `rank` = VALUES(`rank`),
            `flags` = VALUES(`flags`),
            `discord_id` = VALUES(`discord_id`),
            `assigned_by` = VALUES(`assigned_by`),
            `assigned_at` = CURRENT_TIMESTAMP,
            `is_active` = 1
    ]], {
        identifier, rank, flagsJson, discordId, adminLicense
    })

    -- Clear cache
    PermissionsCache[identifier] = nil

    return result ~= nil
end

--- Révoque les permissions d'un joueur
---@param identifier string
---@return boolean success
function RevokePlayerPermission(identifier)
    if not identifier then return false end

    local result = MySQL.query.await('UPDATE `z_admin_permissions` SET `is_active` = 0 WHERE `identifier` = ?', {
        identifier
    })

    -- Clear cache
    PermissionsCache[identifier] = nil

    return result ~= nil
end

-- ============================================
-- HELPERS
-- ============================================

--- Récupère un joueur depuis n'importe quel identifier
---@param identifier string
---@return number|nil source
function GetPlayerFromIdentifier(identifier)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local ids = GetPlayerIdentifiers(playerId)
        for _, id in ipairs(ids) do
            if id == identifier then
                return tonumber(playerId)
            end
        end
    end
    return nil
end

--- Convertit timestamp MySQL en Unix timestamp
---@param mysqlTimestamp string
---@return number
function GetTimestamp(mysqlTimestamp)
    if not mysqlTimestamp then return 0 end
    local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
    local year, month, day, hour, min, sec = mysqlTimestamp:match(pattern)
    return os.time({
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = sec
    })
end

-- ============================================
-- EVENTS
-- ============================================

-- Clear cache quand joueur disconnect
AddEventHandler('playerDropped', function()
    local src = source
    local license = GetPlayerLicense(src)
    if license then
        PermissionsCache[license] = nil
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

exports('GetPlayerPermissions', GetPlayerPermissions)
exports('HasPermission', HasPermission)
exports('HasRank', HasRank)
exports('IsStaff', IsStaff)
exports('SetPlayerPermission', SetPlayerPermission)
exports('RevokePlayerPermission', RevokePlayerPermission)

-- ============================================
-- COMMANDS DEBUG
-- ============================================

RegisterCommand('badmin:perms', function(source, args)
    if source == 0 then return end -- Console uniquement

    local perms = GetPlayerPermissions(source)
    print('^3[B_ADMIN2]^7 Permissions pour ' .. GetPlayerName(source))
    print('  Rank: ' .. perms.rank)
    print('  Flags: ' .. json.encode(perms.flags, { indent = true }))
end, false)

print('^2[B_ADMIN2]^7 Système de permissions RBAC chargé ✓')
