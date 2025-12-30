-- ============================================
-- B_ADMIN2 - SCHEMA SQL COMPLET
-- Préfixe: z_ (pour différenciation)
-- ============================================

-- Table: Permissions staff (RBAC)
CREATE TABLE IF NOT EXISTS `z_admin_permissions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(100) NOT NULL COMMENT 'license:xxx ou discord:xxx',
  `rank` VARCHAR(50) NOT NULL DEFAULT 'helper' COMMENT 'helper/mod/admin/superadmin/owner',
  `flags` TEXT NULL COMMENT 'JSON array flags custom',
  `discord_id` VARCHAR(100) NULL,
  `assigned_by` VARCHAR(100) NULL,
  `assigned_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  UNIQUE KEY `unique_identifier` (`identifier`),
  INDEX `idx_discord` (`discord_id`),
  INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Actions staff (logs)
CREATE TABLE IF NOT EXISTS `z_admin_actions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `admin_license` VARCHAR(100) NOT NULL,
  `admin_discord_id` VARCHAR(100) NULL,
  `admin_rank` VARCHAR(50) NOT NULL,
  `target_license` VARCHAR(100) NULL COMMENT 'Null si action globale',
  `target_discord_id` VARCHAR(100) NULL,
  `target_name` VARCHAR(255) NULL,
  `action_type` VARCHAR(100) NOT NULL COMMENT 'warn/kick/ban/give_money/spectate/etc',
  `action_category` VARCHAR(50) NOT NULL COMMENT 'moderation/economy/player/staffmode/reports/security',
  `payload` TEXT NULL COMMENT 'JSON: montant/item/durée/coords/raison/etc',
  `success` TINYINT(1) DEFAULT 1,
  `fail_reason` TEXT NULL,
  `ticket_id` INT NULL,
  `performed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `server_id` VARCHAR(50) NULL COMMENT 'Si multi-serveur',
  INDEX `idx_admin` (`admin_license`),
  INDEX `idx_target` (`target_license`),
  INDEX `idx_action_type` (`action_type`),
  INDEX `idx_category` (`action_category`),
  INDEX `idx_performed_at` (`performed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Warns
CREATE TABLE IF NOT EXISTS `z_admin_warns` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `target_license` VARCHAR(100) NOT NULL,
  `target_discord_id` VARCHAR(100) NULL,
  `target_name` VARCHAR(255) NOT NULL,
  `admin_license` VARCHAR(100) NOT NULL,
  `admin_name` VARCHAR(255) NOT NULL,
  `reason` TEXT NOT NULL,
  `points` INT DEFAULT 1,
  `issued_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `action_log_id` INT NULL,
  INDEX `idx_target` (`target_license`),
  INDEX `idx_active` (`is_active`),
  FOREIGN KEY (`action_log_id`) REFERENCES `z_admin_actions`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Bans
CREATE TABLE IF NOT EXISTS `z_admin_bans` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `target_license` VARCHAR(100) NOT NULL,
  `target_discord_id` VARCHAR(100) NULL,
  `target_name` VARCHAR(255) NOT NULL,
  `admin_license` VARCHAR(100) NOT NULL,
  `admin_name` VARCHAR(255) NOT NULL,
  `reason` TEXT NOT NULL,
  `ban_type` VARCHAR(20) NOT NULL COMMENT 'temp/permanent',
  `issued_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `expires_at` TIMESTAMP NULL,
  `is_active` TINYINT(1) DEFAULT 1,
  `unbanned_by` VARCHAR(100) NULL,
  `unbanned_at` TIMESTAMP NULL,
  `action_log_id` INT NULL,
  UNIQUE KEY `unique_active_license` (`target_license`, `is_active`),
  INDEX `idx_target` (`target_license`),
  INDEX `idx_active` (`is_active`),
  FOREIGN KEY (`action_log_id`) REFERENCES `z_admin_actions`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Notes staff sur joueurs
CREATE TABLE IF NOT EXISTS `z_admin_notes` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `target_license` VARCHAR(100) NOT NULL,
  `target_discord_id` VARCHAR(100) NULL,
  `admin_license` VARCHAR(100) NOT NULL,
  `admin_name` VARCHAR(255) NOT NULL,
  `note` TEXT NOT NULL,
  `severity` VARCHAR(20) DEFAULT 'info' COMMENT 'info/warning/critical',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_target` (`target_license`),
  INDEX `idx_severity` (`severity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Reports & Tickets (système unique)
CREATE TABLE IF NOT EXISTS `z_admin_tickets` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `reporter_license` VARCHAR(100) NOT NULL,
  `reporter_discord_id` VARCHAR(100) NULL,
  `reporter_name` VARCHAR(255) NOT NULL,
  `reported_license` VARCHAR(100) NULL COMMENT 'Null si report général',
  `reported_discord_id` VARCHAR(100) NULL,
  `reported_name` VARCHAR(255) NULL,
  `category` VARCHAR(50) NOT NULL COMMENT 'cheat/bug/grief/help/abuse/other',
  `priority` VARCHAR(20) DEFAULT 'normal' COMMENT 'low/normal/high/urgent',
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT NOT NULL,
  `status` VARCHAR(50) DEFAULT 'open' COMMENT 'open/assigned/in_progress/resolved/closed',
  `assigned_to` VARCHAR(100) NULL COMMENT 'staff license',
  `assigned_at` TIMESTAMP NULL,
  `resolved_by` VARCHAR(100) NULL,
  `resolved_at` TIMESTAMP NULL,
  `resolution_note` TEXT NULL,
  `rating` TINYINT(1) NULL COMMENT '1-5 stars, null si pas rated',
  `rating_comment` TEXT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_reporter` (`reporter_license`),
  INDEX `idx_reported` (`reported_license`),
  INDEX `idx_status` (`status`),
  INDEX `idx_assigned` (`assigned_to`),
  INDEX `idx_priority` (`priority`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Ticket timeline (actions liées)
CREATE TABLE IF NOT EXISTS `z_admin_ticket_timeline` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `ticket_id` INT NOT NULL,
  `actor_license` VARCHAR(100) NULL COMMENT 'Staff ou système',
  `actor_name` VARCHAR(255) NULL,
  `event_type` VARCHAR(50) NOT NULL COMMENT 'created/assigned/comment/status_change/resolved/rated',
  `event_data` TEXT NULL COMMENT 'JSON: détails de l\'event',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_ticket` (`ticket_id`),
  FOREIGN KEY (`ticket_id`) REFERENCES `z_admin_tickets`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Player actions (logs joueurs optionnels, perf safe)
CREATE TABLE IF NOT EXISTS `z_player_actions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `license` VARCHAR(100) NOT NULL,
  `discord_id` VARCHAR(100) NULL,
  `player_name` VARCHAR(255) NULL,
  `action_type` VARCHAR(100) NOT NULL COMMENT 'connect/disconnect/vehicle_enter/weapon_fired/kill/death/inventory_move/money_change/command/teleport/speed',
  `payload` TEXT NULL COMMENT 'JSON: détails action',
  `coords` VARCHAR(100) NULL,
  `zone` VARCHAR(100) NULL,
  `suspicious` TINYINT(1) DEFAULT 0 COMMENT 'Flag si action suspecte (tp, speed)',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_license` (`license`),
  INDEX `idx_action_type` (`action_type`),
  INDEX `idx_suspicious` (`suspicious`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Discord Watch sessions (télémétrie)
CREATE TABLE IF NOT EXISTS `z_admin_watch_sessions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `target_license` VARCHAR(100) NOT NULL,
  `watcher_discord_id` VARCHAR(100) NOT NULL,
  `watcher_name` VARCHAR(255) NOT NULL,
  `started_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `ended_at` TIMESTAMP NULL,
  `duration_minutes` INT DEFAULT 5,
  `is_active` TINYINT(1) DEFAULT 1,
  `discord_channel_id` VARCHAR(100) NULL COMMENT 'Channel où envoyer les updates',
  INDEX `idx_target` (`target_license`),
  INDEX `idx_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table: Config (panic mode, maintenance, etc.)
CREATE TABLE IF NOT EXISTS `z_admin_config` (
  `key` VARCHAR(100) PRIMARY KEY,
  `value` TEXT NOT NULL,
  `updated_by` VARCHAR(100) NULL,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Inserts config par défaut
INSERT INTO `z_admin_config` (`key`, `value`) VALUES
('panic_mode', 'false'),
('maintenance_mode', 'false'),
('economy_multiplier', '1.0')
ON DUPLICATE KEY UPDATE `key`=`key`;

-- Table: Rate limits (anti-spam)
CREATE TABLE IF NOT EXISTS `z_admin_rate_limits` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `identifier` VARCHAR(100) NOT NULL COMMENT 'license ou discord_id',
  `action_type` VARCHAR(100) NOT NULL,
  `last_used` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `use_count` INT DEFAULT 1,
  `reset_at` TIMESTAMP NULL,
  UNIQUE KEY `unique_identifier_action` (`identifier`, `action_type`),
  INDEX `idx_reset` (`reset_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- VIEWS UTILES
-- ============================================

-- View: Stats staff (nombre actions par admin)
CREATE OR REPLACE VIEW `z_admin_stats` AS
SELECT
  `admin_license`,
  `admin_rank`,
  COUNT(*) as `total_actions`,
  COUNT(CASE WHEN `action_category` = 'moderation' THEN 1 END) as `moderation_actions`,
  COUNT(CASE WHEN `action_category` = 'economy' THEN 1 END) as `economy_actions`,
  COUNT(CASE WHEN `action_category` = 'player' THEN 1 END) as `player_actions`,
  MAX(`performed_at`) as `last_action`
FROM `z_admin_actions`
GROUP BY `admin_license`, `admin_rank`;

-- View: Active bans
CREATE OR REPLACE VIEW `z_active_bans` AS
SELECT
  `id`,
  `target_license`,
  `target_discord_id`,
  `target_name`,
  `admin_name`,
  `reason`,
  `ban_type`,
  `issued_at`,
  `expires_at`,
  CASE
    WHEN `ban_type` = 'permanent' THEN 'Permanent'
    WHEN `expires_at` > NOW() THEN CONCAT(TIMESTAMPDIFF(HOUR, NOW(), `expires_at`), 'h restantes')
    ELSE 'Expiré'
  END as `time_remaining`
FROM `z_admin_bans`
WHERE `is_active` = 1;

-- View: Active warns
CREATE OR REPLACE VIEW `z_active_warns` AS
SELECT
  `target_license`,
  COUNT(*) as `total_warns`,
  SUM(`points`) as `total_points`,
  MAX(`issued_at`) as `last_warn`
FROM `z_admin_warns`
WHERE `is_active` = 1
GROUP BY `target_license`;

-- View: Open tickets
CREATE OR REPLACE VIEW `z_open_tickets` AS
SELECT
  `id`,
  `reporter_name`,
  `reported_name`,
  `category`,
  `priority`,
  `title`,
  `status`,
  `assigned_to`,
  `created_at`,
  TIMESTAMPDIFF(MINUTE, `created_at`, NOW()) as `age_minutes`
FROM `z_admin_tickets`
WHERE `status` IN ('open', 'assigned', 'in_progress')
ORDER BY
  FIELD(`priority`, 'urgent', 'high', 'normal', 'low'),
  `created_at` ASC;

-- ============================================
-- INDEXES ADDITIONNELS POUR PERFORMANCE
-- ============================================

-- Index composites pour recherches fréquentes
ALTER TABLE `z_admin_actions`
  ADD INDEX `idx_admin_date` (`admin_license`, `performed_at`),
  ADD INDEX `idx_target_date` (`target_license`, `performed_at`);

ALTER TABLE `z_player_actions`
  ADD INDEX `idx_license_date` (`license`, `created_at`),
  ADD INDEX `idx_suspicious_date` (`suspicious`, `created_at`);

-- ============================================
-- TRIGGERS UTILES
-- ============================================

-- Trigger: Auto-expire warns
DELIMITER $$
CREATE TRIGGER `z_auto_expire_warns`
BEFORE UPDATE ON `z_admin_warns`
FOR EACH ROW
BEGIN
  IF NEW.`expires_at` IS NOT NULL AND NEW.`expires_at` < NOW() THEN
    SET NEW.`is_active` = 0;
  END IF;
END$$
DELIMITER ;

-- Trigger: Auto-expire bans
DELIMITER $$
CREATE TRIGGER `z_auto_expire_bans`
BEFORE UPDATE ON `z_admin_bans`
FOR EACH ROW
BEGIN
  IF NEW.`ban_type` = 'temp' AND NEW.`expires_at` IS NOT NULL AND NEW.`expires_at` < NOW() THEN
    SET NEW.`is_active` = 0;
  END IF;
END$$
DELIMITER ;

-- ============================================
-- FIN DU SCHEMA
-- ============================================
