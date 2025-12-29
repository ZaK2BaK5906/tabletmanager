-- ============================================
-- MDT CLEANUP - SUPPRESSION COMPLÈTE
-- ============================================
-- ⚠️ ATTENTION: Ce fichier supprime TOUTES les tables MDT
-- Utiliser AVANT d'installer mdt_complete.sql
-- ============================================

-- Désactiver les contraintes de clés étrangères temporairement
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================
-- SUPPRESSION DES VUES
-- ============================================
DROP VIEW IF EXISTS `mdt_user_effective_permissions`;
DROP VIEW IF EXISTS `mdt_active_calls`;
DROP VIEW IF EXISTS `mdt_citizen_search`;

-- ============================================
-- SUPPRESSION DES TABLES DE PERMISSIONS
-- ============================================
DROP TABLE IF EXISTS `mdt_blocked_actions`;
DROP TABLE IF EXISTS `mdt_department_config`;
DROP TABLE IF EXISTS `mdt_share_permissions`;
DROP TABLE IF EXISTS `mdt_access_logs`;
DROP TABLE IF EXISTS `mdt_access_restrictions`;
DROP TABLE IF EXISTS `mdt_confidentiality_levels`;
DROP TABLE IF EXISTS `mdt_user_permissions`;
DROP TABLE IF EXISTS `mdt_job_permissions`;
DROP TABLE IF EXISTS `mdt_permissions_list`;

-- ============================================
-- SUPPRESSION DES TABLES EMS
-- ============================================
DROP TABLE IF EXISTS `mdt_medical_inventory`;
DROP TABLE IF EXISTS `mdt_patient_followup`;
DROP TABLE IF EXISTS `mdt_certificates`;
DROP TABLE IF EXISTS `mdt_deaths`;
DROP TABLE IF EXISTS `mdt_mental_health`;
DROP TABLE IF EXISTS `mdt_hospitalizations`;
DROP TABLE IF EXISTS `mdt_transport`;
DROP TABLE IF EXISTS `mdt_medication`;
DROP TABLE IF EXISTS `mdt_trauma`;
DROP TABLE IF EXISTS `mdt_epcr`;
DROP TABLE IF EXISTS `mdt_vitals`;
DROP TABLE IF EXISTS `mdt_medical_records`;
DROP TABLE IF EXISTS `mdt_patients`;
DROP TABLE IF EXISTS `mdt_ems_units`;
DROP TABLE IF EXISTS `mdt_ems_calls`;

-- ============================================
-- SUPPRESSION DES TABLES DOJ
-- ============================================
DROP TABLE IF EXISTS `mdt_expungement`;
DROP TABLE IF EXISTS `mdt_motions`;
DROP TABLE IF EXISTS `mdt_probation`;
DROP TABLE IF EXISTS `mdt_judgments`;
DROP TABLE IF EXISTS `mdt_plea_deals`;
DROP TABLE IF EXISTS `mdt_bail`;
DROP TABLE IF EXISTS `mdt_hearing_minutes`;
DROP TABLE IF EXISTS `mdt_hearings`;
DROP TABLE IF EXISTS `mdt_subpoenas`;
DROP TABLE IF EXISTS `mdt_probable_cause`;
DROP TABLE IF EXISTS `mdt_charges`;
DROP TABLE IF EXISTS `mdt_cases`;

-- ============================================
-- SUPPRESSION DES TABLES POLICE
-- ============================================
DROP TABLE IF EXISTS `mdt_citizen_notes`;
DROP TABLE IF EXISTS `mdt_personnel`;
DROP TABLE IF EXISTS `mdt_gangs`;
DROP TABLE IF EXISTS `mdt_orders`;
DROP TABLE IF EXISTS `mdt_witnesses`;
DROP TABLE IF EXISTS `mdt_scenes`;
DROP TABLE IF EXISTS `mdt_evidence`;
DROP TABLE IF EXISTS `mdt_impounds`;
DROP TABLE IF EXISTS `mdt_warrants`;
DROP TABLE IF EXISTS `mdt_wanted`;
DROP TABLE IF EXISTS `mdt_bolo`;
DROP TABLE IF EXISTS `mdt_pursuits`;
DROP TABLE IF EXISTS `mdt_use_of_force`;
DROP TABLE IF EXISTS `mdt_reports`;
DROP TABLE IF EXISTS `mdt_arrests`;
DROP TABLE IF EXISTS `mdt_citations`;
DROP TABLE IF EXISTS `mdt_criminal_records`;
DROP TABLE IF EXISTS `mdt_ppa_ccw`;
DROP TABLE IF EXISTS `mdt_licenses`;
DROP TABLE IF EXISTS `mdt_businesses`;
DROP TABLE IF EXISTS `mdt_weapons`;
DROP TABLE IF EXISTS `mdt_vehicles`;
DROP TABLE IF EXISTS `mdt_units`;
DROP TABLE IF EXISTS `mdt_calls`;

-- ============================================
-- SUPPRESSION DES TABLES PARTAGÉES
-- ============================================
DROP TABLE IF EXISTS `mdt_notes`;
DROP TABLE IF EXISTS `mdt_activity_log`;
DROP TABLE IF EXISTS `mdt_attachments`;
DROP TABLE IF EXISTS `mdt_citizens`;

-- Réactiver les contraintes de clés étrangères
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- CONFIRMATION
-- ============================================
SELECT '✅ Cleanup MDT terminé - Toutes les tables supprimées' as status;
SELECT 'ℹ️ Vous pouvez maintenant exécuter mdt_complete.sql' as next_step;
