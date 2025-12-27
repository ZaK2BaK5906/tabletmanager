-- ============================================
-- MIGRATION: Système de Recrutement/Emploi
-- Description: Ajout des tables pour le système Indeed intégré
-- Date: 2025-12-27
-- ============================================

-- Table pour les profils d'entreprise
CREATE TABLE IF NOT EXISTS `company_profiles` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `job_name` VARCHAR(50) NOT NULL UNIQUE,
    `job_label` VARCHAR(100) NOT NULL,
    `photo_url` VARCHAR(500) DEFAULT NULL,
    `description` TEXT DEFAULT NULL,
    `salary_info` TEXT DEFAULT NULL,
    `is_recruiting` TINYINT(1) DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_job_name` (`job_name`),
    INDEX `idx_recruiting` (`is_recruiting`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table pour les candidatures
CREATE TABLE IF NOT EXISTS `job_applications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `job_name` VARCHAR(50) NOT NULL,
    `applicant_identifier` VARCHAR(60) NOT NULL,
    `applicant_name` VARCHAR(100) NOT NULL,
    `first_name` VARCHAR(50) NOT NULL,
    `last_name` VARCHAR(50) NOT NULL,
    `phone_number` VARCHAR(20) NOT NULL,
    `experience` TEXT DEFAULT NULL,
    `motivation` TEXT DEFAULT NULL,
    `status` ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_job_name` (`job_name`),
    INDEX `idx_applicant` (`applicant_identifier`),
    INDEX `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Initialiser les profils pour tous les jobs existants (sans les données joueurs)
-- Cette requête crée automatiquement un profil pour chaque job qui n'en a pas encore
INSERT IGNORE INTO company_profiles (job_name, job_label, description, is_recruiting)
SELECT 'unemployed', 'Chômeur', 'Pole Emploi - Sans emploi', 0
UNION ALL SELECT 'police', 'LSPD', 'Los Santos Police Department - Protéger et servir la ville', 1
UNION ALL SELECT 'ambulance', 'EMS', 'Emergency Medical Services - Sauver des vies', 1
UNION ALL SELECT 'mechanic', 'Mécano', 'Garage mécanique - Réparation de véhicules', 1
UNION ALL SELECT 'doj', 'DOJ', 'Department of Justice - Justice et gouvernement', 0
UNION ALL SELECT 'government', 'Gouvernement', 'Administration gouvernementale', 0
UNION ALL SELECT 'taxi', 'Taxi', 'Service de transport - Conduire les citoyens', 1
UNION ALL SELECT 'unicorn', 'Unicorn', 'Vanilla Unicorn - Divertissement', 1
UNION ALL SELECT 'realestateagent', 'Agent Immo', 'Agence immobilière - Vente de propriétés', 1
UNION ALL SELECT 'cardealer', 'Concessionnaire', 'Vente de véhicules neufs et occasions', 1
UNION ALL SELECT 'banker', 'Banque', 'Services bancaires et financiers', 1;

-- ============================================
-- FIN DE LA MIGRATION
-- ============================================
