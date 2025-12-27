-- ============================================
-- SERVER: Système de Recrutement/Emploi
-- ============================================

-- Vérifier si un joueur est patron de son entreprise
function IsBoss(source)
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

    local isBoss = IsBoss(source)
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
                    photo_url = profile.photo_url,
                    description = profile.description,
                    salary_info = profile.salary_info,
                    is_recruiting = profile.is_recruiting == 1
                })
            else
                -- Créer un profil par défaut si non existant
                MySQL.insert.await([[
                    INSERT INTO company_profiles (job_name, job_label, description, is_recruiting)
                    VALUES (?, ?, ?, 1)
                ]], {jobName, jobData.label, 'Rejoignez notre équipe !'})

                table.insert(companies, {
                    job_name = jobName,
                    job_label = jobData.label,
                    photo_url = nil,
                    description = 'Rejoignez notre équipe !',
                    salary_info = nil,
                    is_recruiting = true
                })
            end
        end
    end

    -- Obtenir le statut de recrutement de l'entreprise actuelle
    local isRecruiting = false
    local currentProfile = MySQL.single.await('SELECT is_recruiting FROM company_profiles WHERE job_name = ?', {currentJob})
    if currentProfile then
        isRecruiting = currentProfile.is_recruiting == 1
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
        TriggerClientEvent('employment:showNotification', _source, '❌ Vous avez déjà une candidature en attente pour cette entreprise', 'error')
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

    TriggerClientEvent('employment:showNotification', _source, '✅ Candidature envoyée avec succès !', 'success')

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

    if not IsBoss(source) then cb(nil) return end

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

    if not IsBoss(_source) then
        TriggerClientEvent('employment:showNotification', _source, '❌ Vous n\'êtes pas autorisé', 'error')
        return
    end

    local job = xPlayer.job.name

    MySQL.update.await([[
        UPDATE company_profiles
        SET photo_url = ?, description = ?, salary_info = ?
        WHERE job_name = ?
    ]], {
        data.photoUrl or nil,
        data.description or nil,
        data.salaryInfo or nil,
        job
    })

    TriggerClientEvent('employment:showNotification', _source, '✅ Profil mis à jour avec succès', 'success')

    -- Webhook
    SendWebhook('CompanyProfileUpdated', {
        jobLabel = xPlayer.job.label,
        modifiedBy = xPlayer.getName(),
        changes = {
            photo = data.photoUrl ~= nil and data.photoUrl ~= '',
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

    if not IsBoss(_source) then
        TriggerClientEvent('employment:showNotification', _source, '❌ Vous n\'êtes pas autorisé', 'error')
        return
    end

    local job = xPlayer.job.name

    -- Obtenir le statut actuel
    local profile = MySQL.single.await('SELECT is_recruiting FROM company_profiles WHERE job_name = ?', {job})

    if not profile then return end

    local newStatus = profile.is_recruiting == 1 and 0 or 1

    MySQL.update.await('UPDATE company_profiles SET is_recruiting = ? WHERE job_name = ?', {newStatus, job})

    local message = newStatus == 1 and '✅ Recrutement ouvert' or '🔒 Recrutement fermé'
    TriggerClientEvent('employment:showNotification', _source, message, 'success')

    -- Webhook
    SendWebhook('RecruitmentStatusChanged', {
        jobLabel = xPlayer.job.label,
        isRecruiting = newStatus == 1,
        modifiedBy = xPlayer.getName()
    })

    -- Rafraîchir pour tous les joueurs
    BroadcastCompaniesUpdate()
end)

-- Obtenir les candidatures (Boss)
ESX.RegisterServerCallback('employment:getApplications', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    if not IsBoss(source) then cb(nil) return end

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

    if not IsBoss(_source) then
        TriggerClientEvent('employment:showNotification', _source, '❌ Vous n\'êtes pas autorisé', 'error')
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
    TriggerClientEvent('employment:showNotification', _source, message, 'success')

    -- Notifier le candidat s'il est en ligne
    local targetPlayer = ESX.GetPlayerFromIdentifier(application.applicant_identifier)
    if targetPlayer then
        local notifMessage = newStatus == 'accepted' and
            '✅ Votre candidature pour ' .. xPlayer.job.label .. ' a été ACCEPTÉE !' or
            '❌ Votre candidature pour ' .. xPlayer.job.label .. ' a été REFUSÉE.'
        TriggerClientEvent('esx:showNotification', targetPlayer.source, notifMessage)
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
                    photo_url = profile.photo_url,
                    description = profile.description,
                    salary_info = profile.salary_info,
                    is_recruiting = profile.is_recruiting == 1
                })
            end
        end
    end

    TriggerClientEvent('employment:refreshCompanies', -1, companies)
end
