-- ============================================
-- POLICE MDT - INSTALLATION COMPLÈTE
-- ============================================
-- Système MDT Police Ultra-Complet
-- Préfixe: zx_
-- Utilise directement: users, owned_vehicles (ESX)
-- ============================================

SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- TABLE 1: APPELS CAD / 911
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `call_number` varchar(20) NOT NULL COMMENT 'Format: YYMMDD-XXX',
  `priority` enum('low','medium','high','critical') DEFAULT 'medium',
  `call_type` varchar(100) NOT NULL COMMENT '10-codes, traffic stop, etc.',
  `location` varchar(255) NOT NULL,
  `postal` varchar(10) DEFAULT NULL,
  `caller_name` varchar(100) DEFAULT NULL,
  `caller_phone` varchar(20) DEFAULT NULL,
  `description` text NOT NULL,
  `units_assigned` longtext DEFAULT NULL COMMENT 'JSON array of unit identifiers',
  `status` enum('pending','dispatched','on_scene','closed','cancelled') DEFAULT 'pending',
  `created_by` varchar(60) DEFAULT NULL COMMENT 'Qui a créé (NULL = 911)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `dispatched_at` timestamp NULL DEFAULT NULL,
  `closed_at` timestamp NULL DEFAULT NULL,
  `closed_by` varchar(60) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `call_number` (`call_number`),
  KEY `status_priority` (`status`, `priority`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Appels CAD/911';

-- ============================================
-- TABLE 2: RAPPORTS DE POLICE
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `report_number` varchar(20) NOT NULL,
  `report_type` varchar(50) NOT NULL COMMENT 'incident, traffic_stop, welfare_check, etc.',
  `title` varchar(255) NOT NULL,
  `location` varchar(255) NOT NULL,
  `postal` varchar(10) DEFAULT NULL,
  `incident_date` timestamp NOT NULL,
  `primary_officer` varchar(60) NOT NULL,
  `primary_officer_name` varchar(100) NOT NULL,
  `assisting_officers` longtext DEFAULT NULL COMMENT 'JSON array',
  `involved_citizens` longtext DEFAULT NULL COMMENT 'JSON array of identifiers',
  `involved_vehicles` longtext DEFAULT NULL COMMENT 'JSON array of plates',
  `narrative` text NOT NULL,
  `status` enum('draft','submitted','approved','rejected') DEFAULT 'draft',
  `approved_by` varchar(60) DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `report_number` (`report_number`),
  KEY `primary_officer` (`primary_officer`),
  KEY `status` (`status`),
  KEY `incident_date` (`incident_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Rapports de police';

-- ============================================
-- TABLE 3: ARRESTATIONS
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_arrests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `arrest_number` varchar(20) NOT NULL,
  `citizen_identifier` varchar(60) NOT NULL,
  `citizen_name` varchar(100) NOT NULL,
  `charges` longtext NOT NULL COMMENT 'JSON array of charge codes',
  `total_fine` decimal(10,2) DEFAULT 0.00,
  `total_jail_time` int(11) DEFAULT 0 COMMENT 'Minutes',
  `location` varchar(255) NOT NULL,
  `postal` varchar(10) DEFAULT NULL,
  `arrest_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `arresting_officer` varchar(60) NOT NULL,
  `arresting_officer_name` varchar(100) NOT NULL,
  `assisting_officers` longtext DEFAULT NULL COMMENT 'JSON array',
  `miranda_read` tinyint(1) DEFAULT 0,
  `processed` tinyint(1) DEFAULT 0 COMMENT 'Envoyé en prison',
  `processed_at` timestamp NULL DEFAULT NULL,
  `booking_photo` varchar(500) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `arrest_number` (`arrest_number`),
  KEY `citizen` (`citizen_identifier`),
  KEY `officer` (`arresting_officer`),
  KEY `arrest_date` (`arrest_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Arrestations';

-- ============================================
-- TABLE 4: CITATIONS / AMENDES
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_citations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citation_number` varchar(20) NOT NULL,
  `citizen_identifier` varchar(60) NOT NULL,
  `citizen_name` varchar(100) NOT NULL,
  `violation_code` varchar(50) NOT NULL COMMENT 'VC 21461, PC 415, etc.',
  `violation_description` varchar(255) NOT NULL,
  `fine_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `points` int(11) DEFAULT 0,
  `location` varchar(255) DEFAULT NULL,
  `postal` varchar(10) DEFAULT NULL,
  `vehicle_plate` varchar(20) DEFAULT NULL,
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
  KEY `payment_status` (`payment_status`),
  KEY `issued_by` (`issued_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Citations et amendes';

-- ============================================
-- TABLE 5: BOLO (BE ON LOOKOUT)
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_bolo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bolo_type` enum('person','vehicle') NOT NULL,
  `subject` varchar(255) NOT NULL COMMENT 'Name or vehicle description',
  `description` text NOT NULL,
  `last_seen_location` varchar(255) DEFAULT NULL,
  `last_seen_postal` varchar(10) DEFAULT NULL,
  `priority` enum('low','medium','high','critical') DEFAULT 'medium',
  `danger_level` enum('low','medium','high','armed_dangerous') DEFAULT 'medium',
  `plate` varchar(20) DEFAULT NULL COMMENT 'Si véhicule',
  `status` enum('active','closed') DEFAULT 'active',
  `issued_by` varchar(60) NOT NULL,
  `issued_by_name` varchar(100) NOT NULL,
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `closed_by` varchar(60) DEFAULT NULL,
  `closed_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `status` (`status`),
  KEY `priority` (`priority`),
  KEY `bolo_type` (`bolo_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='BOLO - Be On Lookout';

-- ============================================
-- TABLE 6: MANDATS (WARRANTS)
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_warrants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `warrant_number` varchar(20) NOT NULL,
  `warrant_type` enum('arrest','search','bench') NOT NULL,
  `citizen_identifier` varchar(60) DEFAULT NULL,
  `citizen_name` varchar(100) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL COMMENT 'Pour search warrant',
  `charges` longtext DEFAULT NULL COMMENT 'JSON array',
  `probable_cause` text NOT NULL,
  `issued_by` varchar(60) NOT NULL COMMENT 'Judge identifier',
  `issued_by_name` varchar(100) NOT NULL,
  `approved_by` varchar(60) DEFAULT NULL COMMENT 'Superviseur',
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expiry_date` date DEFAULT NULL,
  `status` enum('pending','active','executed','expired','recalled') DEFAULT 'pending',
  `executed_by` varchar(60) DEFAULT NULL,
  `executed_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `warrant_number` (`warrant_number`),
  KEY `citizen` (`citizen_identifier`),
  KEY `status` (`status`),
  KEY `warrant_type` (`warrant_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Mandats';

-- ============================================
-- TABLE 7: PERSONNES RECHERCHÉES
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_wanted` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_identifier` varchar(60) NOT NULL,
  `citizen_name` varchar(100) NOT NULL,
  `reason` text NOT NULL,
  `charges` longtext DEFAULT NULL COMMENT 'JSON array',
  `priority` enum('low','medium','high') DEFAULT 'medium',
  `armed` tinyint(1) DEFAULT 0,
  `dangerous` tinyint(1) DEFAULT 0,
  `last_known_location` varchar(255) DEFAULT NULL,
  `warrant_id` int(11) DEFAULT NULL COMMENT 'Lien vers zx_police_warrants',
  `status` enum('active','arrested','cleared') DEFAULT 'active',
  `issued_by` varchar(60) NOT NULL,
  `issued_by_name` varchar(100) NOT NULL,
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cleared_by` varchar(60) DEFAULT NULL,
  `cleared_at` timestamp NULL DEFAULT NULL,
  `mugshot` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizen` (`citizen_identifier`),
  KEY `status` (`status`),
  KEY `warrant_id` (`warrant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Personnes recherchées';

-- ============================================
-- TABLE 8: PREUVES
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_evidence` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `evidence_number` varchar(20) NOT NULL,
  `report_id` int(11) DEFAULT NULL COMMENT 'Lien vers zx_police_reports',
  `arrest_id` int(11) DEFAULT NULL COMMENT 'Lien vers zx_police_arrests',
  `item_type` varchar(100) NOT NULL COMMENT 'weapon, drugs, documents, etc.',
  `item_description` text NOT NULL,
  `quantity` int(11) DEFAULT 1,
  `seized_from_identifier` varchar(60) DEFAULT NULL,
  `seized_from_name` varchar(100) DEFAULT NULL,
  `seized_location` varchar(255) DEFAULT NULL,
  `seized_postal` varchar(10) DEFAULT NULL,
  `seized_by` varchar(60) NOT NULL,
  `seized_by_name` varchar(100) NOT NULL,
  `seized_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `storage_location` varchar(100) DEFAULT 'Evidence Locker',
  `chain_of_custody` longtext DEFAULT NULL COMMENT 'JSON array: timestamps, handlers',
  `status` enum('seized','stored','released','destroyed') DEFAULT 'seized',
  `released_to` varchar(100) DEFAULT NULL,
  `released_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `evidence_number` (`evidence_number`),
  KEY `report_id` (`report_id`),
  KEY `arrest_id` (`arrest_id`),
  KEY `seized_by` (`seized_by`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Preuves saisies';

-- ============================================
-- TABLE 9: NOTES / INTEL
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_identifier` varchar(60) NOT NULL,
  `note_text` text NOT NULL,
  `note_type` enum('info','caution','warning','threat','gang','intel') DEFAULT 'info',
  `is_flagged` tinyint(1) DEFAULT 0 COMMENT 'Note importante',
  `is_confidential` tinyint(1) DEFAULT 0 COMMENT 'Visible superviseurs uniquement',
  `author_identifier` varchar(60) NOT NULL,
  `author_name` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizen` (`citizen_identifier`),
  KEY `flagged` (`is_flagged`),
  KEY `type` (`note_type`),
  KEY `author` (`author_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Notes et renseignements';

-- ============================================
-- TABLE 10: PPA (PERMIS PORT D'ARME)
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_ppa` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `permit_number` varchar(20) NOT NULL,
  `citizen_identifier` varchar(60) NOT NULL,
  `citizen_name` varchar(100) NOT NULL,
  `permit_type` enum('PPA','CCW') DEFAULT 'PPA' COMMENT 'Port d\'arme / Concealed Carry',
  `permit_class` varchar(50) DEFAULT NULL COMMENT 'Class 1, 2, 3',
  `authorized_weapons` longtext DEFAULT NULL COMMENT 'JSON: types d\'armes autorisées',
  `restrictions` text DEFAULT NULL,
  `status` enum('pending','active','suspended','revoked','expired') DEFAULT 'pending',
  `issued_date` date DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  `issued_by` varchar(60) NOT NULL,
  `issued_by_name` varchar(100) NOT NULL,
  `revoked_by` varchar(60) DEFAULT NULL,
  `revoked_at` timestamp NULL DEFAULT NULL,
  `revocation_reason` text DEFAULT NULL,
  `background_check_date` date DEFAULT NULL,
  `training_completed` tinyint(1) DEFAULT 0,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `permit_number` (`permit_number`),
  KEY `citizen` (`citizen_identifier`),
  KEY `status` (`status`),
  KEY `expiry` (`expiry_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Permis de port d\'arme';

-- ============================================
-- TABLE 11: PPA LOURD (ARMES LOURDES/AUTO)
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_ppa_heavy` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `permit_number` varchar(20) NOT NULL,
  `citizen_identifier` varchar(60) NOT NULL,
  `citizen_name` varchar(100) NOT NULL,
  `weapon_category` enum('automatic','heavy','explosive','special') NOT NULL,
  `specific_weapons` longtext NOT NULL COMMENT 'JSON: liste précise des armes autorisées',
  `justification` text NOT NULL COMMENT 'Raison de la demande',
  `status` enum('pending','active','suspended','revoked','expired') DEFAULT 'pending',
  `issued_date` date DEFAULT NULL,
  `expiry_date` date DEFAULT NULL,
  `issued_by` varchar(60) NOT NULL COMMENT 'DOJ/Sheriff/Chief',
  `issued_by_name` varchar(100) NOT NULL,
  `approved_by_judge` varchar(60) DEFAULT NULL,
  `revoked_by` varchar(60) DEFAULT NULL,
  `revoked_at` timestamp NULL DEFAULT NULL,
  `revocation_reason` text DEFAULT NULL,
  `conditions` text DEFAULT NULL COMMENT 'Conditions spéciales',
  `background_check_level` enum('standard','enhanced','top_secret') DEFAULT 'enhanced',
  `yearly_review_required` tinyint(1) DEFAULT 1,
  `last_review_date` date DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `permit_number` (`permit_number`),
  KEY `citizen` (`citizen_identifier`),
  KEY `status` (`status`),
  KEY `category` (`weapon_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='PPA Lourd - Armes automatiques/lourdes';

-- ============================================
-- TABLE 12: VÉHICULES VOLÉS
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_stolen_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(20) NOT NULL,
  `vehicle_model` varchar(100) DEFAULT NULL,
  `vehicle_hash` varchar(100) DEFAULT NULL,
  `owner_identifier` varchar(60) DEFAULT NULL,
  `owner_name` varchar(100) DEFAULT NULL,
  `stolen_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `stolen_location` varchar(255) DEFAULT NULL,
  `stolen_postal` varchar(10) DEFAULT NULL,
  `reported_by` varchar(60) DEFAULT NULL COMMENT 'Qui a déclaré le vol',
  `report_id` int(11) DEFAULT NULL COMMENT 'Lien vers rapport',
  `status` enum('stolen','recovered','destroyed') DEFAULT 'stolen',
  `recovered_date` timestamp NULL DEFAULT NULL,
  `recovered_by` varchar(60) DEFAULT NULL,
  `recovered_location` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `plate` (`plate`),
  KEY `status` (`status`),
  KEY `owner` (`owner_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Véhicules volés';

-- ============================================
-- TABLE 13: CHARGES PÉNALES (LISTE)
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_charges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `charge_code` varchar(50) NOT NULL COMMENT 'PC 187, VC 23152, etc.',
  `charge_title` varchar(255) NOT NULL,
  `charge_category` enum('traffic','misdemeanor','felony') NOT NULL,
  `charge_class` varchar(50) DEFAULT NULL COMMENT '1st degree, 2nd degree',
  `fine_amount` decimal(10,2) DEFAULT 0.00,
  `jail_time` int(11) DEFAULT 0 COMMENT 'Minutes',
  `points` int(11) DEFAULT 0 COMMENT 'Points permis',
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `charge_code` (`charge_code`),
  KEY `category` (`charge_category`),
  KEY `active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Liste des charges pénales';

-- ============================================
-- TABLE 14: UNITÉS / PATROUILLES
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_units` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `unit_number` varchar(20) NOT NULL COMMENT 'Ex: 1-Adam-12',
  `unit_type` varchar(50) NOT NULL COMMENT 'patrol, traffic, k9, swat, detective',
  `officer_identifier` varchar(60) NOT NULL,
  `officer_name` varchar(100) NOT NULL,
  `partner_identifier` varchar(60) DEFAULT NULL,
  `partner_name` varchar(100) DEFAULT NULL,
  `status` enum('10-8','10-7','10-6','10-97','10-23','code-6') DEFAULT '10-7' COMMENT '10-8=available',
  `status_text` varchar(100) DEFAULT NULL COMMENT 'Texte custom',
  `current_location` varchar(255) DEFAULT NULL,
  `current_postal` varchar(10) DEFAULT NULL,
  `assigned_call_id` int(11) DEFAULT NULL,
  `vehicle_plate` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `officer` (`officer_identifier`),
  KEY `status` (`status`),
  KEY `unit_type` (`unit_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Unités et patrouilles actives';

-- ============================================
-- TABLE 15: PERSONNEL POLICE
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_personnel` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `officer_identifier` varchar(60) NOT NULL,
  `officer_name` varchar(100) NOT NULL,
  `badge_number` varchar(20) DEFAULT NULL,
  `rank` varchar(50) DEFAULT NULL,
  `division` varchar(50) DEFAULT NULL COMMENT 'patrol, traffic, detective, K9, SWAT',
  `certifications` longtext DEFAULT NULL COMMENT 'JSON: taser, k9, swat, detective',
  `hire_date` date DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `emergency_contact` varchar(255) DEFAULT NULL,
  `performance_rating` decimal(3,2) DEFAULT NULL COMMENT '0.00-5.00',
  `commendations` int(11) DEFAULT 0,
  `complaints` int(11) DEFAULT 0,
  `disciplinary_actions` longtext DEFAULT NULL COMMENT 'JSON array',
  `status` enum('active','leave','suspended','terminated') DEFAULT 'active',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `officer_identifier` (`officer_identifier`),
  UNIQUE KEY `badge_number` (`badge_number`),
  KEY `status` (`status`),
  KEY `division` (`division`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Personnel police';

-- ============================================
-- TABLE 16: INTEL / RENSEIGNEMENTS
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_intel` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `intel_type` enum('gang','organized_crime','drug_trafficking','terrorism','other') NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `related_citizens` longtext DEFAULT NULL COMMENT 'JSON: array of identifiers',
  `related_locations` text DEFAULT NULL,
  `threat_level` enum('low','medium','high','critical') DEFAULT 'medium',
  `confidentiality` enum('public','restricted','confidential','top_secret') DEFAULT 'restricted',
  `source` varchar(255) DEFAULT NULL COMMENT 'Informateur, surveillance, etc.',
  `source_reliability` enum('low','medium','high') DEFAULT 'medium',
  `verified` tinyint(1) DEFAULT 0,
  `verified_by` varchar(60) DEFAULT NULL,
  `created_by` varchar(60) NOT NULL,
  `created_by_name` varchar(100) NOT NULL,
  `last_updated_by` varchar(60) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `intel_type` (`intel_type`),
  KEY `threat_level` (`threat_level`),
  KEY `confidentiality` (`confidentiality`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Renseignements et intelligence';

-- ============================================
-- TABLE 17: WEBHOOKS DISCORD
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_webhooks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `webhook_name` varchar(100) NOT NULL COMMENT 'arrests, reports, bolo, etc.',
  `webhook_url` varchar(500) NOT NULL,
  `webhook_color` int(11) DEFAULT NULL COMMENT 'Couleur embed Discord',
  `enabled` tinyint(1) DEFAULT 1,
  `events` longtext DEFAULT NULL COMMENT 'JSON: liste des events à logger',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `webhook_name` (`webhook_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Configuration webhooks Discord';

-- ============================================
-- TABLE 18: LOGS D'ACTIVITÉ (POUR WEBHOOKS)
-- ============================================
CREATE TABLE IF NOT EXISTS `zx_police_activity_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `action_type` varchar(50) NOT NULL COMMENT 'arrest, report, bolo, citation, etc.',
  `action_data` longtext NOT NULL COMMENT 'JSON: détails complets',
  `user_identifier` varchar(60) NOT NULL,
  `user_name` varchar(100) NOT NULL,
  `user_job` varchar(50) NOT NULL,
  `webhook_sent` tinyint(1) DEFAULT 0,
  `webhook_sent_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `action_type` (`action_type`),
  KEY `user_identifier` (`user_identifier`),
  KEY `webhook_sent` (`webhook_sent`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Logs d\'activité pour webhooks';

-- ============================================
-- DONNÉES INITIALES: CHARGES PÉNALES
-- ============================================
INSERT INTO `zx_police_charges` (`charge_code`, `charge_title`, `charge_category`, `charge_class`, `fine_amount`, `jail_time`, `points`, `description`) VALUES
-- Traffic
('VC-001', 'Excès de vitesse (léger)', 'traffic', 'Infraction', 150.00, 0, 1, 'Dépassement de 10-20 km/h'),
('VC-002', 'Excès de vitesse (moyen)', 'traffic', 'Infraction', 300.00, 0, 2, 'Dépassement de 20-40 km/h'),
('VC-003', 'Excès de vitesse (grave)', 'traffic', 'Infraction', 500.00, 5, 3, 'Dépassement de plus de 40 km/h'),
('VC-004', 'Conduite dangereuse', 'traffic', 'Misdemeanor', 750.00, 10, 4, 'Mise en danger d\'autrui'),
('VC-005', 'Feu rouge grillé', 'traffic', 'Infraction', 200.00, 0, 2, 'Non-respect du feu rouge'),
('VC-006', 'Sens interdit', 'traffic', 'Infraction', 250.00, 0, 2, 'Circulation en sens interdit'),
('VC-007', 'Conduite sans permis', 'traffic', 'Misdemeanor', 1000.00, 15, 0, 'Absence de permis de conduire valide'),
('VC-008', 'Délit de fuite', 'traffic', 'Misdemeanor', 2000.00, 30, 6, 'Fuite après accident'),
('VC-009', 'Conduite en état d\'ivresse (DUI)', 'traffic', 'Misdemeanor', 3000.00, 45, 8, 'Alcoolémie supérieure à la limite'),
('VC-010', 'Course de rue', 'traffic', 'Misdemeanor', 2500.00, 40, 6, 'Participation à une course illégale'),

-- Misdemeanors
('PC-001', 'Trouble à l\'ordre public', 'misdemeanor', 'Misdemeanor', 500.00, 10, 0, 'Comportement perturbateur'),
('PC-002', 'Résistance à l\'arrestation', 'misdemeanor', 'Misdemeanor', 1500.00, 20, 0, 'Opposition physique à l\'arrestation'),
('PC-003', 'Outrage à agent', 'misdemeanor', 'Misdemeanor', 1000.00, 15, 0, 'Insultes/menaces envers un agent'),
('PC-004', 'Port d\'arme illégal', 'misdemeanor', 'Misdemeanor', 2000.00, 25, 0, 'Port d\'arme sans PPA'),
('PC-005', 'Possession de drogue (usage)', 'misdemeanor', 'Misdemeanor', 1500.00, 20, 0, 'Détention de stupéfiants pour usage'),
('PC-006', 'Vandalisme', 'misdemeanor', 'Misdemeanor', 1200.00, 15, 0, 'Dégradation de biens'),
('PC-007', 'Intrusion', 'misdemeanor', 'Misdemeanor', 800.00, 10, 0, 'Entrée non autorisée'),
('PC-008', 'Vol simple', 'misdemeanor', 'Misdemeanor', 1500.00, 20, 0, 'Vol de biens < 5000$'),
('PC-009', 'Agression simple', 'misdemeanor', 'Misdemeanor', 2000.00, 25, 0, 'Violence sans arme'),
('PC-010', 'Menaces', 'misdemeanor', 'Misdemeanor', 1000.00, 15, 0, 'Menaces de violence'),

-- Felonies
('PC-101', 'Vol qualifié', 'felony', '3rd Degree', 5000.00, 60, 0, 'Vol avec violence/arme'),
('PC-102', 'Cambriolage', 'felony', '3rd Degree', 4000.00, 50, 0, 'Entrée par effraction'),
('PC-103', 'Agression avec arme', 'felony', '2nd Degree', 6000.00, 75, 0, 'Agression armée'),
('PC-104', 'Enlèvement', 'felony', '1st Degree', 10000.00, 120, 0, 'Séquestration de personne'),
('PC-105', 'Trafic de drogue', 'felony', '2nd Degree', 8000.00, 90, 0, 'Vente/distribution de stupéfiants'),
('PC-106', 'Braquage de banque', 'felony', '1st Degree', 15000.00, 150, 0, 'Hold-up établissement bancaire'),
('PC-107', 'Meurtre', 'felony', '1st Degree', 25000.00, 300, 0, 'Homicide volontaire'),
('PC-108', 'Tentative de meurtre', 'felony', '1st Degree', 20000.00, 240, 0, 'Tentative d\'homicide'),
('PC-109', 'Terrorisme', 'felony', '1st Degree', 50000.00, 500, 0, 'Actes terroristes'),
('PC-110', 'Trahison', 'felony', '1st Degree', 30000.00, 400, 0, 'Trahison envers l\'État'),
('PC-111', 'Corruption d\'agent public', 'felony', '2nd Degree', 10000.00, 120, 0, 'Corruption de fonctionnaire'),
('PC-112', 'Évasion', 'felony', '2nd Degree', 7500.00, 90, 0, 'Évasion de prison'),
('PC-113', 'Prise d\'otage', 'felony', '1st Degree', 20000.00, 200, 0, 'Séquestration avec menaces'),
('PC-114', 'Vol de véhicule', 'felony', '3rd Degree', 4500.00, 55, 0, 'Vol de véhicule à moteur'),
('PC-115', 'Recel', 'felony', '3rd Degree', 3500.00, 40, 0, 'Recel de biens volés')
ON DUPLICATE KEY UPDATE charge_title = VALUES(charge_title);

-- ============================================
-- WEBHOOKS PAR DÉFAUT
-- ============================================
INSERT INTO `zx_police_webhooks` (`webhook_name`, `webhook_url`, `webhook_color`, `enabled`, `events`) VALUES
('arrests', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 16711680, 0, '["arrest_created","arrest_processed"]'),
('reports', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 3447003, 0, '["report_created","report_approved"]'),
('bolo', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 16776960, 0, '["bolo_created","bolo_closed"]'),
('citations', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 16744272, 0, '["citation_issued"]'),
('warrants', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 10038562, 0, '["warrant_issued","warrant_executed"]'),
('evidence', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 9807270, 0, '["evidence_logged","evidence_released"]'),
('ppa', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 5763719, 0, '["ppa_issued","ppa_revoked"]'),
('admin', 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE', 15158332, 0, '["all"]')
ON DUPLICATE KEY UPDATE webhook_name = VALUES(webhook_name);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- CONFIRMATION
-- ============================================
SELECT '✅ Installation Police MDT terminée!' as status;
SELECT COUNT(*) as total_tables FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name LIKE 'zx_police_%';
SELECT COUNT(*) as total_charges FROM zx_police_charges;
SELECT COUNT(*) as total_webhooks FROM zx_police_webhooks;
