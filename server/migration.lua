-- ============================================
-- AUTO-MIGRATION: Création tables si inexistantes
-- ============================================

CreateThread(function()
    -- Attendre que MySQL soit prêt
    Wait(1000)

    print("^3[Tablet Manager]^7 Vérification des tables...")

    -- Créer la table company_profiles si elle n'existe pas
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `company_profiles` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `job_name` VARCHAR(50) NOT NULL UNIQUE,
            `job_label` VARCHAR(100) NOT NULL,
            `photo_url` VARCHAR(500) DEFAULT NULL,
            `description` TEXT DEFAULT NULL,
            `salary_info` TEXT DEFAULT NULL,
            `is_recruiting` TINYINT(1) DEFAULT 1,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX `idx_job_name` (`job_name`),
            INDEX `idx_recruiting` (`is_recruiting`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    -- Créer la table job_applications si elle n'existe pas
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `job_applications` (
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
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])

    print("^2[Tablet Manager]^7 Tables vérifiées ✓")

    -- Initialiser les profils pour les jobs existants
    Wait(2000)
    local jobs = ESX.GetJobs()

    for jobName, jobData in pairs(jobs) do
        if jobName ~= 'unemployed' then
            -- Vérifier si le profil existe
            local exists = MySQL.scalar.await('SELECT COUNT(*) FROM company_profiles WHERE job_name = ?', {jobName})

            if exists == 0 then
                -- Créer le profil par défaut
                MySQL.insert.await([[
                    INSERT INTO company_profiles (job_name, job_label, description, is_recruiting)
                    VALUES (?, ?, ?, 1)
                ]], {jobName, jobData.label, 'Rejoignez notre équipe professionnelle !'})

                print(string.format("^2[Tablet Manager]^7 Profil créé pour: %s", jobData.label))
            end
        end
    end

    print("^2[Tablet Manager]^7 Migration automatique terminée ✓")
end)
