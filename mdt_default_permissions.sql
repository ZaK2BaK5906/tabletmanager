-- ============================================
-- PERMISSIONS PAR DÉFAUT POUR MDT
-- ============================================
-- Ce fichier insère les permissions par défaut pour tous les grades de Police/DOJ/EMS
-- À exécuter APRÈS mdt_permissions.sql

-- ============================================
-- POLICE - PERMISSIONS PAR DÉFAUT
-- ============================================

-- Tous les policiers peuvent:
INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted) VALUES
-- CAD
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.cad.view'), 1),
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.cad.create'), 1),
-- Recherches
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.search.citizen'), 1),
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.search.vehicle'), 1),
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.search.weapon'), 1),
-- BOLO
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.bolo.view'), 1),
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.bolo.create'), 1),
-- Reports
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.reports.view'), 1),
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.reports.create'), 1),
-- Citations
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.citations.create'), 1),
-- Arrests
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.arrests.create'), 1),
-- Warrants (consultation)
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.warrants.view'), 1)
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- Sheriff (mêmes permissions que police)
INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted)
SELECT 'sheriff', job_grade, permission_id, granted
FROM mdt_job_permissions
WHERE job_name = 'police'
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- State Police (mêmes permissions que police)
INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted)
SELECT 'state_police', job_grade, permission_id, granted
FROM mdt_job_permissions
WHERE job_name = 'police'
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- ============================================
-- DOJ - PERMISSIONS PAR DÉFAUT
-- ============================================

INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted) VALUES
-- Cases
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.cases.view'), 1),
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.cases.create'), 1),
-- Warrants
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.warrants.view'), 1),
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.warrants.create'), 1),
-- Subpoenas
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.subpoenas.create'), 1),
-- Hearings
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.hearings.view'), 1),
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.hearings.create'), 1)
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- Government (mêmes permissions que doj)
INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted)
SELECT 'government', job_grade, permission_id, granted
FROM mdt_job_permissions
WHERE job_name = 'doj'
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- ============================================
-- EMS - PERMISSIONS PAR DÉFAUT
-- ============================================

INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted) VALUES
-- Dispatch
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.dispatch.view'), 1),
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.dispatch.create'), 1),
-- Patients
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.patients.view'), 1),
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.patients.search'), 1),
-- ePCR
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.epcr.create'), 1),
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.epcr.view_own'), 1),
-- Medical Records (lecture seule)
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.medical_records.view'), 1),
-- Vitals
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.vitals.create'), 1)
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- Fire (mêmes permissions que ambulance)
INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted)
SELECT 'fire', job_grade, permission_id, granted
FROM mdt_job_permissions
WHERE job_name = 'ambulance'
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- ============================================
-- CONFIRMATION
-- ============================================

SELECT
    'Permissions installées' as status,
    COUNT(*) as total_permissions,
    COUNT(DISTINCT job_name) as jobs_configured
FROM mdt_job_permissions;

SELECT
    job_name,
    COUNT(*) as permissions_count
FROM mdt_job_permissions
GROUP BY job_name
ORDER BY job_name;
