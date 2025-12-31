Config = {}

-- ============================================
-- CONFIGURATION GÉNÉRALE
-- ============================================

Config.Framework = 'esx' -- esx ou qb-core
Config.Command = 'mdt' -- Commande pour ouvrir la MDT
Config.UseSteam = false -- Utiliser Steam pour identifier les joueurs (false = fonctionne sans Steam)

-- ============================================
-- JOBS POLICE
-- ============================================

Config.PoliceJobs = {
    'police',
    'sheriff',
    'state'
}

-- ============================================
-- JOBS EMS (POUR PLUS TARD)
-- ============================================

Config.EMSJobs = {
    'ambulance',
    'fire'
}

-- ============================================
-- JOBS DOJ (POUR PLUS TARD)
-- ============================================

Config.DOJJobs = {
    'doj',
    'government',
    'judge',
    'lawyer'
}

-- ============================================
-- PERMISSIONS PAR GRADE
-- ============================================

Config.Permissions = {
    police = {
        -- Grade 0-2 : Cadets / Officers
        [0] = {
            dashboard = true,
            cad = true,
            search_citizens = true,
            search_vehicles = true,
            citizen_profile = true,
            bolo_view = true,
            reports_view = true,
            reports_create = true,
            arrests_create = true,
            citations_create = true,
            evidence_create = true,
            notes_create = true,
            units = true,
            charges = true,

            -- Interdictions
            warrants_create = false,
            reports_approve = false,
            reports_delete = false,
            personnel_manage = false,
            ppa_issue = false,
            wanted_create = false,
            intel_confidential = false
        },
        [1] = {
            dashboard = true,
            cad = true,
            search_citizens = true,
            search_vehicles = true,
            citizen_profile = true,
            bolo_view = true,
            bolo_create = true,
            reports_view = true,
            reports_create = true,
            arrests_create = true,
            citations_create = true,
            evidence_create = true,
            evidence_release = false,
            notes_create = true,
            units = true,
            charges = true,
            stolen_vehicles = true,

            -- Toujours interdit
            warrants_create = false,
            reports_approve = false,
            personnel_manage = false,
            ppa_issue = false,
            intel_confidential = false
        },
        [2] = {
            dashboard = true,
            cad = true,
            search_citizens = true,
            search_vehicles = true,
            citizen_profile = true,
            bolo_view = true,
            bolo_create = true,
            bolo_close = true,
            reports_view = true,
            reports_create = true,
            arrests_create = true,
            citations_create = true,
            evidence_create = true,
            evidence_release = false,
            notes_create = true,
            units = true,
            charges = true,
            stolen_vehicles = true,
            wanted_view = true,

            -- Interdit
            warrants_create = false,
            reports_approve = false,
            personnel_manage = false,
            ppa_issue = false,
            intel_confidential = false
        },
        -- Grade 3+ : Sergeants / Lieutenants / Captains / Chiefs
        [3] = {
            dashboard = true,
            cad = true,
            search_citizens = true,
            search_vehicles = true,
            citizen_profile = true,
            bolo_view = true,
            bolo_create = true,
            bolo_close = true,
            reports_view = true,
            reports_create = true,
            reports_approve = true,
            arrests_create = true,
            citations_create = true,
            evidence_create = true,
            evidence_release = true,
            notes_create = true,
            units = true,
            charges = true,
            stolen_vehicles = true,
            wanted_view = true,
            wanted_create = true,
            warrants_view = true,
            warrants_create = true,
            intel_view = true,
            intel_create = true,
            personnel_view = true,
            ppa_issue = false, -- Toujours superviseur+
            intel_confidential = false
        },
        [4] = { -- Superviseur (Capitaine+)
            all = true, -- Accès total
            dashboard = true,
            cad = true,
            search_citizens = true,
            search_vehicles = true,
            citizen_profile = true,
            bolo_view = true,
            bolo_create = true,
            bolo_close = true,
            reports_view = true,
            reports_create = true,
            reports_approve = true,
            reports_delete = true,
            arrests_create = true,
            citations_create = true,
            evidence_create = true,
            evidence_release = true,
            notes_create = true,
            units = true,
            charges = true,
            stolen_vehicles = true,
            wanted_view = true,
            wanted_create = true,
            warrants_view = true,
            warrants_create = true,
            intel_view = true,
            intel_create = true,
            intel_confidential = true,
            personnel_view = true,
            personnel_manage = true,
            ppa_issue = true,
            ppa_revoke = true,
            ppa_heavy_issue = true
        }
    }
}

-- ============================================
-- WEBHOOKS DISCORD
-- ============================================

Config.Webhooks = {
    enabled = true, -- Activer/désactiver tous les webhooks

    urls = {
        arrests = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', -- Arrestations
        reports = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', -- Rapports
        bolo = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', -- BOLO
        citations = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', -- Citations
        warrants = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', -- Mandats
        evidence = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', -- Preuves
        ppa = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', -- PPA
        admin = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE' -- Admin (tout)
    },

    colors = {
        arrests = 16711680, -- Rouge
        reports = 3447003, -- Bleu
        bolo = 16776960, -- Jaune
        citations = 16744272, -- Orange
        warrants = 10038562, -- Violet
        evidence = 9807270, -- Vert foncé
        ppa = 5763719, -- Vert
        admin = 15158332, -- Blanc
        error = 15158332 -- Rouge vif
    },

    -- Configuration détaillée des events
    events = {
        arrests = {'arrest_created', 'arrest_processed'},
        reports = {'report_created', 'report_approved', 'report_rejected'},
        bolo = {'bolo_created', 'bolo_closed'},
        citations = {'citation_issued', 'citation_paid'},
        warrants = {'warrant_issued', 'warrant_executed', 'warrant_recalled'},
        evidence = {'evidence_logged', 'evidence_released', 'evidence_destroyed'},
        ppa = {'ppa_issued', 'ppa_revoked', 'ppa_heavy_issued'},
        admin = {'all'} -- Tous les events
    }
}

-- ============================================
-- NUMÉROTATION AUTOMATIQUE
-- ============================================

Config.AutoNumbering = {
    calls = 'CALL-%y%m%d-%n', -- Ex: CALL-251231-001
    reports = 'RPT-%y%m%d-%n', -- Ex: RPT-251231-001
    arrests = 'ARR-%y%m%d-%n', -- Ex: ARR-251231-001
    citations = 'CIT-%y%m%d-%n', -- Ex: CIT-251231-001
    warrants = 'WRT-%y%m%d-%n', -- Ex: WRT-251231-001
    evidence = 'EVD-%y%m%d-%n', -- Ex: EVD-251231-001
    bolo = 'BOLO-%y%m%d-%n', -- Ex: BOLO-251231-001
    ppa = 'PPA-%y%m%d-%n', -- Ex: PPA-251231-001
    ppa_heavy = 'PPAH-%y%m%d-%n' -- Ex: PPAH-251231-001
}

-- %y = année (2 chiffres)
-- %m = mois
-- %d = jour
-- %n = numéro incrémental (001, 002, etc.)

-- ============================================
-- SYSTÈME PPA
-- ============================================

Config.PPA = {
    enabled = true,

    -- Durée de validité (jours)
    validity = {
        standard = 365, -- 1 an
        heavy = 180 -- 6 mois (renouvellement plus fréquent)
    },

    -- Catégories d'armes lourdes
    heavy_categories = {
        'automatic', -- Armes automatiques
        'heavy', -- Armes lourdes (mitrailleuses, etc.)
        'explosive', -- Explosifs
        'special' -- Catégorie spéciale (sniper, etc.)
    },

    -- Grades minimum pour délivrer
    min_grade_issue = 4, -- Grade 4+ peut délivrer PPA
    min_grade_heavy = 4, -- Grade 4+ peut délivrer PPA Lourd

    -- Background check requis
    require_background_check = true,
    require_training = true
}

-- ============================================
-- SYSTÈME DE CHARGES PÉNALES
-- ============================================

Config.Charges = {
    -- Les charges sont stockées en base de données (zx_police_charges)
    -- Possibilité d'ajouter des charges custom en jeu
    allow_custom_charges = false, -- Seuls les superviseurs peuvent ajouter des charges

    -- Multiplicateurs selon type d'arme/véhicule
    multipliers = {
        weapon = 1.5, -- Avec arme
        vehicle = 1.2, -- Avec véhicule
        gang = 2.0, -- Activité gang
        repeat_offense = 1.5 -- Récidive
    }
}

-- ============================================
-- UNITÉS / PATROUILLES
-- ============================================

Config.Units = {
    enabled = true,

    -- Types d'unités
    types = {
        'patrol', -- Patrouille
        'traffic', -- Traffic
        'k9', -- Chiens
        'swat', -- SWAT
        'detective', -- Détectives
        'motorcycle', -- Moto
        'air', -- Hélico
        'marine' -- Marine
    },

    -- 10-codes
    codes = {
        ['10-7'] = 'Hors service',
        ['10-8'] = 'Disponible',
        ['10-6'] = 'Occupé',
        ['10-97'] = 'En route',
        ['10-23'] = 'Sur les lieux',
        ['code-6'] = 'Assistance requise'
    },

    -- Auto-suppression des unités inactives (minutes)
    auto_remove_inactive = 30
}

-- ============================================
-- RECHERCHE CITOYENS
-- ============================================

Config.CitizenSearch = {
    -- Champs visibles dans le profil citoyen
    show_bank_accounts = true, -- Voir les comptes bancaires
    show_vehicles = true, -- Voir les véhicules (owned_vehicles)
    show_properties = true, -- Voir les propriétés
    show_phone = true, -- Voir le numéro de téléphone
    show_job = true, -- Voir le job actuel
    show_licenses = true, -- Voir les licences

    -- Historique visible
    show_arrests = true,
    show_citations = true,
    show_reports = true,
    show_warrants = true,
    show_notes = true,

    -- Limite de résultats de recherche
    max_search_results = 20
}

-- ============================================
-- VÉHICULES VOLÉS
-- ============================================

Config.StolenVehicles = {
    enabled = true,

    -- Notification automatique si véhicule volé scanné
    auto_notify_stolen = true,

    -- Durée avant suppression auto (jours, 0 = jamais)
    auto_remove_days = 30
}

-- ============================================
-- PREUVES
-- ============================================

Config.Evidence = {
    -- Chaîne de traçabilité stricte
    strict_chain_of_custody = true,

    -- Types de preuves
    types = {
        'weapon', -- Arme
        'drugs', -- Drogues
        'money', -- Argent
        'documents', -- Documents
        'electronics', -- Électronique
        'clothing', -- Vêtements
        'biological', -- Biologique
        'other' -- Autre
    },

    -- Localisation de stockage
    storage_locations = {
        'Evidence Locker',
        'Crime Lab',
        'Off-site Storage',
        'Seized Assets'
    }
}

-- ============================================
-- INTEL / RENSEIGNEMENTS
-- ============================================

Config.Intel = {
    enabled = true,

    -- Niveaux de confidentialité
    confidentiality_levels = {
        'public', -- Visible tous
        'restricted', -- Grade 2+
        'confidential', -- Grade 3+
        'top_secret' -- Grade 4+
    },

    -- Types d'intel
    types = {
        'gang',
        'organized_crime',
        'drug_trafficking',
        'terrorism',
        'corruption',
        'other'
    }
}

-- ============================================
-- BOLO
-- ============================================

Config.BOLO = {
    enabled = true,

    -- Notification automatique à toutes les unités
    auto_notify_units = true,

    -- Suppression auto des BOLO fermés (jours)
    auto_remove_closed_days = 7
}

-- ============================================
-- DASHBOARD
-- ============================================

Config.Dashboard = {
    -- Stats visibles
    show_active_calls = true,
    show_active_units = true,
    show_recent_arrests = true,
    show_active_bolo = true,
    show_wanted_persons = true,
    show_active_warrants = true,

    -- Nombre d'éléments récents
    recent_items_count = 5
}

-- ============================================
-- SYSTÈME DE LOGS
-- ============================================

Config.Logging = {
    enabled = true,

    -- Logger toutes les actions dans zx_police_activity_log
    log_all_actions = true,

    -- Durée de rétention des logs (jours, 0 = infini)
    retention_days = 90
}

-- ============================================
-- DIVERS
-- ============================================

-- Panic Button
Config.PanicButton = {
    enabled = true,
    command = 'panic',
    cooldown = 60 -- Secondes
}

-- Commandes rapides
Config.QuickCommands = {
    ['/10-8'] = 'setStatus_10-8',
    ['/10-7'] = 'setStatus_10-7',
    ['/10-6'] = 'setStatus_10-6',
    ['/bolo'] = 'openBOLO'
}

-- Clé pour ouvrir la MDT (nil = commande uniquement)
Config.OpenKey = nil -- Ex: 'F5'

print('^2[ZX Police MDT]^0 Configuration chargée')
