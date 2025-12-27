-- Ajouter colonnes pour tracking financier avec reset
ALTER TABLE company_profiles
ADD COLUMN commission_reset_date TIMESTAMP NULL DEFAULT NULL,
ADD COLUMN vat_reset_date TIMESTAMP NULL DEFAULT NULL;
