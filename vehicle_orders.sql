-- Table pour tracker les commandes de véhicules (pour affichage dans historique)
CREATE TABLE IF NOT EXISTS `vehicle_orders` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `job` VARCHAR(50) NOT NULL,
    `vehicle_model` VARCHAR(60) NOT NULL,
    `vehicle_name` VARCHAR(100) NOT NULL,
    `quantity` INT NOT NULL,
    `unit_price` DECIMAL(10,2) NOT NULL,
    `total_cost` DECIMAL(10,2) NOT NULL,
    `ordered_by` VARCHAR(100) NOT NULL,
    `ordered_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_job` (`job`),
    INDEX `idx_date` (`ordered_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
