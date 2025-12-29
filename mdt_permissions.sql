-- ============================================
-- MDT SYSTEM - PERMISSIONS & ACCESS CONTROL
-- Système de permissions granulaires
-- ============================================
-- Ce fichier ajoute le système de permissions au MDT
-- À exécuter APRÈS mdt_schema.sql
-- ============================================

-- ============================================
-- SYSTÈME DE PERMISSIONS GRANULAIRES
-- ============================================

-- Permissions disponibles dans le système
CREATE TABLE IF NOT EXISTS `mdt_permissions_list` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `permission_key` varchar(100) NOT NULL COMMENT 'Ex: police.reports.create, doj.cases.edit',
  `permission_name` varchar(255) NOT NULL,
  `permission_category` varchar(50) NOT NULL COMMENT 'police, doj, ems, admin',
  `permission_type` enum('read','create','edit','delete','admin') NOT NULL,
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `permission_key` (`permission_key`),
  KEY `category` (`permission_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Permissions par défaut pour chaque job
CREATE TABLE IF NOT EXISTS `mdt_job_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL COMMENT 'police, sheriff, doj, ambulance, etc.',
  `job_grade` int(11) DEFAULT NULL COMMENT 'NULL = tous les grades',
  `permission_id` int(11) NOT NULL,
  `granted` tinyint(1) DEFAULT 1 COMMENT '1=accordé, 0=refusé explicitement',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `job_grade_permission` (`job_name`, `job_grade`, `permission_id`),
  KEY `permission_id` (`permission_id`),
  CONSTRAINT `fk_job_perm_permission` FOREIGN KEY (`permission_id`) REFERENCES `mdt_permissions_list` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Permissions individuelles des employés (override job permissions)
CREATE TABLE IF NOT EXISTS `mdt_user_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_identifier` varchar(60) NOT NULL,
  `permission_id` int(11) NOT NULL,
  `granted` tinyint(1) NOT NULL COMMENT '1=accordé, 0=refusé',
  `granted_by` varchar(60) NOT NULL COMMENT 'Qui a accordé/refusé',
  `reason` text DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL COMMENT 'NULL = permanent',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_permission` (`user_identifier`, `permission_id`),
  KEY `permission_id` (`permission_id`),
  CONSTRAINT `fk_user_perm_permission` FOREIGN KEY (`permission_id`) REFERENCES `mdt_permissions_list` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- CONTRÔLE D'ACCÈS AUX DOSSIERS
-- ============================================

-- Niveaux de confidentialité pour les dossiers
CREATE TABLE IF NOT EXISTS `mdt_confidentiality_levels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `level_key` varchar(50) NOT NULL COMMENT 'public, restricted, confidential, top_secret',
  `level_name` varchar(100) NOT NULL,
  `level_rank` int(11) NOT NULL COMMENT 'Plus élevé = plus confidentiel',
  `description` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `level_key` (`level_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Restrictions d'accès aux dossiers
CREATE TABLE IF NOT EXISTS `mdt_access_restrictions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `record_type` varchar(50) NOT NULL COMMENT 'case, report, patient, etc.',
  `record_id` int(11) NOT NULL,
  `confidentiality_level_id` int(11) NOT NULL,
  `restricted_from_jobs` text DEFAULT NULL COMMENT 'JSON array: jobs qui ne peuvent PAS voir',
  `restricted_from_users` text DEFAULT NULL COMMENT 'JSON array: users qui ne peuvent PAS voir',
  `allowed_jobs` text DEFAULT NULL COMMENT 'JSON array: SEULEMENT ces jobs peuvent voir (override)',
  `allowed_users` text DEFAULT NULL COMMENT 'JSON array: SEULEMENT ces users peuvent voir (override)',
  `reason` text DEFAULT NULL,
  `restricted_by` varchar(60) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `record` (`record_type`, `record_id`),
  KEY `confidentiality_level_id` (`confidentiality_level_id`),
  CONSTRAINT `fk_restriction_confidentiality` FOREIGN KEY (`confidentiality_level_id`) REFERENCES `mdt_confidentiality_levels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Logs d'accès aux dossiers sensibles
CREATE TABLE IF NOT EXISTS `mdt_access_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_identifier` varchar(60) NOT NULL,
  `user_job` varchar(50) NOT NULL,
  `record_type` varchar(50) NOT NULL,
  `record_id` int(11) NOT NULL,
  `action` enum('view','create','edit','delete','print','export') NOT NULL,
  `access_granted` tinyint(1) NOT NULL COMMENT '1=autorisé, 0=refusé',
  `denial_reason` varchar(255) DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `accessed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_actions` (`user_identifier`, `accessed_at`),
  KEY `record_access` (`record_type`, `record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTAGE DE DOSSIERS ENTRE SERVICES
-- ============================================

-- Autorisations de partage inter-services
CREATE TABLE IF NOT EXISTS `mdt_share_permissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `record_type` varchar(50) NOT NULL,
  `record_id` int(11) NOT NULL,
  `shared_by_job` varchar(50) NOT NULL COMMENT 'Job qui partage',
  `shared_by_user` varchar(60) NOT NULL,
  `shared_with_job` varchar(50) NOT NULL COMMENT 'Job destinataire',
  `shared_with_user` varchar(60) DEFAULT NULL COMMENT 'NULL = tout le job, sinon user spécifique',
  `permission_level` enum('read','read_write','full') DEFAULT 'read',
  `expires_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `record` (`record_type`, `record_id`),
  KEY `shared_with` (`shared_with_job`, `shared_with_user`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- GESTION PATRON / SUPERVISEUR
-- ============================================

-- Configuration des permissions par département/service
CREATE TABLE IF NOT EXISTS `mdt_department_config` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `config_key` varchar(100) NOT NULL COMMENT 'allow_edit_others_reports, require_supervisor_approval, etc.',
  `config_value` text NOT NULL COMMENT 'JSON ou simple value',
  `updated_by` varchar(60) NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `job_config` (`job_name`, `config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Actions bloquées par le patron pour certains grades
CREATE TABLE IF NOT EXISTS `mdt_blocked_actions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `job_grade` int(11) DEFAULT NULL COMMENT 'NULL = tous les grades sauf superviseurs',
  `action_key` varchar(100) NOT NULL COMMENT 'create_warrant, edit_case, delete_report, etc.',
  `is_blocked` tinyint(1) DEFAULT 1,
  `reason` text DEFAULT NULL,
  `blocked_by` varchar(60) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `job_grade_action` (`job_name`, `job_grade`, `action_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- AJOUT DE CHAMPS CONFIDENTIALITÉ AUX TABLES EXISTANTES
-- ============================================

-- Ajouter champ confidentialité aux cases (DOJ)
ALTER TABLE `mdt_cases` ADD COLUMN `confidentiality_level_id` int(11) DEFAULT NULL AFTER `priority`;
ALTER TABLE `mdt_cases` ADD COLUMN `sealed` tinyint(1) DEFAULT 0 COMMENT 'Dossier scellé = invisible sauf admin' AFTER `confidentiality_level_id`;
ALTER TABLE `mdt_cases` ADD KEY `confidentiality` (`confidentiality_level_id`);

-- Ajouter champ confidentialité aux rapports police
ALTER TABLE `mdt_reports` ADD COLUMN `confidentiality_level_id` int(11) DEFAULT NULL AFTER `status`;
ALTER TABLE `mdt_reports` ADD COLUMN `sensitive` tinyint(1) DEFAULT 0 COMMENT 'Rapport sensible (UC, informant, etc.)' AFTER `confidentiality_level_id`;
ALTER TABLE `mdt_reports` ADD KEY `confidentiality` (`confidentiality_level_id`);

-- Ajouter champ confidentialité aux patients EMS
ALTER TABLE `mdt_patients` ADD COLUMN `confidentiality_level_id` int(11) DEFAULT NULL AFTER `medical_flags`;
ALTER TABLE `mdt_patients` ADD COLUMN `hipaa_protected` tinyint(1) DEFAULT 1 COMMENT 'Protection HIPAA par défaut' AFTER `confidentiality_level_id`;
ALTER TABLE `mdt_patients` ADD KEY `confidentiality` (`confidentiality_level_id`);

-- Ajouter champ confidentialité aux ePCR
ALTER TABLE `mdt_epcr` ADD COLUMN `confidentiality_level_id` int(11) DEFAULT NULL AFTER `status`;
ALTER TABLE `mdt_epcr` ADD KEY `confidentiality` (`confidentiality_level_id`);

-- Ajouter champ confidentialité aux preuves
ALTER TABLE `mdt_evidence` ADD COLUMN `confidentiality_level_id` int(11) DEFAULT NULL AFTER `status`;
ALTER TABLE `mdt_evidence` ADD KEY `confidentiality` (`confidentiality_level_id`);

-- ============================================
-- DONNÉES DE DÉPART (NIVEAUX DE CONFIDENTIALITÉ)
-- ============================================

INSERT INTO `mdt_confidentiality_levels` (`level_key`, `level_name`, `level_rank`, `description`) VALUES
('public', 'Public', 0, 'Accessible à tous les membres du service'),
('restricted', 'Restreint', 1, 'Accessible uniquement aux grades autorisés'),
('confidential', 'Confidentiel', 2, 'Accès limité - superviseurs uniquement'),
('top_secret', 'Top Secret', 3, 'Accès très limité - command staff uniquement'),
('sealed', 'Scellé', 4, 'Invisible sauf exception judiciaire');

-- ============================================
-- PERMISSIONS DE BASE POUR POLICE
-- ============================================

INSERT INTO `mdt_permissions_list` (`permission_key`, `permission_name`, `permission_category`, `permission_type`, `description`) VALUES
-- CAD
('police.cad.view', 'Voir les appels CAD', 'police', 'read', 'Voir la liste des appels 911'),
('police.cad.create', 'Créer un appel', 'police', 'create', 'Créer un nouvel appel CAD'),
('police.cad.edit', 'Modifier un appel', 'police', 'edit', 'Modifier les détails d\'un appel'),
('police.cad.close', 'Clôturer un appel', 'police', 'delete', 'Clôturer un appel CAD'),

-- Recherches
('police.search.citizen', 'Rechercher citoyen', 'police', 'read', 'Rechercher dans la base citoyens'),
('police.search.vehicle', 'Rechercher véhicule', 'police', 'read', 'Rechercher dans la base véhicules'),
('police.search.weapon', 'Rechercher arme', 'police', 'read', 'Rechercher dans le registre armes'),

-- Rapports
('police.reports.view', 'Voir les rapports', 'police', 'read', 'Voir tous les rapports'),
('police.reports.create', 'Créer un rapport', 'police', 'create', 'Créer un nouveau rapport'),
('police.reports.edit', 'Modifier un rapport', 'police', 'edit', 'Modifier ses propres rapports'),
('police.reports.edit_all', 'Modifier tous les rapports', 'police', 'admin', 'Modifier n\'importe quel rapport (superviseur)'),
('police.reports.delete', 'Supprimer un rapport', 'police', 'delete', 'Supprimer un rapport (superviseur)'),

-- Arrestations
('police.arrests.view', 'Voir les arrestations', 'police', 'read', 'Voir les arrestations'),
('police.arrests.create', 'Créer une arrestation', 'police', 'create', 'Créer un rapport d\'arrestation'),

-- BOLO
('police.bolo.view', 'Voir les BOLO', 'police', 'read', 'Voir les BOLO actifs'),
('police.bolo.create', 'Créer un BOLO', 'police', 'create', 'Créer un BOLO'),
('police.bolo.edit', 'Modifier un BOLO', 'police', 'edit', 'Modifier un BOLO'),
('police.bolo.close', 'Clôturer un BOLO', 'police', 'delete', 'Clôturer un BOLO'),

-- Preuves
('police.evidence.view', 'Voir les preuves', 'police', 'read', 'Voir les preuves'),
('police.evidence.create', 'Saisir des preuves', 'police', 'create', 'Créer une entrée de preuve'),
('police.evidence.edit', 'Modifier les preuves', 'police', 'edit', 'Modifier chain of custody'),
('police.evidence.release', 'Restituer des preuves', 'police', 'admin', 'Autoriser la restitution'),

-- Personnel
('police.personnel.view', 'Voir le personnel', 'police', 'read', 'Voir le roster'),
('police.personnel.manage', 'Gérer le personnel', 'police', 'admin', 'Gérer sanctions, formations (superviseur)');

-- ============================================
-- PERMISSIONS DE BASE POUR DOJ
-- ============================================

INSERT INTO `mdt_permissions_list` (`permission_key`, `permission_name`, `permission_category`, `permission_type`, `description`) VALUES
-- Cases
('doj.cases.view', 'Voir les dossiers', 'doj', 'read', 'Voir les dossiers/affaires'),
('doj.cases.create', 'Créer un dossier', 'doj', 'create', 'Créer un nouveau dossier'),
('doj.cases.edit', 'Modifier un dossier', 'doj', 'edit', 'Modifier un dossier assigné'),
('doj.cases.edit_all', 'Modifier tous les dossiers', 'doj', 'admin', 'Modifier n\'importe quel dossier'),
('doj.cases.seal', 'Sceller un dossier', 'doj', 'admin', 'Sceller un dossier (juge)'),

-- Charges
('doj.charges.view', 'Voir les charges', 'doj', 'read', 'Voir les charges'),
('doj.charges.file', 'Déposer des charges', 'doj', 'create', 'Déposer des charges (procureur)'),
('doj.charges.dismiss', 'Rejeter des charges', 'doj', 'admin', 'Rejeter des charges (juge)'),

-- Mandats
('doj.warrants.view', 'Voir les mandats', 'doj', 'read', 'Voir les mandats'),
('doj.warrants.create', 'Créer un mandat', 'doj', 'create', 'Créer un mandat (procureur/juge)'),
('doj.warrants.approve', 'Approuver un mandat', 'doj', 'admin', 'Approuver un mandat (juge)'),
('doj.warrants.recall', 'Annuler un mandat', 'doj', 'admin', 'Annuler un mandat (juge)'),

-- Audiences
('doj.hearings.view', 'Voir les audiences', 'doj', 'read', 'Voir le calendrier'),
('doj.hearings.schedule', 'Planifier une audience', 'doj', 'create', 'Planifier une audience'),
('doj.hearings.manage', 'Gérer les audiences', 'doj', 'admin', 'Modifier/annuler audiences (juge)'),

-- Jugements
('doj.judgments.view', 'Voir les jugements', 'doj', 'read', 'Voir les jugements'),
('doj.judgments.create', 'Prononcer un jugement', 'doj', 'admin', 'Créer un jugement (juge uniquement)'),

-- Probation
('doj.probation.view', 'Voir les probations', 'doj', 'read', 'Voir les probations actives'),
('doj.probation.manage', 'Gérer les probations', 'doj', 'edit', 'Gérer violations, révocations'),

-- Reports police
('doj.reports_police.view', 'Voir rapports police', 'doj', 'read', 'Lire les rapports police'),
('doj.reports_police.validate', 'Valider rapports police', 'doj', 'admin', 'Approuver/rejeter rapports'),
('doj.reports_police.request', 'Demander compléments', 'doj', 'edit', 'Retourner rapport pour compléments');

-- ============================================
-- PERMISSIONS DE BASE POUR EMS
-- ============================================

INSERT INTO `mdt_permissions_list` (`permission_key`, `permission_name`, `permission_category`, `permission_type`, `description`) VALUES
-- Dispatch
('ems.dispatch.view', 'Voir les appels EMS', 'ems', 'read', 'Voir la liste des appels'),
('ems.dispatch.create', 'Créer un appel', 'ems', 'create', 'Créer un nouvel appel'),
('ems.dispatch.edit', 'Modifier un appel', 'ems', 'edit', 'Modifier les détails'),

-- Patients
('ems.patients.view', 'Voir les patients', 'ems', 'read', 'Rechercher et voir les patients'),
('ems.patients.create', 'Créer un patient', 'ems', 'create', 'Créer un nouveau profil patient'),
('ems.patients.edit', 'Modifier un patient', 'ems', 'edit', 'Modifier les infos patient'),

-- ePCR
('ems.epcr.view', 'Voir les ePCR', 'ems', 'read', 'Voir les rapports médicaux'),
('ems.epcr.create', 'Créer un ePCR', 'ems', 'create', 'Créer un rapport médical'),
('ems.epcr.edit', 'Modifier un ePCR', 'ems', 'edit', 'Modifier ses propres ePCR'),
('ems.epcr.edit_all', 'Modifier tous les ePCR', 'ems', 'admin', 'Modifier n\'importe quel ePCR (superviseur)'),

-- Certificats
('ems.certificates.view', 'Voir les certificats', 'ems', 'read', 'Voir les certificats'),
('ems.certificates.create', 'Créer un certificat', 'ems', 'create', 'Créer un certificat'),
('ems.certificates.sign', 'Signer un certificat', 'ems', 'admin', 'Signer un certificat (MD/superviseur)'),

-- 5150
('ems.mental_health.view', 'Voir 5150 holds', 'ems', 'read', 'Voir les holds santé mentale'),
('ems.mental_health.create', 'Créer un 5150', 'ems', 'create', 'Initier un hold 5150'),
('ems.mental_health.release', 'Lever un 5150', 'ems', 'admin', 'Autoriser la levée du hold'),

-- Inventaire
('ems.inventory.view', 'Voir l\'inventaire', 'ems', 'read', 'Voir l\'inventaire médical'),
('ems.inventory.manage', 'Gérer l\'inventaire', 'ems', 'admin', 'Gérer stocks (superviseur)');

-- ============================================
-- VUES UTILES POUR VÉRIFICATION PERMISSIONS
-- ============================================

-- Vue pour checker rapidement les permissions d'un user
CREATE OR REPLACE VIEW `mdt_user_effective_permissions` AS
SELECT DISTINCT
    u.identifier,
    u.job as job_name,
    u.job_grade,
    p.permission_key,
    p.permission_name,
    p.permission_type,
    COALESCE(up.granted, jp.granted, 0) as has_permission,
    CASE
        WHEN up.id IS NOT NULL THEN 'user_override'
        WHEN jp.id IS NOT NULL THEN 'job_default'
        ELSE 'denied'
    END as permission_source
FROM users u
CROSS JOIN mdt_permissions_list p
LEFT JOIN mdt_user_permissions up ON up.user_identifier = u.identifier
    AND up.permission_id = p.id
    AND (up.expires_at IS NULL OR up.expires_at > NOW())
LEFT JOIN mdt_job_permissions jp ON jp.job_name = u.job
    AND (jp.job_grade IS NULL OR jp.job_grade = u.job_grade)
    AND jp.permission_id = p.id
WHERE u.job IN ('police', 'sheriff', 'doj', 'ambulance', 'fire')
ORDER BY u.identifier, p.permission_category, p.permission_key;

-- ============================================
-- INDEXES ADDITIONNELS POUR PERFORMANCE
-- ============================================

ALTER TABLE `mdt_access_logs` ADD INDEX `date_range` (`accessed_at`);
ALTER TABLE `mdt_user_permissions` ADD INDEX `active_perms` (`user_identifier`, `expires_at`);
ALTER TABLE `mdt_share_permissions` ADD INDEX `active_shares` (`shared_with_job`, `expires_at`);

-- ============================================
-- FIN DU SCHÉMA PERMISSIONS
-- ============================================
