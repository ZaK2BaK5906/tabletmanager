-- ============================================
-- MDT POLICE - TABLES ADDITIONNELLES
-- Pour compléter le schéma de base MDT
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
  KEY `type` (`note_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Notes police sur citoyens avec flags et types';

-- Index pour recherche rapide des notes flaggées
CREATE INDEX idx_citizen_flagged ON mdt_citizen_notes(citizen_identifier, is_flagged);
