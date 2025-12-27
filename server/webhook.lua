-- ============================================
-- SYSTÈME DE WEBHOOKS DISCORD
-- Logs complets pour l'administration
-- ============================================

-- Fonction pour envoyer un webhook Discord
function SendWebhook(webhookType, data)
    -- Protection si Config.Webhooks n'existe pas
    if not Config or not Config.Webhooks then return end
    if not Config.Webhooks.Enabled then return end

    local webhookUrl = Config.Webhooks[webhookType]
    if not webhookUrl or webhookUrl == '' then return end

    -- Créer l'embed selon le type
    local embed = CreateWebhookEmbed(webhookType, data)
    if not embed then return end

    -- Envoyer le webhook
    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({
        username = Config.Webhooks.BotName or 'Tablet Manager',
        avatar_url = Config.Webhooks.BotAvatar or '',
        embeds = { embed }
    }), { ['Content-Type'] = 'application/json' })
end

-- Créer l'embed selon le type de webhook
function CreateWebhookEmbed(webhookType, data)
    local embed = {
        footer = {
            text = 'Tablet Manager System • ' .. os.date('%d/%m/%Y %H:%M:%S'),
            icon_url = Config.Webhooks.FooterIcon or ''
        }
    }

    -- FACTURES
    if webhookType == 'InvoiceCreated' then
        embed.title = '📄 Nouvelle Facture Créée'
        embed.color = 3447003 -- Bleu
        embed.description = string.format('**Facture #%s** créée par **%s**', data.invoiceId, data.employeeName)
        embed.fields = {
            { name = '🏢 Entreprise', value = data.jobLabel or data.job, inline = true },
            { name = '👤 Employé', value = data.employeeName, inline = true },
            { name = '💰 Montant Total', value = string.format('%.2f€', data.total), inline = true },
            { name = '📊 Commission', value = string.format('%.2f€ (%.1f%%)', data.commissionAmount, data.commissionPercent), inline = true },
            { name = '🎯 Type', value = data.invoiceType == 'citizen' and 'Citoyen' or 'Entreprise', inline = true },
            { name = '📍 Cible', value = data.targetName or data.targetCompany or 'N/A', inline = true },
        }

    elseif webhookType == 'InvoicePaid' then
        embed.title = '✅ Facture Payée'
        embed.color = 5763719 -- Vert
        embed.description = string.format('**Facture #%s** payée par **%s**', data.invoiceId, data.paidBy)
        embed.fields = {
            { name = '🏢 Entreprise', value = data.job, inline = true },
            { name = '💰 Montant', value = string.format('%.2f€', data.total), inline = true },
            { name = '💳 Payé par', value = data.paidBy, inline = true },
            { name = '📊 Commission versée', value = string.format('%.2f€', data.commissionAmount), inline = true },
            { name = '🏦 Ajouté à la société', value = string.format('%.2f€', data.societyAmount), inline = true },
        }

    elseif webhookType == 'InvoiceCancelled' then
        embed.title = '❌ Facture Annulée'
        embed.color = 15158332 -- Rouge
        embed.description = string.format('**Facture #%s** annulée', data.invoiceId)
        embed.fields = {
            { name = '🏢 Entreprise', value = data.job, inline = true },
            { name = '💰 Montant', value = string.format('%.2f€', data.total), inline = true },
            { name = '👤 Annulée par', value = data.cancelledBy, inline = true },
            { name = '📍 Statut précédent', value = data.previousStatus == 'paid' and '✅ Payée (Remboursée)' or '⏳ En attente', inline = true },
        }

    -- PRODUITS
    elseif webhookType == 'ProductAdded' then
        embed.title = '➕ Produit Ajouté'
        embed.color = 3066993 -- Vert clair
        embed.description = string.format('Nouveau produit **%s** ajouté', data.productName)
        embed.fields = {
            { name = '🏢 Entreprise', value = data.job, inline = true },
            { name = '📦 Produit', value = data.productName, inline = true },
            { name = '💰 Prix', value = string.format('%.2f€', data.price), inline = true },
            { name = '👤 Ajouté par', value = data.addedBy, inline = true },
        }

    elseif webhookType == 'ProductDeleted' then
        embed.title = '🗑️ Produit Supprimé'
        embed.color = 10038562 -- Orange
        embed.description = string.format('Produit **%s** supprimé', data.productName)
        embed.fields = {
            { name = '🏢 Entreprise', value = data.job, inline = true },
            { name = '📦 Produit', value = data.productName, inline = true },
            { name = '💰 Prix', value = string.format('%.2f€', data.price), inline = true },
            { name = '👤 Supprimé par', value = data.deletedBy, inline = true },
        }

    -- PARTENARIATS
    elseif webhookType == 'PartnershipAdded' then
        embed.title = '🤝 Partenariat Créé'
        embed.color = 3447003 -- Bleu
        embed.description = string.format('Partenariat avec **%s** établi', data.companyName)
        embed.fields = {
            { name = '🏢 Entreprise', value = data.job, inline = true },
            { name = '🤝 Partenaire', value = data.companyName, inline = true },
            { name = '💸 Remise', value = string.format('%.1f%%', data.discount), inline = true },
            { name = '👤 Créé par', value = data.addedBy, inline = true },
        }

    elseif webhookType == 'PartnershipDeleted' then
        embed.title = '💔 Partenariat Supprimé'
        embed.color = 15158332 -- Rouge
        embed.description = string.format('Partenariat avec **%s** terminé', data.companyName)
        embed.fields = {
            { name = '🏢 Entreprise', value = data.job, inline = true },
            { name = '🤝 Partenaire', value = data.companyName, inline = true },
            { name = '👤 Supprimé par', value = data.deletedBy, inline = true },
        }

    -- COMMISSIONS
    elseif webhookType == 'CommissionUpdated' then
        embed.title = '📊 Commission Modifiée'
        embed.color = 15844367 -- Or
        embed.description = string.format('Commission de **%s** modifiée', data.employeeName)
        embed.fields = {
            { name = '🏢 Entreprise', value = data.job, inline = true },
            { name = '👤 Employé', value = data.employeeName, inline = true },
            { name = '📉 Ancienne commission', value = string.format('%.1f%%', data.oldCommission), inline = true },
            { name = '📈 Nouvelle commission', value = string.format('%.1f%%', data.newCommission), inline = true },
            { name = '👤 Modifié par', value = data.modifiedBy, inline = true },
        }

    -- VENTES (RESET)
    elseif webhookType == 'SalesReset' then
        embed.title = '🔄 Réinitialisation des Ventes'
        embed.color = 10181046 -- Violet
        embed.description = 'Les statistiques de ventes ont été réinitialisées'
        embed.fields = {
            { name = '🏢 Entreprise', value = data.job, inline = true },
            { name = '👤 Réinitialisé par', value = data.resetBy, inline = true },
            { name = '📊 Factures affectées', value = tostring(data.affectedInvoices or 0), inline = true },
        }

    -- RECRUTEMENT
    elseif webhookType == 'JobApplication' then
        embed.title = '📝 Nouvelle Candidature'
        embed.color = 3447003 -- Bleu
        embed.description = string.format('**%s %s** a postulé', data.firstName, data.lastName)
        embed.fields = {
            { name = '🏢 Entreprise', value = data.jobLabel, inline = true },
            { name = '👤 Candidat', value = string.format('%s %s', data.firstName, data.lastName), inline = true },
            { name = '📞 Téléphone', value = data.phoneNumber, inline = true },
        }

        if data.experience and data.experience ~= '' then
            table.insert(embed.fields, { name = '💼 Expérience', value = data.experience, inline = false })
        end

        if data.motivation and data.motivation ~= '' then
            table.insert(embed.fields, { name = '💭 Motivation', value = data.motivation, inline = false })
        end

    elseif webhookType == 'ApplicationStatusChanged' then
        embed.title = '📋 Candidature Traitée'
        embed.color = data.newStatus == 'accepted' and 5763719 or 15158332 -- Vert ou Rouge
        embed.description = string.format('Candidature de **%s** : **%s**', data.applicantName,
            data.newStatus == 'accepted' and 'ACCEPTÉE ✅' or 'REFUSÉE ❌')
        embed.fields = {
            { name = '🏢 Entreprise', value = data.job, inline = true },
            { name = '👤 Candidat', value = data.applicantName, inline = true },
            { name = '📍 Décision', value = data.newStatus == 'accepted' and 'Accepté' or 'Refusé', inline = true },
            { name = '👤 Traité par', value = data.processedBy, inline = true },
        }

    elseif webhookType == 'RecruitmentStatusChanged' then
        embed.title = '🚪 Statut de Recrutement Modifié'
        embed.color = data.isRecruiting and 5763719 or 10038562 -- Vert ou Orange
        embed.description = string.format('**%s** : %s', data.jobLabel,
            data.isRecruiting and '✅ RECRUTEMENT OUVERT' or '🔒 RECRUTEMENT FERMÉ')
        embed.fields = {
            { name = '🏢 Entreprise', value = data.jobLabel, inline = true },
            { name = '📍 Nouveau statut', value = data.isRecruiting and 'Ouvert aux candidatures' or 'Fermé', inline = true },
            { name = '👤 Modifié par', value = data.modifiedBy, inline = true },
        }

    elseif webhookType == 'CompanyProfileUpdated' then
        embed.title = '✏️ Profil Entreprise Modifié'
        embed.color = 3447003 -- Bleu
        embed.description = string.format('Profil de **%s** mis à jour', data.jobLabel)
        embed.fields = {
            { name = '🏢 Entreprise', value = data.jobLabel, inline = true },
            { name = '👤 Modifié par', value = data.modifiedBy, inline = true },
        }

        if data.changes then
            local changesList = {}
            if data.changes.description then table.insert(changesList, '📝 Description') end
            if data.changes.photo then table.insert(changesList, '📷 Photo') end
            if data.changes.salary then table.insert(changesList, '💰 Informations salariales') end

            if #changesList > 0 then
                table.insert(embed.fields, { name = '🔄 Modifications', value = table.concat(changesList, '\n'), inline = false })
            end
        end

    else
        return nil
    end

    return embed
end

-- Exports pour les autres fichiers
_G.SendWebhook = SendWebhook
