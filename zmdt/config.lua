Config = {}

-- ============================================
-- JOBS AUTORISÉS
-- ============================================

-- Jobs Police
Config.PoliceJobs = {
    'police',
    'sheriff',
    'state_police'
}

-- Jobs DOJ
Config.DOJJobs = {
    'doj',
    'government'
}

-- Jobs EMS
Config.EMSJobs = {
    'ambulance',
    'fire'
}

-- Tous les jobs MDT
Config.AllMDTJobs = {}
for _, job in ipairs(Config.PoliceJobs) do table.insert(Config.AllMDTJobs, job) end
for _, job in ipairs(Config.DOJJobs) do table.insert(Config.AllMDTJobs, job) end
for _, job in ipairs(Config.EMSJobs) do table.insert(Config.AllMDTJobs, job) end

-- ============================================
-- GRADES SUPERVISEURS (pour permissions avancées)
-- ============================================

Config.SupervisorGrades = {
    ['police'] = 4,      -- Sergeant et +
    ['sheriff'] = 4,
    ['doj'] = 3,         -- Senior Attorney et +
    ['ambulance'] = 3,   -- Supervisor et +
    ['fire'] = 3
}

-- ============================================
-- COMMANDES
-- ============================================

Config.Commands = {
    mdt = 'mdt',           -- /mdt pour ouvrir
    bolo = 'bolo',         -- /bolo [text] pour BOLO rapide
    wanted = 'wanted',     -- /wanted [id] pour wanted rapide
    dispatch = '911'       -- /911 pour voir appels actifs
}

-- ============================================
-- INTÉGRATION ESX
-- ============================================

-- Synchronisation automatique avec ESX
Config.SyncWithESX = {
    citizens = true,        -- Sync users -> mdt_citizens
    vehicles = true,        -- Sync owned_vehicles -> mdt_vehicles
    weapons = true,         -- Sync datastore -> mdt_weapons
    licenses = true         -- Sync user_licenses -> mdt_licenses
}

-- Mapping licences ESX → MDT
Config.LicenseMapping = {
    ['drive'] = 'drive',
    ['drive_bike'] = 'drive_bike',
    ['drive_truck'] = 'drive_truck',
    ['weapon'] = 'weapon',     -- Licence arme
    ['dmv'] = 'drive',         -- Compatibility
    ['weed_processing'] = nil  -- Ignorer
}

-- ============================================
-- NIVEAUX DE CONFIDENTIALITÉ PAR DÉFAUT
-- ============================================

Config.DefaultConfidentiality = {
    reports = 'public',        -- Rapports police
    cases = 'restricted',      -- Dossiers DOJ
    patients = 'confidential', -- Patients EMS
    evidence = 'restricted'
}

-- ============================================
-- RAYON DE DÉTECTION
-- ============================================

Config.NearbyRadius = 50.0  -- Mètres pour recherche joueurs proches

-- ============================================
-- WEBHOOKS DISCORD
-- ============================================

Config.Webhooks = {
    Enabled = true,

    -- Police
    PoliceReports = '',
    PoliceArrests = '',
    PoliceBOLO = '',
    PoliceEvidence = '',

    -- DOJ
    DOJCases = '',
    DOJWarrants = '',
    DOJJudgments = '',

    -- EMS
    EMSReports = '',
    EMS5150 = '',
    EMSDeaths = ''
}

-- ============================================
-- PERMISSIONS PAR DÉFAUT (par grade)
-- ============================================

Config.DefaultPermissions = {
    -- Police - Tous les grades
    police = {
        [0] = { -- Cadet/Recruit
            'police.cad.view',
            'police.search.citizen',
            'police.search.vehicle',
            'police.reports.view',
            'police.bolo.view'
        },
        [1] = { -- Officer
            'police.cad.view',
            'police.cad.create',
            'police.search.citizen',
            'police.search.vehicle',
            'police.search.weapon',
            'police.reports.view',
            'police.reports.create',
            'police.reports.edit',
            'police.arrests.create',
            'police.bolo.view',
            'police.bolo.create',
            'police.evidence.view',
            'police.evidence.create'
        },
        [2] = { -- Senior Officer
            -- Même que Officer + citations
            'police.citations.create'
        },
        [3] = { -- Corporal
            -- Même que Senior + edit others
        },
        [4] = { -- Sergeant (Superviseur)
            'police.reports.edit_all',
            'police.reports.delete',
            'police.evidence.release',
            'police.personnel.manage'
        }
    },

    -- DOJ - Procureurs et Juges
    doj = {
        [0] = { -- Junior Attorney
            'doj.cases.view',
            'doj.reports_police.view'
        },
        [1] = { -- Attorney
            'doj.cases.view',
            'doj.cases.create',
            'doj.cases.edit',
            'doj.charges.file',
            'doj.reports_police.view',
            'doj.reports_police.request'
        },
        [2] = { -- Senior Attorney
            'doj.warrants.create',
            'doj.hearings.schedule',
            'doj.probation.manage'
        },
        [3] = { -- Judge
            'doj.warrants.approve',
            'doj.hearings.manage',
            'doj.judgments.create',
            'doj.cases.seal',
            'doj.reports_police.validate'
        }
    },

    -- EMS - Paramedics
    ems = {
        [0] = { -- EMT Basic
            'ems.dispatch.view',
            'ems.patients.view',
            'ems.epcr.view'
        },
        [1] = { -- Paramedic
            'ems.dispatch.create',
            'ems.patients.create',
            'ems.patients.edit',
            'ems.epcr.create',
            'ems.epcr.edit',
            'ems.mental_health.create',
            'ems.certificates.create'
        },
        [2] = { -- Advanced Paramedic
            'ems.mental_health.release',
            'ems.certificates.sign'
        },
        [3] = { -- Supervisor / MD
            'ems.epcr.edit_all',
            'ems.inventory.manage'
        }
    }
}

-- ============================================
-- FORMATS DE NUMÉROS
-- ============================================

Config.NumberFormats = {
    calls = 'YYMMDD-XXX',        -- 251229-001
    reports = 'YY-XXXXX',        -- 25-00001
    cases = 'CF-YY-XXXXX',       -- CF-25-00001
    warrants = 'WR-YY-XXXXX',    -- WR-25-00001
    arrests = 'AR-YY-XXXXX',     -- AR-25-00001
    citations = 'CT-YY-XXXXX',   -- CT-25-00001
    epcr = 'EMS-YY-XXXXX'        -- EMS-25-00001
}

-- ============================================
-- UI COLORS
-- ============================================

Config.Colors = {
    police = '#3b82f6',    -- Bleu
    doj = '#f59e0b',       -- Or
    ems = '#ef4444'        -- Rouge
}

-- ============================================
-- NOTIFICATIONS
-- ============================================

Config.Notifications = {
    ['no_permission'] = '❌ Vous n\'avez pas la permission',
    ['no_access'] = '❌ Accès refusé - dossier confidentiel',
    ['success'] = '✅ Opération réussie',
    ['error'] = '❌ Une erreur est survenue',
    ['not_found'] = '❌ Introuvable',
    ['invalid_data'] = '❌ Données invalides'
}

print('^2[ZMDT]^0 Config loaded successfully')
