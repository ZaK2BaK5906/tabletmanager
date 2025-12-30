Config = {}

-- ============================================
-- GÉNÉRAL
-- ============================================
Config.Locale = 'fr'
Config.ServerName = 'REVIVE RP'
Config.ServerId = 'srv01' -- Pour multi-serveur

-- ============================================
-- PERMISSIONS & RBAC
-- ============================================

-- Ranks avec héritage (chaque rank hérite du précédent)
Config.Ranks = {
    'helper',      -- 1
    'mod',         -- 2
    'admin',       -- 3
    'superadmin',  -- 4
    'owner'        -- 5
}

-- Mapping Discord Role IDs -> Rank (remplacer par vos IDs)
Config.DiscordRoles = {
    ['1043283984672641094'] = 'owner' -- Role staff = owner (toutes permissions)
}

-- WHITELIST LICENSES (PRIORITAIRE - ajoutez vos licenses ici)
Config.AdminLicenses = {
    ['license:fcb47b307801e586e8c95881bdfc98004f24d031'] = 'owner', -- Ta license = owner
    -- Ajouter d'autres licenses ici :
    -- ['license:xxxxx'] = 'admin',
    -- ['license:yyyyy'] = 'mod',
}

-- Overrides par Discord User ID (optionnel, prioritaire sur roles)
Config.DiscordUserOverrides = {
    -- ['discord:123456789'] = { rank = 'owner', flags = {'*'} }
}

-- Cache TTL pour permissions Discord (en secondes)
Config.PermissionCacheTTL = 300 -- 5 minutes

-- Fallback ACE (optionnel, si Discord fail)
Config.UseFallbackACE = true
Config.ACEPermission = 'badmin.access'

-- ============================================
-- FLAGS & PERMISSIONS PAR RANK
-- ============================================

-- Flags par défaut pour chaque rank (héritage automatique)
Config.RankFlags = {
    helper = {
        'admin.ui.open',
        'admin.player.goto',
        'admin.player.bring',
        'admin.reports.view',
        'admin.reports.reply'
    },
    mod = {
        'admin.player.spectate',
        'admin.player.freeze',
        'admin.player.revive',
        'admin.player.heal',
        'admin.mod.warn',
        'admin.mod.kick',
        'admin.mod.ban.temp',
        'admin.reports.manage',
        'admin.vehicle.delete'
    },
    admin = {
        'admin.player.setjob',
        'admin.player.clearinv',
        'admin.mod.ban.perma',
        'admin.vehicle.spawn',
        'admin.world.timeweather',
        'admin.staffmode',
        'admin.player.watch_discord'
    },
    superadmin = {
        'admin.economy.give_money',
        'admin.economy.remove_money',
        'admin.economy.give_item',
        'admin.economy.give_weapon',
        'admin.devtools'
    },
    owner = {
        '*' -- Toutes permissions
    }
}

-- ============================================
-- UI / NUI
-- ============================================

Config.MenuKey = 'F10' -- Touche pour ouvrir le menu (admin.ui.open requis)
Config.CloseMenuKey = 'ESC'

-- Refresh intervals (ms)
Config.UIRefreshInterval = 1000 -- Dashboard
Config.SpectateOverlayRefresh = 750 -- Overlay spectate (throttle)
Config.WatchDiscordInterval = 8000 -- Télémétrie Discord (ms)

-- ============================================
-- SPECTATE
-- ============================================

Config.SpectateSettings = {
    GhostMode = true,          -- Staff invincible/invisible/no collision
    ShowOverlay = true,        -- Overlay top-bar
    ShowSidebar = true,        -- Sidebar inventaire/timeline
    AllowSilentSpec = true,    -- Silent spec (pas de notif à la cible)
    MaxConcurrentSpecs = 5,    -- Max spec simultanés (perf)
}

-- ============================================
-- STAFF MODE
-- ============================================

Config.StaffMode = {
    EnableNoclip = true,
    EnableGodMode = true,
    EnableInvisible = true,
    ShowWatermark = true,
    WatermarkText = '🛡️ STAFF MODE',
    WatermarkPosition = { x = 0.5, y = 0.95 } -- Centre-bas
}

-- ============================================
-- MODERATION
-- ============================================

Config.Moderation = {
    WarnPointsThreshold = 10,     -- Points avant auto-ban
    WarnExpireDays = 30,          -- Expiration warns (jours)
    DefaultTempBanDuration = 86400, -- 1 jour (secondes)
    MaxTempBanDuration = 2592000, -- 30 jours
    RequireDoubleConfirmPerma = true
}

-- ============================================
-- ECONOMY
-- ============================================

Config.Economy = {
    MaxGiveMoney = 1000000,       -- Cap par transaction
    MaxGiveMoneyPerDay = 5000000, -- Cap journalier (anti-abus)
    RequireDoubleConfirm = true,
    CooldownSeconds = 60,

    -- Whitelists
    AllowedItems = {
        'bread', 'water', 'bandage', 'phone', 'id_card',
        -- Ajouter items autorisés
    },
    MaxItemQuantity = 500,

    AllowedWeapons = {
        'WEAPON_PISTOL', 'WEAPON_NIGHTSTICK', 'WEAPON_FLASHLIGHT',
        -- Ajouter armes autorisées
    },
    MaxAmmo = 250
}

-- ============================================
-- VEHICLES
-- ============================================

Config.Vehicles = {
    AllowedVehicles = {
        'adder', 'zentorno', 'police', 'ambulance', 'taxi',
        -- Ajouter véhicules autorisés (ou '*' pour tous si superadmin)
    },
    MaxSpawnDistance = 10.0,
    DeleteRadius = 5.0
}

-- ============================================
-- WORLD
-- ============================================

Config.World = {
    AllowedWeathers = {
        'CLEAR', 'EXTRASUNNY', 'CLOUDS', 'OVERCAST', 'RAIN',
        'THUNDER', 'CLEARING', 'NEUTRAL', 'SNOW', 'BLIZZARD',
        'SNOWLIGHT', 'XMAS', 'HALLOWEEN'
    }
}

-- ============================================
-- LOGGING
-- ============================================

Config.Logging = {
    -- Staff logs (toujours actifs)
    StaffLogs = {
        Database = true,
        Discord = true,
        Console = true
    },

    -- Player logs (optionnel, peut être gourmand)
    PlayerLogs = {
        Database = true,
        Discord = false, -- Recommandé: false (spam)
        Console = false,
        LogConnect = true,
        LogDisconnect = true,
        LogVehicle = true,
        LogWeaponFired = false, -- Très gourmand
        LogKillDeath = true,
        LogInventory = true,
        LogMoney = true,
        LogCommands = true,
        LogTeleport = true,  -- Détection suspect
        LogSpeed = true      -- Détection suspect
    },

    -- Fichier JSONL (optionnel)
    JSONLFile = false,
    JSONLPath = 'logs/admin_logs.jsonl'
}

-- Discord Webhooks (par catégorie)
Config.Webhooks = {
    moderation = 'https://discord.com/api/webhooks/1455405399317676065/hqda9icjhpbbZdi1l4oWY5WYd74QNjgLgBmfjVlPYl96QXpRlakgK5oeQ5uqSQURMYiV',
    economy = 'https://discord.com/api/webhooks/1455405399317676065/hqda9icjhpbbZdi1l4oWY5WYd74QNjgLgBmfjVlPYl96QXpRlakgK5oeQ5uqSQURMYiV',
    player = 'https://discord.com/api/webhooks/1455405399317676065/hqda9icjhpbbZdi1l4oWY5WYd74QNjgLgBmfjVlPYl96QXpRlakgK5oeQ5uqSQURMYiV',
    staffmode = 'https://discord.com/api/webhooks/1455405399317676065/hqda9icjhpbbZdi1l4oWY5WYd74QNjgLgBmfjVlPYl96QXpRlakgK5oeQ5uqSQURMYiV',
    reports = 'https://discord.com/api/webhooks/1455405399317676065/hqda9icjhpbbZdi1l4oWY5WYd74QNjgLgBmfjVlPYl96QXpRlakgK5oeQ5uqSQURMYiV',
    security = 'https://discord.com/api/webhooks/1455405399317676065/hqda9icjhpbbZdi1l4oWY5WYd74QNjgLgBmfjVlPYl96QXpRlakgK5oeQ5uqSQURMYiV',
    player_actions = 'https://discord.com/api/webhooks/1455405399317676065/hqda9icjhpbbZdi1l4oWY5WYd74QNjgLgBmfjVlPYl96QXpRlakgK5oeQ5uqSQURMYiV' -- Optionnel
}

-- ============================================
-- DISCORD BOT API
-- ============================================

Config.DiscordBot = {
    Enabled = true,
    GuildId = '1043276815629815998', -- Votre Guild ID
    StaffChannelId = '1455405371920220233', -- Channel staff

    -- Sécurité HMAC
    HMACSecret = 'CHANGE_ME_SUPER_SECRET_KEY_MINIMUM_32_CHARS', -- CHANGER !
    RequestTTL = 30, -- TTL requêtes (secondes)

    -- Rate limits bot
    RateLimitWindow = 60, -- Fenêtre (secondes)
    RateLimitMax = 20,    -- Max requêtes par fenêtre

    -- Whitelist roles autorisés (Discord Role IDs)
    AllowedRoles = {
        '1043283984672641094' -- Role staff
    }
}

-- ============================================
-- TICKETS & REPORTS
-- ============================================

Config.Tickets = {
    Enabled = false,
    MaxOpenPerPlayer = 3,
    AutoAssign = true, -- Auto-assign au staff dispo
    RequireScreenshot = false,

    Categories = {
        'cheat', 'bug', 'grief', 'help', 'abuse', 'other'
    },

    Priorities = {
        'low', 'normal', 'high', 'urgent'
    },

    AutoPriorityKeywords = { -- Auto-mark urgent si keywords
        urgent = {'cheat', 'hack', 'aimbot', 'godmode'},
        high = {'grief', 'rdm', 'vdm', 'abuse'}
    }
}

-- ============================================
-- RATE LIMITS (ANTI-SPAM)
-- ============================================

Config.RateLimits = {
    -- Format: [action] = { max, window (secondes) }
    ['goto'] = { 10, 60 },
    ['bring'] = { 10, 60 },
    ['spectate'] = { 5, 60 },
    ['freeze'] = { 15, 60 },
    ['revive'] = { 20, 60 },
    ['heal'] = { 20, 60 },
    ['warn'] = { 5, 300 },
    ['kick'] = { 5, 300 },
    ['ban'] = { 3, 300 },
    ['give_money'] = { 5, 300 },
    ['give_item'] = { 10, 300 },
    ['spawn_vehicle'] = { 5, 300 },
    ['screenshot'] = { 3, 60 }
}

-- ============================================
-- PANIC MODE
-- ============================================

Config.PanicMode = {
    DisableEconomy = true,
    DisableVehicleSpawn = true,
    DisableTPCommands = true,
    NotifyAllPlayers = true,
    NotifyMessage = '⚠️ Le serveur est en mode maintenance, certaines fonctionnalités sont désactivées.'
}

-- ============================================
-- MESSAGES
-- ============================================

Config.Messages = {
    NoPermission = '❌ Vous n\'avez pas la permission.',
    PlayerNotFound = '❌ Joueur introuvable.',
    ActionSuccess = '✅ Action effectuée avec succès.',
    ActionFailed = '❌ Échec de l\'action.',
    RateLimited = '⏳ Vous allez trop vite, attendez un peu.',
    PanicModeActive = '⚠️ Mode Panic activé, action bloquée.',
    TargetIsStaff = '⚠️ La cible est un membre du staff.',
    DoubleConfirmRequired = '⚠️ Confirmation requise pour cette action critique.',

    -- NUI Messages
    MenuOpened = '📋 Menu admin ouvert',
    MenuClosed = '📋 Menu admin fermé',
    SpectateStarted = '👁️ Spectate démarré',
    SpectateStopped = '👁️ Spectate arrêté',
    StaffModeEnabled = '🛡️ Staff Mode activé',
    StaffModeDisabled = '🛡️ Staff Mode désactivé',
}

-- ============================================
-- DEV TOOLS
-- ============================================

Config.DevMode = false -- Active debug console
Config.DevTools = {
    ShowTimings = true,
    ShowRateLimits = true,
    ShowErrors = true,
    MaxErrorHistory = 50
}
