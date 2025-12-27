-- ============================================
-- UPDATE SQL: Activer recrutement par défaut
-- ============================================
-- Ce script met à jour tous les profils existants pour activer le recrutement par défaut
-- Sûr à exécuter plusieurs fois (idempotent)

-- Activer le recrutement pour toutes les entreprises existantes
UPDATE company_profiles
SET is_recruiting = 1
WHERE is_recruiting = 0 OR is_recruiting IS NULL;

-- Vérification
SELECT
    job_name,
    job_label,
    is_recruiting,
    CASE
        WHEN is_recruiting = 1 THEN '✅ Recrutement Ouvert'
        ELSE '🔒 Recrutement Fermé'
    END as status
FROM company_profiles
ORDER BY job_label;
