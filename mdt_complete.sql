-- ============================================
-- MDT SYSTEM - MOBILE DATA TERMINAL COMPLET
-- Pour ESX Framework (Police, DOJ, EMS)
-- ============================================
-- Ce fichier contient TOUT le système MDT en un seul fichier:
-- - Schéma de base (52 tables)
-- - Système de permissions
-- - Permissions par défaut
-- - Tables additionnelles Police
-- ============================================
-- Installation: Exécuter ce fichier SQL unique
-- ============================================

-- ============================================
-- PARTIE 1: TABLES PARTAGÉES (TOUS SERVICES)
-- ============================================

-- Profils citoyens centralisés
CREATE TABLE IF NOT EXISTS `mdt_citizens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) NOT NULL,
  `firstname` varchar(50) NOT NULL,
  `lastname` varchar(50) NOT NULL,
  `dateofbirth` date NOT NULL,
  `sex` varchar(1) DEFAULT 'M',
  `height` int(11) DEFAULT 175,
  `phone_number` varchar(20) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `photo_url` varchar(500) DEFAULT NULL,
  `fingerprint` varchar(255) DEFAULT NULL,
  `flags` text DEFAULT NULL COMMENT 'JSON: violent, gang, suicidal, etc.',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`),
  KEY `name_search` (`lastname`, `firstname`),
  KEY `dob_search` (`dateofbirth`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Pièces jointes (photos, documents, bodycam refs)
CREATE TABLE IF NOT EXISTS `mdt_attachments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(50) NOT NULL COMMENT 'report, evidence, case, patient, etc.',
  `reference_id` int(11) NOT NULL COMMENT 'ID de la table parente',
  `file_type` varchar(20) NOT NULL COMMENT 'image, document, video, bodycam',
  `file_url` varchar(500) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `uploaded_by` varchar(60) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `type_ref` (`type`, `reference_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Logs d'activité (audit trail)
CREATE TABLE IF NOT EXISTS `mdt_activity_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `action_type` varchar(50) NOT NULL COMMENT 'create, update, delete, view',
  `table_name` varchar(50) NOT NULL,
  `record_id` int(11) NOT NULL,
  `user_identifier` varchar(60) NOT NULL,
  `user_job` varchar(50) NOT NULL,
  `details` text DEFAULT NULL COMMENT 'JSON details',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `user_actions` (`user_identifier`),
  KEY `table_record` (`table_name`, `record_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Notes partagées
CREATE TABLE IF NOT EXISTS `mdt_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(50) NOT NULL COMMENT 'citizen, case, vehicle, etc.',
  `reference_id` int(11) NOT NULL,
  `note_text` text NOT NULL,
  `author_identifier` varchar(60) NOT NULL,
  `author_job` varchar(50) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `type_ref` (`type`, `reference_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 2: POLICE - CAD / DISPATCH
-- ============================================

-- Appels 911 / CAD
CREATE TABLE IF NOT EXISTS `mdt_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `call_number` varchar(20) NOT NULL COMMENT 'Format: YYMMDD-XXX',
  `priority` enum('low','medium','high','critical') DEFAULT 'medium',
  `call_type` varchar(100) NOT NULL COMMENT '10-codes, traffic stop, etc.',
  `location` varchar(255) NOT NULL,
  `caller_info` varchar(255) DEFAULT NULL,
  `description` text NOT NULL,
  `units_assigned` text DEFAULT NULL COMMENT 'JSON array of unit IDs',
  `status` enum('pending','dispatched','on_scene','closed','cancelled') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `dispatched_at` timestamp NULL DEFAULT NULL,
  `closed_at` timestamp NULL DEFAULT NULL,
  `closed_by` varchar(60) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `call_number` (`call_number`),
  KEY `status_priority` (`status`, `priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Unités / Patrouilles
CREATE TABLE IF NOT EXISTS `mdt_units` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unit_number` varchar(20) NOT NULL COMMENT 'Ex: 1-Adam-12',
  `unit_type` varchar(50) NOT NULL COMMENT 'patrol, traffic, k9, swat, etc.',
  `officer_identifier` varchar(60) NOT NULL,
  `officer_name` varchar(100) NOT NULL,
  `partner_identifier` varchar(60) DEFAULT NULL,
  `partner_name` varchar(100) DEFAULT NULL,
  `status` enum('10-8','10-7','10-6','10-97','code-6') DEFAULT '10-7' COMMENT '10-8=available, 10-7=unavailable',
  `current_location` varchar(255) DEFAULT NULL,
  `assigned_call_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `officer` (`officer_identifier`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 3: POLICE - RECHERCHES & REGISTRES
-- ============================================

-- Véhicules enregistrés
CREATE TABLE IF NOT EXISTS `mdt_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(10) NOT NULL,
  `vin` varchar(17) DEFAULT NULL,
  `model` varchar(100) NOT NULL,
  `color` varchar(50) DEFAULT NULL,
  `owner_identifier` varchar(60) DEFAULT NULL,
  `owner_name` varchar(100) DEFAULT NULL,
  `registration_status` enum('valid','expired','suspended','revoked') DEFAULT 'valid',
  `insurance_status` enum('valid','expired','none') DEFAULT 'none',
  `stolen_status` enum('not_stolen','stolen','recovered') DEFAULT 'not_stolen',
  `impound_status` enum('not_impounded','impounded','released') DEFAULT 'not_impounded',
  `flags` text DEFAULT NULL COMMENT 'JSON: bolo, wanted, etc.',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `plate` (`plate`),
  KEY `owner` (`owner_identifier`),
  KEY `stolen` (`stolen_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Registre des armes
CREATE TABLE IF NOT EXISTS `mdt_weapons` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `serial_number` varchar(100) NOT NULL,
  `weapon_type` varchar(100) NOT NULL COMMENT 'handgun, rifle, shotgun, etc.',
  `make` varchar(100) DEFAULT NULL,
  `model` varchar(100) DEFAULT NULL,
  `caliber` varchar(50) DEFAULT NULL,
  `owner_identifier` varchar(60) DEFAULT NULL,
  `owner_name` varchar(100) DEFAULT NULL,
  `legal_status` enum('legal','illegal','stolen','seized') DEFAULT 'legal',
  `registered_date` date DEFAULT NULL,
  `seized_date` date DEFAULT NULL,
  `seized_by` varchar(60) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `serial_number` (`serial_number`),
  KEY `owner` (`owner_identifier`),
  KEY `legal_status` (`legal_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Entreprises (raison sociale, licences, infractions)
CREATE TABLE IF NOT EXISTS `mdt_businesses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `business_name` varchar(255) NOT NULL,
  `business_type` varchar(100) DEFAULT NULL,
  `owner_identifier` varchar(60) DEFAULT NULL,
  `owner_name` varchar(100) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `licenses` text DEFAULT NULL COMMENT 'JSON: liquor, firearms, etc.',
  `infractions` text DEFAULT NULL COMMENT 'JSON: violations, dates',
  `status` enum('active','suspended','revoked') DEFAULT 'active',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `owner` (`owner_identifier`),
  KEY `business_name` (`business_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Licences & Permis
CREATE TABLE IF NOT EXISTS `mdt_licenses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_identifier` varchar(60) NOT NULL,
  `license_type` varchar(50) NOT NULL COMMENT 'drive, drive_bike, drive_truck, weapon, hunting, etc.',
  `status` enum('valid','suspended','revoked','expired') DEFAULT 'valid',
  `issued_date` date NOT NULL,
  `expiry_date` date DEFAULT NULL,
  `issued_by` varchar(60) DEFAULT NULL,
  `points` int(11) DEFAULT 0 COMMENT 'Points sur permis de conduire',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_license` (`citizen_identifier`, `license_type`),
  KEY `license_type` (`license_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- PPA / CCW (Port d'arme dissimulé)
CREATE TABLE IF NOT EXISTS `mdt_ppa_ccw` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_identifier` varchar(60) NOT NULL,
  `permit_type` enum('PPA','CCW') DEFAULT 'CCW',
  `permit_class` varchar(50) DEFAULT NULL COMMENT 'Class 1, 2, 3, etc.',
  `status` enum('valid','suspended','revoked','expired') DEFAULT 'valid',
  `issued_date` date NOT NULL,
  `expiry_date` date NOT NULL,
  `issued_by` varchar(60) NOT NULL COMMENT 'DOJ/Sheriff identifier',
  `conditions` text DEFAULT NULL COMMENT 'Restrictions, limitations',
  `revocation_reason` text DEFAULT NULL,
  `revoked_by` varchar(60) DEFAULT NULL,
  `revoked_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizen` (`citizen_identifier`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 4: POLICE - CASIER & INFRACTIONS
-- ============================================

-- Casier judiciaire (arrestations, charges, condamnations)
CREATE TABLE IF NOT EXISTS `mdt_criminal_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_identifier` varchar(60) NOT NULL,
  `record_type` enum('arrest','charge','conviction','probation') DEFAULT 'arrest',
  `charge_code` varchar(50) DEFAULT NULL COMMENT 'PC 459, VC 23152, etc.',
  `charge_title` varchar(255) NOT NULL,
  `charge_class` enum('infraction','misdemeanor','felony') DEFAULT 'misdemeanor',
  `arrest_date` date DEFAULT NULL,
  `conviction_date` date DEFAULT NULL,
  `sentence` text DEFAULT NULL COMMENT 'Prison time, fine, community service',
  `probation_end_date` date DEFAULT NULL,
  `status` enum('active','completed','dismissed','sealed') DEFAULT 'active',
  `case_id` int(11) DEFAULT NULL COMMENT 'Lien vers mdt_cases',
  `arresting_officer` varchar(60) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizen` (`citizen_identifier`),
  KEY `case_id` (`case_id`),
  KEY `charge_class` (`charge_class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Citations / Amendes
CREATE TABLE IF NOT EXISTS `mdt_citations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citation_number` varchar(20) NOT NULL,
  `citizen_identifier` varchar(60) NOT NULL,
  `citizen_name` varchar(100) NOT NULL,
  `violation_code` varchar(50) NOT NULL COMMENT 'VC 21461, PC 415, etc.',
  `violation_description` varchar(255) NOT NULL,
  `fine_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `points` int(11) DEFAULT 0,
  `location` varchar(255) DEFAULT NULL,
  `issued_by` varchar(60) NOT NULL,
  `issued_by_name` varchar(100) NOT NULL,
  `payment_status` enum('unpaid','paid','dismissed','warrant') DEFAULT 'unpaid',
  `paid_at` timestamp NULL DEFAULT NULL,
  `due_date` date DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citation_number` (`citation_number`),
  KEY `citizen` (`citizen_identifier`),
  KEY `payment_status` (`payment_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 5: POLICE - RAPPORTS & INCIDENTS
-- ============================================

-- Arrestations
CREATE TABLE IF NOT EXISTS `mdt_arrests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `arrest_number` varchar(20) NOT NULL,
  `citizen_identifier` varchar(60) NOT NULL,
  `citizen_name` varchar(100) NOT NULL,
  `charges` text NOT NULL COMMENT 'JSON array of charges',
  `location` varchar(255) NOT NULL,
  `arrest_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `arresting_officer` varchar(60) NOT NULL,
  `assisting_officers` text DEFAULT NULL COMMENT 'JSON array of identifiers',
  `miranda_read` tinyint(1) DEFAULT 0,
  `witnesses` text DEFAULT NULL COMMENT 'JSON array',
  `evidence_seized` text DEFAULT NULL COMMENT 'JSON array',
  `booking_photo` varchar(500) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `arrest_number` (`arrest_number`),
  KEY `citizen` (`citizen_identifier`),
  KEY `officer` (`arresting_officer`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Rapports de police (incident, traffic, etc.)
CREATE TABLE IF NOT EXISTS `mdt_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_number` varchar(20) NOT NULL,
  `report_type` varchar(50) NOT NULL COMMENT 'incident, traffic_stop, welfare_check, etc.',
  `title` varchar(255) NOT NULL,
  `location` varchar(255) NOT NULL,
  `incident_date` timestamp NOT NULL,
  `primary_officer` varchar(60) NOT NULL,
  `assisting_officers` text DEFAULT NULL COMMENT 'JSON array',
  `involved_citizens` text DEFAULT NULL COMMENT 'JSON array of identifiers',
  `involved_vehicles` text DEFAULT NULL COMMENT 'JSON array of plates',
  `narrative` text NOT NULL,
  `status` enum('draft','submitted','approved','rejected') DEFAULT 'draft',
  `approved_by` varchar(60) DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `case_id` int(11) DEFAULT NULL COMMENT 'Lien vers DOJ case si applicable',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `report_number` (`report_number`),
  KEY `primary_officer` (`primary_officer`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Use of Force Reports
CREATE TABLE IF NOT EXISTS `mdt_use_of_force` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_id` int(11) NOT NULL COMMENT 'Lien vers mdt_reports',
  `force_level` enum('verbal','physical','less_lethal','lethal') NOT NULL,
  `force_reason` text NOT NULL,
  `subject_identifier` varchar(60) DEFAULT NULL,
  `subject_injuries` text DEFAULT NULL,
  `officer_injuries` text DEFAULT NULL,
  `bodycam_ref` varchar(255) DEFAULT NULL,
  `supervisor_notified` tinyint(1) DEFAULT 0,
  `supervisor_identifier` varchar(60) DEFAULT NULL,
  `reviewed_by` varchar(60) DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `review_status` enum('pending','approved','under_investigation') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `report_id` (`report_id`),
  KEY `force_level` (`force_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Pursuit Reports
CREATE TABLE IF NOT EXISTS `mdt_pursuits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_id` int(11) NOT NULL COMMENT 'Lien vers mdt_reports',
  `primary_unit` varchar(20) NOT NULL,
  `assisting_units` text DEFAULT NULL COMMENT 'JSON array',
  `suspect_vehicle` varchar(10) DEFAULT NULL COMMENT 'Plate',
  `start_location` varchar(255) NOT NULL,
  `end_location` varchar(255) NOT NULL,
  `max_speed` int(11) DEFAULT NULL,
  `duration_minutes` int(11) DEFAULT NULL,
  `road_conditions` varchar(100) DEFAULT NULL,
  `traffic_density` enum('light','moderate','heavy') DEFAULT 'light',
  `risk_level` enum('low','medium','high') DEFAULT 'medium',
  `termination_reason` varchar(255) DEFAULT NULL,
  `injuries` text DEFAULT NULL,
  `property_damage` text DEFAULT NULL,
  `supervisor_notified` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `report_id` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 6: POLICE - BOLO / WANTED
-- ============================================

-- BOLO (Be On Lookout)
CREATE TABLE IF NOT EXISTS `mdt_bolo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bolo_type` enum('person','vehicle') NOT NULL,
  `subject` varchar(255) NOT NULL COMMENT 'Name or vehicle description',
  `description` text NOT NULL,
  `priority` enum('low','medium','high','critical') DEFAULT 'medium',
  `danger_level` enum('low','medium','high','armed_dangerous') DEFAULT 'medium',
  `zone` varchar(100) DEFAULT NULL COMMENT 'Area to watch',
  `status` enum('active','closed') DEFAULT 'active',
  `issued_by` varchar(60) NOT NULL,
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `closed_by` varchar(60) DEFAULT NULL,
  `closed_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `status` (`status`),
  KEY `priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Wanted / Avis de recherche
CREATE TABLE IF NOT EXISTS `mdt_wanted` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_identifier` varchar(60) NOT NULL,
  `citizen_name` varchar(100) NOT NULL,
  `reason` text NOT NULL,
  `charges` text DEFAULT NULL COMMENT 'JSON array',
  `priority` enum('low','medium','high') DEFAULT 'medium',
  `conditions` text DEFAULT NULL COMMENT 'Armed, dangerous, etc.',
  `warrant_id` int(11) DEFAULT NULL COMMENT 'Lien vers mdt_warrants',
  `status` enum('active','arrested','cleared') DEFAULT 'active',
  `issued_by` varchar(60) NOT NULL,
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cleared_by` varchar(60) DEFAULT NULL,
  `cleared_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizen` (`citizen_identifier`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 7: POLICE & DOJ - MANDATS
-- ============================================

-- Warrants (Mandats)
CREATE TABLE IF NOT EXISTS `mdt_warrants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `warrant_number` varchar(20) NOT NULL,
  `warrant_type` enum('arrest','search','bench') NOT NULL,
  `citizen_identifier` varchar(60) DEFAULT NULL,
  `citizen_name` varchar(100) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL COMMENT 'Pour search warrant',
  `charges` text DEFAULT NULL COMMENT 'JSON array',
  `probable_cause` text DEFAULT NULL,
  `issued_by` varchar(60) NOT NULL COMMENT 'Judge/DOJ identifier',
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expiry_date` date DEFAULT NULL,
  `status` enum('active','executed','expired','recalled') DEFAULT 'active',
  `executed_by` varchar(60) DEFAULT NULL,
  `executed_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `warrant_number` (`warrant_number`),
  KEY `citizen` (`citizen_identifier`),
  KEY `status` (`status`),
  KEY `warrant_type` (`warrant_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 8: POLICE - SAISIES & PREUVES
-- ============================================

-- Impounds / Saisies véhicules
CREATE TABLE IF NOT EXISTS `mdt_impounds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicle_plate` varchar(10) NOT NULL,
  `vehicle_model` varchar(100) DEFAULT NULL,
  `owner_identifier` varchar(60) DEFAULT NULL,
  `owner_name` varchar(100) DEFAULT NULL,
  `reason` text NOT NULL,
  `location` varchar(255) NOT NULL,
  `impounded_by` varchar(60) NOT NULL,
  `impounded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `release_date` date DEFAULT NULL,
  `release_fee` decimal(10,2) DEFAULT 0.00,
  `status` enum('impounded','released','auctioned') DEFAULT 'impounded',
  `released_to` varchar(60) DEFAULT NULL,
  `released_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `vehicle_plate` (`vehicle_plate`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Evidence / Preuves
CREATE TABLE IF NOT EXISTS `mdt_evidence` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `evidence_number` varchar(20) NOT NULL,
  `case_id` int(11) DEFAULT NULL COMMENT 'Lien vers mdt_cases',
  `report_id` int(11) DEFAULT NULL COMMENT 'Lien vers mdt_reports',
  `item_type` varchar(100) NOT NULL COMMENT 'weapon, drugs, documents, etc.',
  `description` text NOT NULL,
  `quantity` int(11) DEFAULT 1,
  `seized_from` varchar(100) DEFAULT NULL,
  `seized_location` varchar(255) DEFAULT NULL,
  `seized_by` varchar(60) NOT NULL,
  `seized_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `storage_location` varchar(100) DEFAULT NULL,
  `chain_of_custody` text DEFAULT NULL COMMENT 'JSON array: timestamps, handlers',
  `status` enum('seized','stored','released','destroyed') DEFAULT 'seized',
  `released_to` varchar(100) DEFAULT NULL,
  `released_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `evidence_number` (`evidence_number`),
  KEY `case_id` (`case_id`),
  KEY `report_id` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 9: POLICE - SCÈNES & TÉMOINS
-- ============================================

-- Scenes / Incidents
CREATE TABLE IF NOT EXISTS `mdt_scenes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_id` int(11) DEFAULT NULL COMMENT 'Lien vers mdt_reports',
  `location` varchar(255) NOT NULL,
  `scene_type` varchar(100) DEFAULT NULL COMMENT 'crime scene, accident, etc.',
  `sketch_url` varchar(500) DEFAULT NULL COMMENT 'URL du croquis',
  `witnesses` text DEFAULT NULL COMMENT 'JSON array of witness IDs',
  `evidence_collected` text DEFAULT NULL COMMENT 'JSON array of evidence IDs',
  `processing_officer` varchar(60) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `report_id` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Witnesses / Témoins
CREATE TABLE IF NOT EXISTS `mdt_witnesses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_id` int(11) DEFAULT NULL COMMENT 'Lien vers mdt_reports',
  `case_id` int(11) DEFAULT NULL COMMENT 'Lien vers mdt_cases',
  `witness_identifier` varchar(60) DEFAULT NULL,
  `witness_name` varchar(100) NOT NULL,
  `witness_phone` varchar(20) DEFAULT NULL,
  `witness_address` varchar(255) DEFAULT NULL,
  `statement` text NOT NULL,
  `signature` varchar(100) DEFAULT NULL COMMENT 'Signature RP',
  `statement_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `taken_by` varchar(60) NOT NULL,
  `credibility` enum('low','medium','high') DEFAULT 'medium',
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `report_id` (`report_id`),
  KEY `case_id` (`case_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 10: POLICE & DOJ - ORDONNANCES
-- ============================================

-- Orders (Protective/Restraining/etc.)
CREATE TABLE IF NOT EXISTS `mdt_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_number` varchar(20) NOT NULL,
  `order_type` enum('protective','restraining','gag','no_contact') NOT NULL,
  `subject_identifier` varchar(60) NOT NULL COMMENT 'Person who must comply',
  `subject_name` varchar(100) NOT NULL,
  `protected_identifier` varchar(60) DEFAULT NULL COMMENT 'Person being protected',
  `protected_name` varchar(100) DEFAULT NULL,
  `conditions` text NOT NULL,
  `distance_feet` int(11) DEFAULT NULL COMMENT 'Minimum distance',
  `issued_by` varchar(60) NOT NULL COMMENT 'Judge identifier',
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expiry_date` date DEFAULT NULL,
  `status` enum('active','expired','violated','dismissed') DEFAULT 'active',
  `violations` text DEFAULT NULL COMMENT 'JSON array of violations',
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `order_number` (`order_number`),
  KEY `subject` (`subject_identifier`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 11: POLICE - GANG INTELLIGENCE
-- ============================================

-- Gang Intelligence
CREATE TABLE IF NOT EXISTS `mdt_gangs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gang_name` varchar(100) NOT NULL,
  `gang_color` varchar(50) DEFAULT NULL,
  `territory` varchar(255) DEFAULT NULL,
  `known_members` text DEFAULT NULL COMMENT 'JSON array of citizen identifiers',
  `leader_identifier` varchar(60) DEFAULT NULL,
  `rivals` text DEFAULT NULL COMMENT 'JSON array of gang IDs',
  `activity_level` enum('low','medium','high') DEFAULT 'medium',
  `flags` text DEFAULT NULL COMMENT 'JSON: violent, drug trafficking, etc.',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `gang_name` (`gang_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 12: POLICE - PERSONNEL (SUPERVISEUR)
-- ============================================

-- Personnel Management
CREATE TABLE IF NOT EXISTS `mdt_personnel` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `officer_identifier` varchar(60) NOT NULL,
  `officer_name` varchar(100) NOT NULL,
  `badge_number` varchar(20) DEFAULT NULL,
  `rank` varchar(50) DEFAULT NULL,
  `division` varchar(50) DEFAULT NULL COMMENT 'patrol, traffic, detective, etc.',
  `certifications` text DEFAULT NULL COMMENT 'JSON: taser, k9, swat, etc.',
  `hire_date` date DEFAULT NULL,
  `performance_notes` text DEFAULT NULL,
  `disciplinary_actions` text DEFAULT NULL COMMENT 'JSON array',
  `status` enum('active','leave','suspended','terminated') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `officer_identifier` (`officer_identifier`),
  KEY `badge_number` (`badge_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 13: DOJ - DOSSIERS & AFFAIRES
-- ============================================

-- Cases / Dossiers
CREATE TABLE IF NOT EXISTS `mdt_cases` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `case_number` varchar(20) NOT NULL,
  `case_type` varchar(100) DEFAULT NULL COMMENT 'criminal, civil, traffic, etc.',
  `title` varchar(255) NOT NULL,
  `defendant_identifier` varchar(60) NOT NULL,
  `defendant_name` varchar(100) NOT NULL,
  `plaintiff_identifier` varchar(60) DEFAULT NULL COMMENT 'Pour civil cases',
  `plaintiff_name` varchar(100) DEFAULT NULL,
  `assigned_prosecutor` varchar(60) DEFAULT NULL,
  `assigned_judge` varchar(60) DEFAULT NULL,
  `assigned_defense` varchar(60) DEFAULT NULL,
  `status` enum('filed','discovery','pre_trial','trial','sentencing','closed','dismissed') DEFAULT 'filed',
  `priority` enum('low','medium','high') DEFAULT 'medium',
  `timeline` text DEFAULT NULL COMMENT 'JSON array of events',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `closed_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `case_number` (`case_number`),
  KEY `defendant` (`defendant_identifier`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Charges (Filing)
CREATE TABLE IF NOT EXISTS `mdt_charges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `case_id` int(11) NOT NULL,
  `charge_code` varchar(50) NOT NULL COMMENT 'PC 187, VC 23152, etc.',
  `charge_title` varchar(255) NOT NULL,
  `charge_class` enum('infraction','misdemeanor','felony') NOT NULL,
  `charge_degree` varchar(50) DEFAULT NULL COMMENT '1st degree, 2nd degree, etc.',
  `enhancements` text DEFAULT NULL COMMENT 'JSON: gang, firearm, etc.',
  `recommended_sentence` text DEFAULT NULL,
  `status` enum('pending','amended','dismissed','convicted','acquitted') DEFAULT 'pending',
  `filed_by` varchar(60) NOT NULL,
  `filed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  KEY `charge_class` (`charge_class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Probable Cause Statements
CREATE TABLE IF NOT EXISTS `mdt_probable_cause` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `case_id` int(11) DEFAULT NULL,
  `warrant_id` int(11) DEFAULT NULL,
  `statement` text NOT NULL,
  `facts` text NOT NULL,
  `supporting_reports` text DEFAULT NULL COMMENT 'JSON array of report IDs',
  `author_identifier` varchar(60) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  KEY `warrant_id` (`warrant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 14: DOJ - AUDIENCES & PROCÉDURES
-- ============================================

-- Subpoenas / Convocations
CREATE TABLE IF NOT EXISTS `mdt_subpoenas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `subpoena_number` varchar(20) NOT NULL,
  `case_id` int(11) NOT NULL,
  `subpoena_type` enum('witness','documents','bodycam','other') NOT NULL,
  `recipient_identifier` varchar(60) DEFAULT NULL,
  `recipient_name` varchar(100) NOT NULL,
  `description` text NOT NULL,
  `hearing_date` date NOT NULL,
  `issued_by` varchar(60) NOT NULL,
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `served` tinyint(1) DEFAULT 0,
  `served_at` timestamp NULL DEFAULT NULL,
  `status` enum('pending','served','complied','quashed') DEFAULT 'pending',
  PRIMARY KEY (`id`),
  UNIQUE KEY `subpoena_number` (`subpoena_number`),
  KEY `case_id` (`case_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Hearings / Audiences
CREATE TABLE IF NOT EXISTS `mdt_hearings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `case_id` int(11) NOT NULL,
  `hearing_type` enum('arraignment','preliminary','pre_trial','trial','sentencing','appeal') NOT NULL,
  `scheduled_date` timestamp NOT NULL,
  `location` varchar(255) DEFAULT NULL COMMENT 'Courtroom',
  `judge_identifier` varchar(60) NOT NULL,
  `prosecutor_identifier` varchar(60) DEFAULT NULL,
  `defense_identifier` varchar(60) DEFAULT NULL,
  `status` enum('scheduled','in_progress','completed','postponed','cancelled') DEFAULT 'scheduled',
  `outcome` text DEFAULT NULL,
  `next_hearing_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  KEY `scheduled_date` (`scheduled_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Hearing Minutes / Minutes d'audience
CREATE TABLE IF NOT EXISTS `mdt_hearing_minutes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `hearing_id` int(11) NOT NULL,
  `minutes` text NOT NULL,
  `decisions_made` text DEFAULT NULL COMMENT 'JSON array',
  `motions_filed` text DEFAULT NULL COMMENT 'JSON array',
  `evidence_admitted` text DEFAULT NULL COMMENT 'JSON array',
  `recorder_identifier` varchar(60) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `hearing_id` (`hearing_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 15: DOJ - BAIL & PLEA DEALS
-- ============================================

-- Bail / Caution
CREATE TABLE IF NOT EXISTS `mdt_bail` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `case_id` int(11) NOT NULL,
  `defendant_identifier` varchar(60) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `conditions` text DEFAULT NULL COMMENT 'no-contact, GPS monitor, etc.',
  `status` enum('set','posted','revoked','exonerated') DEFAULT 'set',
  `posted_at` timestamp NULL DEFAULT NULL,
  `revoked_reason` text DEFAULT NULL,
  `set_by` varchar(60) NOT NULL COMMENT 'Judge identifier',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Plea Deals / Accords
CREATE TABLE IF NOT EXISTS `mdt_plea_deals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `case_id` int(11) NOT NULL,
  `offered_by` varchar(60) NOT NULL COMMENT 'Prosecutor',
  `offered_charges` text NOT NULL COMMENT 'JSON: reduced charges',
  `offered_sentence` text NOT NULL,
  `conditions` text DEFAULT NULL,
  `offer_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expiry_date` date DEFAULT NULL,
  `status` enum('pending','accepted','rejected','withdrawn') DEFAULT 'pending',
  `accepted_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 16: DOJ - JUGEMENTS & PROBATION
-- ============================================

-- Judgments / Jugements
CREATE TABLE IF NOT EXISTS `mdt_judgments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `case_id` int(11) NOT NULL,
  `verdict` enum('guilty','not_guilty','no_contest','dismissed') NOT NULL,
  `sentence_prison_months` int(11) DEFAULT 0,
  `sentence_fine` decimal(10,2) DEFAULT 0.00,
  `sentence_probation_months` int(11) DEFAULT 0,
  `sentence_community_hours` int(11) DEFAULT 0,
  `sentence_details` text DEFAULT NULL,
  `judge_identifier` varchar(60) NOT NULL,
  `judgment_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `appeal_deadline` date DEFAULT NULL,
  `appealed` tinyint(1) DEFAULT 0,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Probation / Parole
CREATE TABLE IF NOT EXISTS `mdt_probation` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `case_id` int(11) NOT NULL,
  `citizen_identifier` varchar(60) NOT NULL,
  `probation_officer` varchar(60) DEFAULT NULL,
  `conditions` text NOT NULL COMMENT 'JSON: curfew, drug tests, etc.',
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `status` enum('active','completed','violated','revoked') DEFAULT 'active',
  `violations` text DEFAULT NULL COMMENT 'JSON array',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  KEY `citizen` (`citizen_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 17: DOJ - MOTIONS & EXPUNGEMENT
-- ============================================

-- Motions
CREATE TABLE IF NOT EXISTS `mdt_motions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `case_id` int(11) NOT NULL,
  `motion_type` enum('suppress_evidence','dismiss','continuance','discovery','other') NOT NULL,
  `filed_by` varchar(60) NOT NULL,
  `filing_party` enum('prosecution','defense') NOT NULL,
  `motion_text` text NOT NULL,
  `filed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `hearing_date` date DEFAULT NULL,
  `status` enum('pending','granted','denied','withdrawn') DEFAULT 'pending',
  `decision_by` varchar(60) DEFAULT NULL,
  `decision_text` text DEFAULT NULL,
  `decided_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Expungement / Scellage
CREATE TABLE IF NOT EXISTS `mdt_expungement` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_identifier` varchar(60) NOT NULL,
  `record_id` int(11) NOT NULL COMMENT 'mdt_criminal_records ID',
  `petition_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `petitioner_identifier` varchar(60) NOT NULL,
  `reason` text NOT NULL,
  `status` enum('pending','granted','denied') DEFAULT 'pending',
  `decided_by` varchar(60) DEFAULT NULL,
  `decided_at` timestamp NULL DEFAULT NULL,
  `decision_reason` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizen` (`citizen_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 18: EMS - DISPATCH & UNITÉS
-- ============================================

-- EMS Calls
CREATE TABLE IF NOT EXISTS `mdt_ems_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `call_number` varchar(20) NOT NULL,
  `priority` enum('routine','urgent','emergency','critical') DEFAULT 'emergency',
  `call_type` varchar(100) NOT NULL COMMENT 'trauma, medical, psych, etc.',
  `location` varchar(255) NOT NULL,
  `caller_info` varchar(255) DEFAULT NULL,
  `chief_complaint` text NOT NULL,
  `units_assigned` text DEFAULT NULL COMMENT 'JSON array',
  `status` enum('pending','dispatched','on_scene','transport','hospital','closed') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `closed_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `call_number` (`call_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- EMS Units
CREATE TABLE IF NOT EXISTS `mdt_ems_units` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unit_number` varchar(20) NOT NULL COMMENT 'Medic-1, Rescue-5, etc.',
  `unit_type` varchar(50) NOT NULL COMMENT 'ambulance, rescue, fire, etc.',
  `paramedic_identifier` varchar(60) NOT NULL,
  `paramedic_name` varchar(100) NOT NULL,
  `partner_identifier` varchar(60) DEFAULT NULL,
  `partner_name` varchar(100) DEFAULT NULL,
  `status` enum('available','busy','on_scene','transport','hospital','maintenance') DEFAULT 'available',
  `current_location` varchar(255) DEFAULT NULL,
  `assigned_call_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `paramedic` (`paramedic_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 19: EMS - PATIENTS & DOSSIERS
-- ============================================

-- Patients
CREATE TABLE IF NOT EXISTS `mdt_patients` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(60) NOT NULL,
  `firstname` varchar(50) NOT NULL,
  `lastname` varchar(50) NOT NULL,
  `dateofbirth` date NOT NULL,
  `sex` varchar(1) DEFAULT 'M',
  `blood_type` varchar(5) DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `emergency_contact_name` varchar(100) DEFAULT NULL,
  `emergency_contact_phone` varchar(20) DEFAULT NULL,
  `photo_url` varchar(500) DEFAULT NULL,
  `medical_flags` text DEFAULT NULL COMMENT 'JSON: allergies, DNR, etc.',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Medical Records
CREATE TABLE IF NOT EXISTS `mdt_medical_records` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `patient_identifier` varchar(60) NOT NULL,
  `record_type` enum('allergy','condition','medication','surgery','immunization') NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `date_recorded` date DEFAULT NULL,
  `recorded_by` varchar(60) NOT NULL,
  `active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `patient` (`patient_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 20: EMS - INTERVENTIONS & RAPPORTS
-- ============================================

-- Vitals / Examens
CREATE TABLE IF NOT EXISTS `mdt_vitals` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `patient_identifier` varchar(60) NOT NULL,
  `epcr_id` int(11) DEFAULT NULL COMMENT 'Lien vers rapport médical',
  `recorded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `blood_pressure_systolic` int(11) DEFAULT NULL,
  `blood_pressure_diastolic` int(11) DEFAULT NULL,
  `heart_rate` int(11) DEFAULT NULL,
  `respiratory_rate` int(11) DEFAULT NULL,
  `oxygen_saturation` int(11) DEFAULT NULL,
  `temperature` decimal(4,1) DEFAULT NULL,
  `gcs_eye` int(11) DEFAULT NULL COMMENT 'Glasgow Coma Scale',
  `gcs_verbal` int(11) DEFAULT NULL,
  `gcs_motor` int(11) DEFAULT NULL,
  `pain_level` int(11) DEFAULT NULL COMMENT '0-10 scale',
  `recorded_by` varchar(60) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `patient` (`patient_identifier`),
  KEY `epcr_id` (`epcr_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ePCR / Rapports médicaux
CREATE TABLE IF NOT EXISTS `mdt_epcr` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_number` varchar(20) NOT NULL,
  `call_id` int(11) DEFAULT NULL,
  `patient_identifier` varchar(60) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `chief_complaint` text NOT NULL,
  `history_present_illness` text DEFAULT NULL,
  `past_medical_history` text DEFAULT NULL,
  `assessment` text NOT NULL,
  `treatment_provided` text DEFAULT NULL,
  `disposition` enum('transport','refuse','treat_release','doa','other') NOT NULL,
  `primary_paramedic` varchar(60) NOT NULL,
  `partner_paramedic` varchar(60) DEFAULT NULL,
  `incident_date` timestamp NOT NULL,
  `status` enum('draft','submitted','reviewed') DEFAULT 'draft',
  `reviewed_by` varchar(60) DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `report_number` (`report_number`),
  KEY `patient` (`patient_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Trauma / Triage
CREATE TABLE IF NOT EXISTS `mdt_trauma` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `epcr_id` int(11) NOT NULL,
  `mechanism_of_injury` text NOT NULL,
  `injuries` text NOT NULL COMMENT 'JSON array',
  `triage_category` enum('green','yellow','red','black') DEFAULT 'yellow',
  `interventions` text DEFAULT NULL COMMENT 'JSON array',
  `severity_score` int(11) DEFAULT NULL COMMENT 'ISS, RTS, etc.',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `epcr_id` (`epcr_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Medication Administered
CREATE TABLE IF NOT EXISTS `mdt_medication` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `epcr_id` int(11) NOT NULL,
  `medication_name` varchar(255) NOT NULL,
  `dose` varchar(100) NOT NULL,
  `route` varchar(50) NOT NULL COMMENT 'IV, PO, IM, etc.',
  `administered_at` timestamp NOT NULL,
  `administered_by` varchar(60) NOT NULL,
  `indication` text DEFAULT NULL,
  `effect` text DEFAULT NULL,
  `contraindications_checked` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `epcr_id` (`epcr_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 21: EMS - TRANSPORT & HOSPITALISATION
-- ============================================

-- Transport
CREATE TABLE IF NOT EXISTS `mdt_transport` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `epcr_id` int(11) NOT NULL,
  `destination` varchar(255) NOT NULL,
  `priority` enum('routine','urgent','emergency','code_3') DEFAULT 'routine',
  `transport_mode` enum('ground','air','walk_in') DEFAULT 'ground',
  `departure_time` timestamp NOT NULL,
  `arrival_time` timestamp NULL DEFAULT NULL,
  `patient_condition_departure` text DEFAULT NULL,
  `patient_condition_arrival` text DEFAULT NULL,
  `refusal` tinyint(1) DEFAULT 0,
  `refusal_signature` varchar(100) DEFAULT NULL,
  `refusal_witness` varchar(60) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `epcr_id` (`epcr_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Hospitalization
CREATE TABLE IF NOT EXISTS `mdt_hospitalizations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `patient_identifier` varchar(60) NOT NULL,
  `admission_date` timestamp NOT NULL,
  `discharge_date` timestamp NULL DEFAULT NULL,
  `department` varchar(100) DEFAULT NULL COMMENT 'ER, ICU, Surgery, etc.',
  `room_number` varchar(20) DEFAULT NULL,
  `admission_reason` text NOT NULL,
  `attending_physician` varchar(100) DEFAULT NULL,
  `discharge_notes` text DEFAULT NULL,
  `status` enum('admitted','discharged','transferred') DEFAULT 'admitted',
  PRIMARY KEY (`id`),
  KEY `patient` (`patient_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 22: EMS - SANTÉ MENTALE & DÉCÈS
-- ============================================

-- Mental Health / 5150
CREATE TABLE IF NOT EXISTS `mdt_mental_health` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `patient_identifier` varchar(60) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `hold_type` varchar(50) DEFAULT '5150' COMMENT 'CA Welfare Code',
  `reason` text NOT NULL,
  `risk_level` enum('low','medium','high','imminent') DEFAULT 'medium',
  `restrictions` text DEFAULT NULL,
  `initiated_by` varchar(60) NOT NULL,
  `initiated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `facility` varchar(255) DEFAULT NULL,
  `duration_hours` int(11) DEFAULT 72,
  `release_date` timestamp NULL DEFAULT NULL,
  `status` enum('active','released','transferred','extended') DEFAULT 'active',
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `patient` (`patient_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Deaths / Morgue
CREATE TABLE IF NOT EXISTS `mdt_deaths` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `deceased_identifier` varchar(60) DEFAULT NULL,
  `deceased_name` varchar(100) NOT NULL,
  `date_of_death` timestamp NOT NULL,
  `location` varchar(255) NOT NULL,
  `cause_of_death_preliminary` text DEFAULT NULL,
  `pronounced_by` varchar(60) NOT NULL,
  `pronounced_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `body_released_to` varchar(100) DEFAULT NULL,
  `release_date` timestamp NULL DEFAULT NULL,
  `autopsy_required` tinyint(1) DEFAULT 0,
  `case_number` varchar(20) DEFAULT NULL COMMENT 'Si investigation criminelle',
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `deceased` (`deceased_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 23: EMS - CERTIFICATS & SUIVI
-- ============================================

-- Certificates
CREATE TABLE IF NOT EXISTS `mdt_certificates` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `certificate_number` varchar(20) NOT NULL,
  `certificate_type` enum('fitness','medical','death','work_clearance') NOT NULL,
  `patient_identifier` varchar(60) DEFAULT NULL,
  `patient_name` varchar(100) NOT NULL,
  `issued_for` varchar(255) NOT NULL,
  `status` enum('fit','unfit','restricted') DEFAULT 'fit',
  `restrictions` text DEFAULT NULL,
  `valid_from` date NOT NULL,
  `valid_until` date DEFAULT NULL,
  `issued_by` varchar(60) NOT NULL,
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `signature` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `certificate_number` (`certificate_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Patient Follow-up
CREATE TABLE IF NOT EXISTS `mdt_patient_followup` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `patient_identifier` varchar(60) NOT NULL,
  `followup_type` enum('appointment','prescription','note','check_in') NOT NULL,
  `description` text NOT NULL,
  `scheduled_date` date DEFAULT NULL,
  `completed` tinyint(1) DEFAULT 0,
  `completed_at` timestamp NULL DEFAULT NULL,
  `created_by` varchar(60) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `patient` (`patient_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 24: EMS - INVENTAIRE & PERSONNEL
-- ============================================

-- Medical Inventory
CREATE TABLE IF NOT EXISTS `mdt_medical_inventory` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `item_name` varchar(255) NOT NULL,
  `item_type` varchar(100) NOT NULL COMMENT 'kit, medication, equipment',
  `quantity` int(11) NOT NULL DEFAULT 0,
  `location` varchar(100) NOT NULL COMMENT 'Station, Unit, etc.',
  `expiry_date` date DEFAULT NULL,
  `controlled_substance` tinyint(1) DEFAULT 0,
  `reorder_level` int(11) DEFAULT NULL,
  `last_restocked` timestamp NULL DEFAULT NULL,
  `last_restocked_by` varchar(60) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `item_type` (`item_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- PARTIE 25: POLICE - TABLES ADDITIONNELLES
-- ============================================

-- Notes citoyens spécifiques police (extension de mdt_notes)
CREATE TABLE IF NOT EXISTS `mdt_citizen_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_identifier` varchar(60) NOT NULL,
  `note_text` text NOT NULL,
  `note_type` enum('info','caution','warning','threat') DEFAULT 'info',
  `is_flagged` tinyint(1) DEFAULT 0 COMMENT '1=note prioritaire/flaggée',
  `author_identifier` varchar(60) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizen` (`citizen_identifier`),
  KEY `flagged` (`is_flagged`),
  KEY `type` (`note_type`),
  KEY `citizen_flagged` (`citizen_identifier`, `is_flagged`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Notes police sur citoyens avec flags et types';

-- ============================================
-- PARTIE 26: SYSTÈME DE PERMISSIONS GRANULAIRES
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
-- PARTIE 27: CONTRÔLE D'ACCÈS AUX DOSSIERS
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
-- PARTIE 28: PARTAGE DE DOSSIERS ENTRE SERVICES
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
-- PARTIE 29: GESTION PATRON / SUPERVISEUR
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
-- PARTIE 30: AJOUT DE CHAMPS CONFIDENTIALITÉ AUX TABLES EXISTANTES
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
-- PARTIE 31: INDEX SUPPLÉMENTAIRES POUR PERFORMANCE
-- ============================================

ALTER TABLE `mdt_citizens` ADD INDEX `flags_search` (`flags`(100));
ALTER TABLE `mdt_reports` ADD INDEX `incident_date` (`incident_date`);
ALTER TABLE `mdt_cases` ADD INDEX `prosecutor` (`assigned_prosecutor`);
ALTER TABLE `mdt_epcr` ADD INDEX `incident_date` (`incident_date`);
ALTER TABLE `mdt_access_logs` ADD INDEX `date_range` (`accessed_at`);
ALTER TABLE `mdt_user_permissions` ADD INDEX `active_perms` (`user_identifier`, `expires_at`);
ALTER TABLE `mdt_share_permissions` ADD INDEX `active_shares` (`shared_with_job`, `expires_at`);

-- ============================================
-- PARTIE 32: VUES SQL POUR RECHERCHE RAPIDE
-- ============================================

-- Vue pour recherche rapide citoyen (avec casier)
CREATE OR REPLACE VIEW `mdt_citizen_search` AS
SELECT
    c.id,
    c.identifier,
    c.firstname,
    c.lastname,
    c.dateofbirth,
    c.phone_number,
    c.address,
    c.flags,
    COUNT(DISTINCT cr.id) as total_arrests,
    GROUP_CONCAT(DISTINCT cr.charge_class) as charge_classes,
    MAX(cr.arrest_date) as last_arrest_date
FROM mdt_citizens c
LEFT JOIN mdt_criminal_records cr ON c.identifier = cr.citizen_identifier AND cr.status = 'active'
GROUP BY c.id;

-- Vue pour dashboard police (appels actifs)
CREATE OR REPLACE VIEW `mdt_active_calls` AS
SELECT
    c.*,
    IFNULL(JSON_LENGTH(c.units_assigned), 0) as units_responding
FROM mdt_calls c
WHERE c.status IN ('pending','dispatched','on_scene')
ORDER BY c.priority DESC, c.created_at ASC;

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
LEFT JOIN mdt_user_permissions up ON up.user_identifier COLLATE utf8mb4_general_ci = u.identifier
    AND up.permission_id = p.id
    AND (up.expires_at IS NULL OR up.expires_at > NOW())
LEFT JOIN mdt_job_permissions jp ON jp.job_name COLLATE utf8mb4_general_ci = u.job
    AND (jp.job_grade IS NULL OR jp.job_grade = u.job_grade)
    AND jp.permission_id = p.id
WHERE u.job IN ('police', 'sheriff', 'doj', 'ambulance', 'fire')
ORDER BY u.identifier, p.permission_category, p.permission_key;

-- ============================================
-- PARTIE 33: DONNÉES INITIALES - NIVEAUX DE CONFIDENTIALITÉ
-- ============================================

INSERT INTO `mdt_confidentiality_levels` (`level_key`, `level_name`, `level_rank`, `description`) VALUES
('public', 'Public', 0, 'Accessible à tous les membres du service'),
('restricted', 'Restreint', 1, 'Accessible uniquement aux grades autorisés'),
('confidential', 'Confidentiel', 2, 'Accès limité - superviseurs uniquement'),
('top_secret', 'Top Secret', 3, 'Accès très limité - command staff uniquement'),
('sealed', 'Scellé', 4, 'Invisible sauf exception judiciaire');

-- ============================================
-- PARTIE 34: PERMISSIONS DE BASE POUR POLICE
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
-- PARTIE 35: PERMISSIONS DE BASE POUR DOJ
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
-- PARTIE 36: PERMISSIONS DE BASE POUR EMS
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
-- PARTIE 37: PERMISSIONS PAR DÉFAUT - POLICE
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
-- Arrests
('police', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'police.arrests.create'), 1)
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- Sheriff (mêmes permissions que police)
INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted)
SELECT 'sheriff', job_grade, permission_id, granted
FROM mdt_job_permissions
WHERE job_name = 'police'
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- ============================================
-- PARTIE 38: PERMISSIONS PAR DÉFAUT - DOJ
-- ============================================

INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted) VALUES
-- Cases
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.cases.view'), 1),
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.cases.create'), 1),
-- Warrants
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.warrants.view'), 1),
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.warrants.create'), 1),
-- Hearings
('doj', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'doj.hearings.view'), 1)
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- ============================================
-- PARTIE 39: PERMISSIONS PAR DÉFAUT - EMS
-- ============================================

INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted) VALUES
-- Dispatch
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.dispatch.view'), 1),
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.dispatch.create'), 1),
-- Patients
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.patients.view'), 1),
-- ePCR
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.epcr.create'), 1),
('ambulance', NULL, (SELECT id FROM mdt_permissions_list WHERE permission_key = 'ems.epcr.view'), 1)
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- ============================================
-- FIN DE L'INSTALLATION MDT COMPLÈTE
-- ============================================

SELECT '✅ Installation MDT complète terminée!' as status;
SELECT COUNT(*) as total_tables FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name LIKE 'mdt_%';
SELECT COUNT(*) as total_permissions FROM mdt_permissions_list;
SELECT COUNT(*) as total_job_permissions FROM mdt_job_permissions;
