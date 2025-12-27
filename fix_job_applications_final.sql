-- Fix complet pour la table job_applications
-- Exécutez ce fichier SQL dans votre base de données

-- Option 1: Si la table existe déjà, ajoutez les colonnes manquantes
ALTER TABLE `job_applications`
ADD COLUMN IF NOT EXISTS `job_name` VARCHAR(50) NOT NULL AFTER `id`,
ADD COLUMN IF NOT EXISTS `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP AFTER `status`,
ADD COLUMN IF NOT EXISTS `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP AFTER `created_at`;

-- Option 2: Si vous préférez recréer la table complète (supprime les données existantes)
-- Décommentez les lignes ci-dessous si vous voulez tout recréer

-- DROP TABLE IF EXISTS `job_applications`;
-- CREATE TABLE `job_applications` (
--     `id` INT AUTO_INCREMENT PRIMARY KEY,
--     `job_name` VARCHAR(50) NOT NULL,
--     `applicant_identifier` VARCHAR(60) NOT NULL,
--     `applicant_name` VARCHAR(100) NOT NULL,
--     `first_name` VARCHAR(50) NOT NULL,
--     `last_name` VARCHAR(50) NOT NULL,
--     `phone_number` VARCHAR(20) NOT NULL,
--     `experience` TEXT DEFAULT NULL,
--     `motivation` TEXT DEFAULT NULL,
--     `status` ENUM('pending', 'accepted', 'rejected') DEFAULT 'pending',
--     `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--     `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--     INDEX `idx_job_name` (`job_name`),
--     INDEX `idx_applicant` (`applicant_identifier`),
--     INDEX `idx_status` (`status`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
