-- ============================================
-- INSTALLATION COMPLÈTE MDT
-- ============================================
-- Ce fichier contient TOUT le nécessaire pour le MDT
-- À exécuter APRÈS mdt_schema.sql et mdt_permissions.sql

-- ============================================
-- TABLES SUPPLÉMENTAIRES POUR IMMERSION
-- ============================================

-- Citations (Tickets/Amendes)
CREATE TABLE IF NOT EXISTS `mdt_citations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citation_number` varchar(50) NOT NULL,
  `citizen_identifier` varchar(60) NOT NULL,
  `citizen_name` varchar(255) NOT NULL,
  `issued_by` varchar(60) NOT NULL,
  `issued_by_name` varchar(255) NOT NULL,
  `violation_code` varchar(50) NOT NULL,
  `violation_description` text NOT NULL,
  `fine_amount` decimal(10,2) NOT NULL,
  `location` varchar(255) NOT NULL,
  `vehicle_plate` varchar(20) DEFAULT NULL,
  `status` enum('pending','paid','overdue','dismissed') DEFAULT 'pending',
  `notes` text DEFAULT NULL,
  `issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `due_date` timestamp NULL DEFAULT NULL,
  `paid_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citation_number` (`citation_number`),
  KEY `citizen_identifier` (`citizen_identifier`),
  KEY `status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Notes sur les citoyens (Officers observations)
CREATE TABLE IF NOT EXISTS `mdt_citizen_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_identifier` varchar(60) NOT NULL,
  `note_type` enum('caution','info','warning','threat') DEFAULT 'info',
  `note_text` text NOT NULL,
  `created_by` varchar(60) NOT NULL,
  `created_by_name` varchar(255) NOT NULL,
  `is_flagged` tinyint(1) DEFAULT 0 COMMENT 'Important flag',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizen_identifier` (`citizen_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Codes 10 / Status Officers
CREATE TABLE IF NOT EXISTS `mdt_officer_status` (
  `identifier` varchar(60) NOT NULL,
  `officer_name` varchar(255) NOT NULL,
  `badge_number` varchar(20) DEFAULT NULL,
  `unit_number` varchar(20) DEFAULT NULL,
  `current_status` varchar(20) DEFAULT '10-7' COMMENT '10-7=Off duty, 10-8=On duty, 10-6=Busy, 10-97=Arrived',
  `status_since` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `current_call_id` int(11) DEFAULT NULL,
  `last_location` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Charges pénales (Criminal Charges)
CREATE TABLE IF NOT EXISTS `mdt_charges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `charge_code` varchar(50) NOT NULL,
  `charge_name` varchar(255) NOT NULL,
  `category` enum('felony','misdemeanor','infraction','traffic') NOT NULL,
  `description` text DEFAULT NULL,
  `min_fine` decimal(10,2) DEFAULT 0,
  `max_fine` decimal(10,2) DEFAULT 0,
  `jail_time` int(11) DEFAULT 0 COMMENT 'En mois',
  `is_active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`),
  UNIQUE KEY `charge_code` (`charge_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Casier judiciaire (Criminal Record Entries)
CREATE TABLE IF NOT EXISTS `mdt_criminal_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen_identifier` varchar(60) NOT NULL,
  `charge_id` int(11) NOT NULL,
  `arrest_id` int(11) DEFAULT NULL,
  `incident_date` timestamp NOT NULL,
  `officer_identifier` varchar(60) NOT NULL,
  `conviction_status` enum('arrested','charged','convicted','dismissed') DEFAULT 'arrested',
  `sentence_months` int(11) DEFAULT 0,
  `fine_amount` decimal(10,2) DEFAULT 0,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `citizen_identifier` (`citizen_identifier`),
  KEY `charge_id` (`charge_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- DONNÉES D'EXEMPLE / SEED DATA
-- ============================================

-- Charges pénales standards
INSERT INTO `mdt_charges` (charge_code, charge_name, category, description, min_fine, max_fine, jail_time) VALUES
-- Felonies
('PC-187', 'Meurtre au 1er degré', 'felony', 'Homicide avec préméditation', 0, 0, 300),
('PC-211', 'Vol à main armée', 'felony', 'Vol avec arme et menaces', 15000, 30000, 120),
('PC-215', 'Tentative de meurtre', 'felony', 'Tentative d\'homicide', 10000, 25000, 180),
('PC-487', 'Grand vol', 'felony', 'Vol de biens >$950', 5000, 15000, 60),
('PC-459', 'Cambriolage', 'felony', 'Entrée illégale avec intention de vol', 8000, 20000, 90),
('HS-11350', 'Possession drogue (felony)', 'felony', 'Possession substances contrôlées', 10000, 25000, 120),
('HS-11351', 'Possession avec intention de vendre', 'felony', 'Détention pour revente', 20000, 50000, 180),
('PC-245', 'Agression avec arme mortelle', 'felony', 'Assault with deadly weapon', 10000, 30000, 150),
('PC-246', 'Tirs sur habitation/véhicule', 'felony', 'Shooting at dwelling/vehicle', 15000, 40000, 200),

-- Misdemeanors
('PC-242', 'Coups et blessures', 'misdemeanor', 'Battery / Physical assault', 2000, 5000, 12),
('PC-148', 'Résistance à l\'arrestation', 'misdemeanor', 'Resisting arrest', 3000, 7000, 24),
('PC-594', 'Vandalisme', 'misdemeanor', 'Destruction de propriété', 1500, 5000, 6),
('PC-647', 'Ivresse publique', 'misdemeanor', 'Public intoxication', 500, 1500, 0),
('PC-415', 'Trouble à l\'ordre public', 'misdemeanor', 'Disturbing the peace', 1000, 3000, 3),
('PC-240', 'Tentative d\'agression', 'misdemeanor', 'Assault', 1500, 4000, 6),
('HS-11364', 'Possession paraphernalia', 'misdemeanor', 'Drug paraphernalia', 1000, 2500, 3),

-- Traffic
('VC-22350', 'Excès de vitesse', 'traffic', 'Speeding violation', 200, 500, 0),
('VC-23152', 'Conduite en état d\'ivresse', 'traffic', 'DUI', 5000, 10000, 12),
('VC-20001', 'Délit de fuite', 'traffic', 'Hit and run', 3000, 8000, 6),
('VC-2800', 'Refus d\'obtempérer', 'traffic', 'Evading police', 5000, 15000, 24),
('VC-14601', 'Conduite sans permis', 'traffic', 'Driving without license', 1500, 3000, 3),
('VC-23103', 'Conduite imprudente', 'traffic', 'Reckless driving', 1000, 2500, 0),
('VC-21453', 'Griller un feu rouge', 'traffic', 'Red light violation', 250, 500, 0),
('VC-22107', 'Virage dangereux', 'traffic', 'Unsafe turn', 200, 400, 0),

-- Infractions
('INF-001', 'Stationnement interdit', 'infraction', 'Illegal parking', 150, 300, 0),
('INF-002', 'Pas de ceinture', 'infraction', 'Seatbelt violation', 100, 200, 0),
('INF-003', 'Téléphone au volant', 'infraction', 'Phone while driving', 200, 350, 0),
('INF-004', 'Stop non respecté', 'infraction', 'Failure to stop', 250, 400, 0)
ON DUPLICATE KEY UPDATE charge_name = VALUES(charge_name);

-- Status codes 10 (Police radio codes)
INSERT INTO `mdt_officer_status` (identifier, officer_name, badge_number, unit_number, current_status, last_location) VALUES
('example_officer_1', 'Officer John Smith', '1001', 'Unit 1-A-1', '10-8', 'Mission Row PD'),
('example_officer_2', 'Officer Jane Doe', '1002', 'Unit 1-A-2', '10-8', 'Vespucci PD'),
('example_officer_3', 'Sergeant Mike Brown', '1010', 'Unit 1-S-1', '10-6', 'Legion Square')
ON DUPLICATE KEY UPDATE officer_name = VALUES(officer_name);

-- Exemples de notes (pour immersion)
INSERT INTO `mdt_citizen_notes` (citizen_identifier, note_type, note_text, created_by, created_by_name, is_flagged) VALUES
('steam:example1', 'caution', 'Suspect connu pour résistance lors d\'arrestations. Approcher avec prudence.', 'officer_badge_1001', 'Officer Smith', 1),
('steam:example2', 'info', 'A coopéré lors du dernier contrôle. Propriétaire d\'un véhicule volé récupéré.', 'officer_badge_1002', 'Officer Doe', 0),
('steam:example3', 'warning', 'Multiples interpellations pour ivresse publique. Peut être agressif.', 'officer_badge_1010', 'Sgt. Brown', 1)
ON DUPLICATE KEY UPDATE note_text = VALUES(note_text);

-- Exemples de citations
INSERT INTO `mdt_citations` (citation_number, citizen_identifier, citizen_name, issued_by, issued_by_name, violation_code, violation_description, fine_amount, location, vehicle_plate, status, due_date) VALUES
('CIT-250101-001', 'steam:example1', 'John Doe', 'officer_1001', 'Officer Smith', 'VC-22350', 'Excès de vitesse (95 mph en zone 65)', 450.00, 'Great Ocean Highway', 'ABC123', 'pending', DATE_ADD(NOW(), INTERVAL 30 DAY)),
('CIT-250101-002', 'steam:example2', 'Jane Miller', 'officer_1002', 'Officer Doe', 'VC-21453', 'Griller un feu rouge', 350.00, 'Legion Square', 'XYZ789', 'pending', DATE_ADD(NOW(), INTERVAL 30 DAY)),
('CIT-250101-003', 'steam:example3', 'Mike Johnson', 'officer_1010', 'Sgt. Brown', 'INF-001', 'Stationnement zone interdite', 200.00, 'Del Perro Beach', NULL, 'paid', NULL)
ON DUPLICATE KEY UPDATE citation_number = VALUES(citation_number);

-- ============================================
-- VUES POUR AFFICHAGE RAPIDE
-- ============================================

-- Vue: Casier complet d'un citoyen
CREATE OR REPLACE VIEW `mdt_citizen_full_record` AS
SELECT
    c.identifier,
    c.firstname,
    c.lastname,
    c.dateofbirth,
    c.sex,
    c.phone_number,
    COUNT(DISTINCT ch.id) as total_charges,
    COUNT(DISTINCT CASE WHEN ch.conviction_status = 'convicted' THEN ch.id END) as convictions,
    COUNT(DISTINCT cit.id) as total_citations,
    COUNT(DISTINCT CASE WHEN cit.status = 'pending' THEN cit.id END) as pending_citations,
    SUM(CASE WHEN cit.status = 'pending' THEN cit.fine_amount ELSE 0 END) as total_unpaid_fines,
    MAX(ch.incident_date) as last_arrest_date
FROM users c
LEFT JOIN mdt_criminal_history ch ON c.identifier = ch.citizen_identifier
LEFT JOIN mdt_citations cit ON c.identifier = cit.citizen_identifier
GROUP BY c.identifier;

-- Vue: Personnel en service
CREATE OR REPLACE VIEW `mdt_active_personnel` AS
SELECT
    os.identifier,
    os.officer_name,
    os.badge_number,
    os.unit_number,
    os.current_status,
    os.status_since,
    os.last_location,
    c.call_number,
    c.call_type,
    c.priority
FROM mdt_officer_status os
LEFT JOIN mdt_calls c ON c.id = os.current_call_id
WHERE os.current_status != '10-7'
ORDER BY os.unit_number;

-- Vue: Citations impayées
CREATE OR REPLACE VIEW `mdt_unpaid_citations` AS
SELECT
    cit.*,
    DATEDIFF(cit.due_date, NOW()) as days_until_due,
    CASE
        WHEN cit.due_date < NOW() THEN 'OVERDUE'
        WHEN DATEDIFF(cit.due_date, NOW()) <= 7 THEN 'DUE SOON'
        ELSE 'CURRENT'
    END as urgency
FROM mdt_citations cit
WHERE cit.status = 'pending'
ORDER BY cit.due_date ASC;

-- ============================================
-- PERMISSIONS ADDITIONNELLES
-- ============================================

INSERT INTO `mdt_permissions_list` (permission_key, permission_name, permission_category, permission_type, description) VALUES
('police.citations.create', 'Créer des citations', 'police', 'write', 'Émettre des tickets/amendes'),
('police.citations.dismiss', 'Annuler des citations', 'police', 'admin', 'Dismisser des amendes (superviseur)'),
('police.charges.apply', 'Appliquer des charges', 'police', 'write', 'Charger un suspect'),
('police.notes.create', 'Créer des notes', 'police', 'write', 'Ajouter notes sur citoyens'),
('police.notes.view_all', 'Voir toutes les notes', 'police', 'read', 'Consulter notes autres officiers'),
('police.status.update', 'Mettre à jour status', 'police', 'write', 'Changer code 10 (10-8, 10-6, etc.)')
ON DUPLICATE KEY UPDATE permission_name = VALUES(permission_name);

-- Donner ces permissions par défaut à la police
INSERT INTO `mdt_job_permissions` (job_name, job_grade, permission_id, granted)
SELECT 'police', NULL, id, 1
FROM mdt_permissions_list
WHERE permission_key IN (
    'police.citations.create',
    'police.charges.apply',
    'police.notes.create',
    'police.notes.view_all',
    'police.status.update'
)
ON DUPLICATE KEY UPDATE granted = VALUES(granted);

-- ============================================
-- TRIGGERS POUR AUTO-UPDATE
-- ============================================

-- Auto-update officer status sur nouveau call assigné
DELIMITER $$
CREATE TRIGGER IF NOT EXISTS update_officer_status_on_call
AFTER UPDATE ON mdt_calls
FOR EACH ROW
BEGIN
    IF NEW.status = 'dispatched' AND OLD.status = 'pending' THEN
        -- Marquer officiers comme 10-6 (busy) si unités assignées
        UPDATE mdt_officer_status
        SET current_status = '10-6',
            current_call_id = NEW.id,
            status_since = NOW()
        WHERE JSON_CONTAINS(NEW.units_assigned, JSON_QUOTE(unit_number));
    END IF;
END$$
DELIMITER ;

-- ============================================
-- INDEX POUR PERFORMANCE
-- ============================================

ALTER TABLE `mdt_citations` ADD INDEX `issued_at` (`issued_at`);
ALTER TABLE `mdt_criminal_history` ADD INDEX `incident_date` (`incident_date`);
ALTER TABLE `mdt_citizen_notes` ADD INDEX `created_at` (`created_at`);

-- ============================================
-- STATS FINALES
-- ============================================

SELECT 'Installation MDT complète !' as status;
SELECT COUNT(*) as total_charges FROM mdt_charges;
SELECT COUNT(*) as total_citations FROM mdt_citations;
SELECT COUNT(*) as total_notes FROM mdt_citizen_notes;
SELECT COUNT(*) as officers_on_duty FROM mdt_officer_status WHERE current_status != '10-7';
