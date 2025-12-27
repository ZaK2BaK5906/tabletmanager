-- Table pour tracking financier par employé
CREATE TABLE IF NOT EXISTS `employee_financial_tracking` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `job` VARCHAR(50) NOT NULL,
    `employee_identifier` VARCHAR(60) NOT NULL,
    `commission_reset_date` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY `unique_job_employee` (`job`, `employee_identifier`),
    INDEX `idx_job` (`job`),
    INDEX `idx_employee` (`employee_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
