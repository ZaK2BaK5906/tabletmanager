-- =====================================================
-- TABLETMANAGER - Base de données
-- =====================================================

-- Table des produits par job
CREATE TABLE IF NOT EXISTS `tablet_products` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `job` VARCHAR(50) NOT NULL,
    `product_name` VARCHAR(100) NOT NULL,
    `price` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des factures
CREATE TABLE IF NOT EXISTS `tablet_invoices` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `job` VARCHAR(50) NOT NULL,
    `employee_identifier` VARCHAR(50) NOT NULL,
    `employee_name` VARCHAR(100) NOT NULL,
    `items` LONGTEXT NOT NULL, -- JSON des items
    `subtotal` DECIMAL(10, 2) NOT NULL DEFAULT 0.00, -- Total HT
    `discount_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `partnership_discount` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `partnership_name` VARCHAR(100) DEFAULT NULL,
    `tax_percent` DECIMAL(5, 2) NOT NULL DEFAULT 20.00,
    `total` DECIMAL(10, 2) NOT NULL DEFAULT 0.00, -- Total TTC
    `commission_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `commission_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `job` (`job`),
    KEY `employee_identifier` (`employee_identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des commissions des employés
CREATE TABLE IF NOT EXISTS `tablet_employee_commissions` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `job` VARCHAR(50) NOT NULL,
    `identifier` VARCHAR(50) NOT NULL,
    `commission_percent` DECIMAL(5, 2) NOT NULL DEFAULT 5.00,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `job_identifier` (`job`, `identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des partenariats
CREATE TABLE IF NOT EXISTS `tablet_partnerships` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `job` VARCHAR(50) NOT NULL,
    `company_name` VARCHAR(100) NOT NULL,
    `discount_percent` DECIMAL(5, 2) NOT NULL DEFAULT 0.00,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Table des paiements entre entreprises
CREATE TABLE IF NOT EXISTS `tablet_company_payments` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `from_job` VARCHAR(50) NOT NULL,
    `to_company` VARCHAR(100) NOT NULL,
    `amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `invoice_id` INT(11) NOT NULL,
    `paid_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `from_job` (`from_job`),
    KEY `invoice_id` (`invoice_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
