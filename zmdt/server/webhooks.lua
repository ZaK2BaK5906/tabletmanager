-- ============================================
-- ZX POLICE MDT - WEBHOOKS DISCORD
-- ============================================

local Webhooks = {}

-- ============================================
-- FONCTION PRINCIPALE: ENVOYER UN WEBHOOK
-- ============================================

function Webhooks.Send(webhookType, eventType, data)
    if not Config.Webhooks.enabled then return end

    local webhookUrl = Config.Webhooks.urls[webhookType]
    if not webhookUrl or webhookUrl == 'https://discord.com/api/webhooks/YOUR_WEBHOOK_HERE' then
        return -- Webhook pas configuré
    end

    -- Vérifier si cet event doit être envoyé
    local events = Config.Webhooks.events[webhookType]
    if events and not table.contains(events, eventType) and not table.contains(events, 'all') then
        return -- Event pas configuré pour ce webhook
    end

    -- Construire l'embed selon le type
    local embed = Webhooks.BuildEmbed(webhookType, eventType, data)
    if not embed then return end

    -- Envoyer le webhook
    PerformHttpRequest(webhookUrl, function(err, text, headers)
        -- Optionnel: logger les erreurs
    end, 'POST', json.encode({
        username = 'Police MDT',
        avatar_url = 'https://i.imgur.com/YOUR_AVATAR.png',
        embeds = {embed}
    }), {['Content-Type'] = 'application/json'})
end

-- ============================================
-- CONSTRUIRE L'EMBED SELON LE TYPE
-- ============================================

function Webhooks.BuildEmbed(webhookType, eventType, data)
    local color = Config.Webhooks.colors[webhookType] or 3447003
    local embed = {
        color = color,
        timestamp = os.date('!%Y-%m-%dT%H:%M:%S'),
        footer = {text = 'Police MDT System'}
    }

    -- ARRESTATIONS
    if webhookType == 'arrests' then
        if eventType == 'arrest_created' then
            embed.title = '🚨 Nouvelle Arrestation'
            embed.description = string.format('**Suspect:** %s\n**Numéro:** %s\n**Agent:** %s',
                data.citizen_name, data.arrest_number, data.officer_name)
            embed.fields = {
                {name = 'Charges', value = data.charges_text or 'N/A', inline = false},
                {name = 'Amende', value = '$'..data.total_fine, inline = true},
                {name = 'Prison', value = data.total_jail_time..' min', inline = true},
                {name = 'Lieu', value = data.location, inline = false}
            }
        elseif eventType == 'arrest_processed' then
            embed.title = '✅ Arrestation Traitée'
            embed.description = string.format('**Suspect:** %s\n**Numéro:** %s', data.citizen_name, data.arrest_number)
        end

    -- RAPPORTS
    elseif webhookType == 'reports' then
        if eventType == 'report_created' then
            embed.title = '📝 Nouveau Rapport'
            embed.description = string.format('**Titre:** %s\n**Numéro:** %s\n**Agent:** %s',
                data.title, data.report_number, data.officer_name)
            embed.fields = {
                {name = 'Type', value = data.report_type, inline = true},
                {name = 'Lieu', value = data.location, inline = true}
            }
        elseif eventType == 'report_approved' then
            embed.title = '✅ Rapport Approuvé'
            embed.description = string.format('**Numéro:** %s\n**Approuvé par:** %s', data.report_number, data.approved_by_name)
        elseif eventType == 'report_rejected' then
            embed.title = '❌ Rapport Rejeté'
            embed.description = string.format('**Numéro:** %s\n**Raison:** %s', data.report_number, data.rejection_reason)
        end

    -- BOLO
    elseif webhookType == 'bolo' then
        if eventType == 'bolo_created' then
            embed.title = '🔍 Nouveau BOLO'
            embed.description = string.format('**Type:** %s\n**Sujet:** %s\n**Priorité:** %s',
                data.bolo_type == 'person' and 'Personne' or 'Véhicule', data.subject, data.priority)
            embed.fields = {
                {name = 'Description', value = data.description, inline = false},
                {name = 'Niveau de danger', value = data.danger_level, inline = true},
                {name = 'Émis par', value = data.issued_by_name, inline = true}
            }
        elseif eventType == 'bolo_closed' then
            embed.title = '✅ BOLO Fermé'
            embed.description = string.format('**Sujet:** %s\n**Fermé par:** %s', data.subject, data.closed_by_name)
        end

    -- CITATIONS
    elseif webhookType == 'citations' then
        if eventType == 'citation_issued' then
            embed.title = '🎫 Citation Émise'
            embed.description = string.format('**Citoyen:** %s\n**Numéro:** %s\n**Agent:** %s',
                data.citizen_name, data.citation_number, data.officer_name)
            embed.fields = {
                {name = 'Violation', value = data.violation_code..' - '..data.violation_description, inline = false},
                {name = 'Amende', value = '$'..data.fine_amount, inline = true},
                {name = 'Points', value = data.points, inline = true}
            }
        end

    -- MANDATS
    elseif webhookType == 'warrants' then
        if eventType == 'warrant_issued' then
            embed.title = '⚖️ Mandat Émis'
            embed.description = string.format('**Type:** %s\n**Numéro:** %s\n**Cible:** %s',
                data.warrant_type, data.warrant_number, data.citizen_name or data.address or 'N/A')
            embed.fields = {
                {name = 'Émis par', value = data.issued_by_name, inline = true},
                {name = 'Statut', value = data.status, inline = true}
            }
        elseif eventType == 'warrant_executed' then
            embed.title = '✅ Mandat Exécuté'
            embed.description = string.format('**Numéro:** %s\n**Exécuté par:** %s', data.warrant_number, data.executed_by_name)
        end

    -- PREUVES
    elseif webhookType == 'evidence' then
        if eventType == 'evidence_logged' then
            embed.title = '📦 Preuve Enregistrée'
            embed.description = string.format('**Numéro:** %s\n**Type:** %s\n**Agent:** %s',
                data.evidence_number, data.item_type, data.officer_name)
            embed.fields = {
                {name = 'Description', value = data.item_description, inline = false},
                {name = 'Saisi de', value = data.seized_from_name or 'N/A', inline = true},
                {name = 'Stockage', value = data.storage_location, inline = true}
            }
        elseif eventType == 'evidence_released' then
            embed.title = '📤 Preuve Restituée'
            embed.description = string.format('**Numéro:** %s\n**À:** %s', data.evidence_number, data.released_to)
        end

    -- PPA
    elseif webhookType == 'ppa' then
        if eventType == 'ppa_issued' then
            embed.title = '🔫 PPA Délivré'
            embed.description = string.format('**Citoyen:** %s\n**Numéro:** %s\n**Type:** %s',
                data.citizen_name, data.permit_number, data.permit_type)
            embed.fields = {
                {name = 'Classe', value = data.permit_class or 'Standard', inline = true},
                {name = 'Validité', value = 'Jusqu\'au '..data.expiry_date, inline = true},
                {name = 'Émis par', value = data.issued_by_name, inline = false}
            }
        elseif eventType == 'ppa_heavy_issued' then
            embed.title = '🎯 PPA LOURD Délivré'
            embed.description = string.format('**Citoyen:** %s\n**Numéro:** %s\n**Catégorie:** %s',
                data.citizen_name, data.permit_number, data.weapon_category)
            embed.color = 15158332 -- Rouge pour PPA Lourd
            embed.fields = {
                {name = 'Justification', value = data.justification, inline = false},
                {name = 'Approuvé par juge', value = data.approved_by_judge and 'Oui' or 'En attente', inline = true},
                {name = 'Validité', value = 'Jusqu\'au '..data.expiry_date, inline = true}
            }
        elseif eventType == 'ppa_revoked' then
            embed.title = '❌ PPA Révoqué'
            embed.description = string.format('**Citoyen:** %s\n**Raison:** %s', data.citizen_name, data.revocation_reason)
        end

    -- ADMIN (tous les events)
    elseif webhookType == 'admin' then
        embed.title = '⚙️ Activité Police MDT'
        embed.description = string.format('**Action:** %s\n**Agent:** %s', eventType, data.user_name or 'Système')
        embed.fields = {}
        for k, v in pairs(data) do
            if type(v) ~= 'table' and k ~= 'user_name' then
                table.insert(embed.fields, {name = k, value = tostring(v), inline = true})
            end
        end
    end

    return embed
end

-- ============================================
-- FONCTION UTILITAIRE
-- ============================================

function table.contains(tbl, element)
    for _, value in pairs(tbl) do
        if value == element then
            return true
        end
    end
    return false
end

-- ============================================
-- LOGGER DANS LA BASE DE DONNÉES
-- ============================================

function Webhooks.LogActivity(actionType, actionData, userIdentifier, userName, userJob)
    if not Config.Logging.enabled then return end

    MySQL.insert([[
        INSERT INTO zx_police_activity_log (action_type, action_data, user_identifier, user_name, user_job, webhook_sent)
        VALUES (?, ?, ?, ?, ?, 0)
    ]], {
        actionType,
        json.encode(actionData),
        userIdentifier,
        userName,
        userJob
    })
end

return Webhooks
