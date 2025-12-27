-- DIAGNOSTIC: Vérifie si tout est OK dans la DB
-- Execute ça et dis-moi ce que ça retourne

-- 1. Vérifie si les colonnes existent dans company_profiles
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'company_profiles'
AND COLUMN_NAME IN ('commission_reset_date', 'vat_reset_date');

-- 2. Vérifie si la table employee_financial_tracking existe
SELECT COUNT(*) as table_exists
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'employee_financial_tracking';

-- 3. Montre les valeurs actuelles
SELECT
    job_name,
    commission_reset_date,
    vat_reset_date
FROM company_profiles
LIMIT 5;

-- 4. Compte les factures payées
SELECT
    job,
    COUNT(*) as factures_payees,
    SUM(commission_amount) as total_commissions,
    SUM(total) as total_ventes
FROM tablet_invoices
WHERE status = 'paid'
GROUP BY job;
