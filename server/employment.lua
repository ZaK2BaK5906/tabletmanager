-- ============================================
-- SERVER: Système de Recrutement/Emploi
-- ============================================

-- Vérifier si un joueur est patron de son entreprise (utilise source ID)
local function IsBossFromSource(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false end

    for _, grade in ipairs(Config.BossGrades) do
        if xPlayer.job.grade_name == grade then
            return true
        end
    end

    return false
end

-- Obtenir toutes les entreprises avec leurs profils
ESX.RegisterServerCallback('employment:getCompanies', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    local isBoss = IsBossFromSource(source)
    local currentJob = xPlayer.job.name
    local currentJobLabel = xPlayer.job.label

    -- Récupérer tous les jobs
    local jobs = ESX.GetJobs()
    local companies = {}

    -- Récupérer les profils des entreprises
    local profiles = MySQL.query.await('SELECT * FROM company_profiles', {})

    -- Créer un map des profils par job_name
    local profileMap = {}
    for _, profile in ipairs(profiles) do
        profileMap[profile.job_name] = profile
    end

    -- Construire la liste des entreprises
    for jobName, jobData in pairs(jobs) do
        if jobName ~= 'unemployed' then
            local profile = profileMap[jobName]

            if profile then
                table.insert(companies, {
                    job_name = jobName,
                    job_label = jobData.label,
                    photo_url = Config.CompanyLogos[jobName] or Config.DefaultCompanyLogo,
                    description = profile.description,
                    salary_info = profile.salary_info,
                    is_recruiting = (profile.is_recruiting == 1 or profile.is_recruiting == true)
                })
            else
                -- Créer un profil par défaut si non existant (IGNORE si existe déjà)
                MySQL.insert.await([[
                    INSERT IGNORE INTO company_profiles (job_name, job_label, description, is_recruiting)
                    VALUES (?, ?, ?, 1)
                ]], {jobName, jobData.label, 'Rejoignez notre équipe !'})

                -- Re-query pour obtenir la vraie valeur (au cas où le profil existait déjà)
                local newProfile = MySQL.single.await('SELECT * FROM company_profiles WHERE job_name = ?', {jobName})

                if newProfile then
                    table.insert(companies, {
                        job_name = jobName,
                        job_label = jobData.label,
                        photo_url = Config.CompanyLogos[jobName] or Config.DefaultCompanyLogo,
                        description = newProfile.description,
                        salary_info = newProfile.salary_info,
                        is_recruiting = newProfile.is_recruiting == 1
                    })
                else
                    -- Fallback (ne devrait jamais arriver)
                    table.insert(companies, {
                        job_name = jobName,
                        job_label = jobData.label,
                        photo_url = Config.CompanyLogos[jobName] or Config.DefaultCompanyLogo,
                        description = 'Rejoignez notre équipe !',
                        salary_info = nil,
                        is_recruiting = true
                    })
                end
            end
        end
    end

    -- Obtenir le statut de recrutement de l'entreprise actuelle
    local isRecruiting = false
    local currentProfile = MySQL.single.await('SELECT is_recruiting FROM company_profiles WHERE job_name = ?', {currentJob})
    if currentProfile then
        -- Gérer TINYINT(1) qui peut retourner true/false ou 1/0
        isRecruiting = (currentProfile.is_recruiting == 1 or currentProfile.is_recruiting == true)
        print('[EMPLOYMENT DEBUG] getCompanies - Job:', currentJob, 'DB value:', currentProfile.is_recruiting, 'Sending isRecruiting:', isRecruiting)
    else
        print('[EMPLOYMENT DEBUG] getCompanies - Job:', currentJob, 'No profile found, sending isRecruiting: false')
    end

    cb({
        companies = companies,
        isBoss = isBoss,
        currentJob = currentJob,
        currentJobLabel = currentJobLabel,
        isRecruiting = isRecruiting
    })
end)

-- Soumettre une candidature
RegisterNetEvent('employment:submitApplication')
AddEventHandler('employment:submitApplication', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local applicantName = xPlayer.getName()

    -- Vérifier si une candidature existe déjà
    local existingApp = MySQL.single.await([[
        SELECT id FROM job_applications
        WHERE job_name = ? AND applicant_identifier = ? AND status = 'pending'
    ]], {data.jobName, identifier})

    if existingApp then
        ShowNotification(_source, '❌ Vous avez déjà une candidature en attente pour cette entreprise', 'error')
        return
    end

    -- Créer la candidature
    MySQL.insert.await([[
        INSERT INTO job_applications
        (job_name, applicant_identifier, applicant_name, first_name, last_name, phone_number, experience, motivation, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')
    ]], {
        data.jobName,
        identifier,
        applicantName,
        data.firstName,
        data.lastName,
        data.phoneNumber,
        data.experience or nil,
        data.motivation or nil
    })

    ShowNotification(_source, '✅ Candidature envoyée avec succès !', 'success')

    -- Webhook
    SendWebhook('JobApplication', {
        jobLabel = data.jobLabel,
        firstName = data.firstName,
        lastName = data.lastName,
        phoneNumber = data.phoneNumber,
        experience = data.experience,
        motivation = data.motivation
    })
end)

-- Obtenir le profil de l'entreprise (Boss)
ESX.RegisterServerCallback('employment:getCompanyProfile', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    if not IsBossFromSource(source) then cb(nil) return end

    local job = xPlayer.job.name

    local profile = MySQL.single.await('SELECT * FROM company_profiles WHERE job_name = ?', {job})

    cb(profile)
end)

-- Mettre à jour le profil de l'entreprise (Boss)
RegisterNetEvent('employment:updateCompanyProfile')
AddEventHandler('employment:updateCompanyProfile', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    if not IsBossFromSource(_source) then
        ShowNotification(_source, '❌ Vous n\'êtes pas autorisé', 'error')
        return
    end

    local job = xPlayer.job.name

    MySQL.update.await([[
        UPDATE company_profiles
        SET description = ?, salary_info = ?
        WHERE job_name = ?
    ]], {
        data.description or nil,
        data.salaryInfo or nil,
        job
    })

    ShowNotification(_source, '✅ Profil mis à jour avec succès', 'success')

    -- Webhook
    SendWebhook('CompanyProfileUpdated', {
        jobLabel = xPlayer.job.label,
        modifiedBy = xPlayer.getName(),
        changes = {
            description = data.description ~= nil and data.description ~= '',
            salary = data.salaryInfo ~= nil and data.salaryInfo ~= ''
        }
    })

    -- Rafraîchir pour tous les joueurs
    BroadcastCompaniesUpdate()
end)

-- Toggle recrutement (Boss)
RegisterNetEvent('employment:toggleRecruitment')
AddEventHandler('employment:toggleRecruitment', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    if not IsBossFromSource(_source) then
        ShowNotification(_source, '❌ Vous n\'êtes pas autorisé', 'error')
        return
    end

    local job = xPlayer.job.name
    local jobLabel = xPlayer.job.label

    -- Obtenir le statut actuel ou créer le profile
    local profile = MySQL.single.await('SELECT is_recruiting FROM company_profiles WHERE job_name = ?', {job})

    print('[EMPLOYMENT DEBUG] Job:', job, 'Profile exists:', profile ~= nil)

    if not profile then
        -- Créer le profile par défaut (IGNORE si existe déjà)
        MySQL.insert.await([[
            INSERT IGNORE INTO company_profiles (job_name, job_label, description, is_recruiting)
            VALUES (?, ?, ?, 0)
        ]], {job, jobLabel, 'Rejoignez notre équipe !'})
        -- Re-query to get the actual value (in case it already existed)
        profile = MySQL.single.await('SELECT is_recruiting FROM company_profiles WHERE job_name = ?', {job})
        if not profile then
            -- Should never happen, but fallback to default
            profile = { is_recruiting = 0 }
        end
        print('[EMPLOYMENT DEBUG] Created or found profile with is_recruiting =', profile.is_recruiting)
    else
        print('[EMPLOYMENT DEBUG] Current is_recruiting value:', profile.is_recruiting)
    end

    -- Convertir en booléen pour gérer TINYINT(1) qui retourne true/false
    local isCurrentlyOpen = (profile.is_recruiting == 1 or profile.is_recruiting == true)
    local newStatus = isCurrentlyOpen and 0 or 1
    print('[EMPLOYMENT DEBUG] Toggling from', profile.is_recruiting, '(isOpen:', isCurrentlyOpen, ') to', newStatus)

    MySQL.update.await('UPDATE company_profiles SET is_recruiting = ? WHERE job_name = ?', {newStatus, job})

    -- Verify the update
    local verify = MySQL.single.await('SELECT is_recruiting FROM company_profiles WHERE job_name = ?', {job})
    print('[EMPLOYMENT DEBUG] After UPDATE, database has is_recruiting =', verify and verify.is_recruiting or 'NULL')

    local message = newStatus == 1 and '✅ Recrutement ouvert' or '🔒 Recrutement fermé'
    ShowNotification(_source, message, 'success')

    -- Rafraîchir pour tous les joueurs
    BroadcastCompaniesUpdate()

    -- Envoyer le nouveau statut au client après un petit délai (async)
    CreateThread(function()
        Wait(150)
        TriggerClientEvent('employment:updateRecruitmentStatus', _source, newStatus == 1)
    end)

    -- Webhook
    SendWebhook('RecruitmentStatusChanged', {
        jobLabel = xPlayer.job.label,
        isRecruiting = newStatus == 1,
        modifiedBy = xPlayer.getName()
    })
end)

-- Obtenir les candidatures (Boss)
ESX.RegisterServerCallback('employment:getApplications', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    if not IsBossFromSource(source) then cb(nil) return end

    local job = xPlayer.job.name

    local applications = MySQL.query.await([[
        SELECT * FROM job_applications
        WHERE job_name = ?
        ORDER BY created_at DESC
    ]], {job})

    cb(applications)
end)

-- Traiter une candidature (Boss)
RegisterNetEvent('employment:processApplication')
AddEventHandler('employment:processApplication', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    if not IsBossFromSource(_source) then
        ShowNotification(_source, '❌ Vous n\'êtes pas autorisé', 'error')
        return
    end

    local appId = data.applicationId
    local newStatus = data.status -- 'accepted' or 'rejected'

    -- Récupérer les infos de la candidature
    local application = MySQL.single.await('SELECT * FROM job_applications WHERE id = ?', {appId})

    if not application then return end

    -- Mettre à jour le statut
    MySQL.update.await('UPDATE job_applications SET status = ? WHERE id = ?', {newStatus, appId})

    local message = newStatus == 'accepted' and '✅ Candidature acceptée' or '❌ Candidature refusée'
    ShowNotification(_source, message, 'success')

    -- Notifier le candidat s'il est en ligne
    local targetPlayer = ESX.GetPlayerFromIdentifier(application.applicant_identifier)
    if targetPlayer then
        local notifMessage = newStatus == 'accepted' and
            '✅ Votre candidature pour ' .. xPlayer.job.label .. ' a été ACCEPTÉE !' or
            '❌ Votre candidature pour ' .. xPlayer.job.label .. ' a été REFUSÉE.'
        local notifType = newStatus == 'accepted' and 'success' or 'error'
        ShowNotification(targetPlayer.source, notifMessage, notifType)
    end

    -- Webhook
    SendWebhook('ApplicationStatusChanged', {
        job = xPlayer.job.name,
        applicantName = application.first_name .. ' ' .. application.last_name,
        newStatus = newStatus,
        processedBy = xPlayer.getName()
    })

    -- Rafraîchir les candidatures pour le patron
    ESX.TriggerServerCallback('employment:getApplications', function(applications)
        TriggerClientEvent('employment:refreshApplications', _source, applications)
    end, _source)
end)

-- Broadcast update des entreprises à tous les joueurs
function BroadcastCompaniesUpdate()
    local jobs = ESX.GetJobs()
    local companies = {}

    local profiles = MySQL.query.await('SELECT * FROM company_profiles', {})

    local profileMap = {}
    for _, profile in ipairs(profiles) do
        profileMap[profile.job_name] = profile
    end

    for jobName, jobData in pairs(jobs) do
        if jobName ~= 'unemployed' then
            local profile = profileMap[jobName]

            if profile then
                table.insert(companies, {
                    job_name = jobName,
                    job_label = jobData.label,
                    photo_url = Config.CompanyLogos[jobName] or Config.DefaultCompanyLogo,
                    description = profile.description,
                    salary_info = profile.salary_info,
                    is_recruiting = (profile.is_recruiting == 1 or profile.is_recruiting == true)
                })
            end
        end
    end

    TriggerClientEvent('employment:refreshCompanies', -1, companies)
end
