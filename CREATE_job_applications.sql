-- Créer la table job_applications complète
-- EXÉCUTEZ CE FICHIER DANS VOTRE BASE DE DONNÉES

-- Supprimer l'ancienne table si elle existe (ATTENTION : supprime les données)
DROP TABLE IF EXISTS `job_applications`;

-- Créer la nouvelle table avec TOUTES les colonnes
CREATE TABLE `job_applications` (
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
