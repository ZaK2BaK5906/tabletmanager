-- ============================================
-- B_ADMIN2 - SYSTÈME DE TICKETS/REPORTS
-- ============================================

--- Créer un ticket
RegisterNetEvent('badmin:createTicket', function(data)
    local source = source
    local license = GetPlayerLicense(source)
    local discord = GetDiscordIdentifier(source)
    local name = GetPlayerName(source)

    if not data.category or not data.title or not data.description then
        TriggerClientEvent('badmin:notify', source, '❌ Données incomplètes')
        return
    end

    -- Check max open tickets
    local openCount = MySQL.scalar.await('SELECT COUNT(*) FROM `z_admin_tickets` WHERE `reporter_license` = ? AND `status` IN ("open", "assigned", "in_progress")', {
        license
    })

    if openCount >= Config.Tickets.MaxOpenPerPlayer then
        TriggerClientEvent('badmin:notify', source, string.format('❌ Vous avez déjà %d tickets ouverts', Config.Tickets.MaxOpenPerPlayer))
        return
    end

    -- Auto-priority based on keywords
    local priority = data.priority or 'normal'
    if Config.Tickets.AutoPriorityKeywords then
        local desc = data.description:lower()
        for level, keywords in pairs(Config.Tickets.AutoPriorityKeywords) do
            for _, keyword in ipairs(keywords) do
                if desc:find(keyword) then
                    priority = level
                    break
                end
            end
        end
    end

    -- Insert ticket
    local ticketId = MySQL.insert.await('INSERT INTO `z_admin_tickets` (`reporter_license`, `reporter_discord_id`, `reporter_name`, `reported_license`, `reported_discord_id`, `reported_name`, `category`, `priority`, `title`, `description`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        license,
        discord,
        name,
        data.reported_license or nil,
        data.reported_discord or nil,
        data.reported_name or nil,
        data.category,
        priority,
        data.title,
        data.description
    })

    -- Timeline: created
    MySQL.insert('INSERT INTO `z_admin_ticket_timeline` (`ticket_id`, `actor_license`, `actor_name`, `event_type`, `event_data`) VALUES (?, ?, ?, ?, ?)', {
        ticketId, license, name, 'created', json.encode({ category = data.category, priority = priority })
    })

    TriggerClientEvent('badmin:notify', source, '✅ Ticket créé #' .. ticketId)

    -- Auto-assign
    if Config.Tickets.AutoAssign then
        -- Trouver staff dispo (TODO: logique plus complexe)
        local staffOnline = {}
        for _, playerId in ipairs(GetPlayers()) do
            if IsStaff(tonumber(playerId)) then
                table.insert(staffOnline, playerId)
            end
        end

        if #staffOnline > 0 then
            local assigned = staffOnline[math.random(#staffOnline)]
            MySQL.update('UPDATE `z_admin_tickets` SET `status` = "assigned", `assigned_to` = ?, `assigned_at` = NOW() WHERE `id` = ?', {
                GetPlayerLicense(assigned), ticketId
            })
            TriggerClientEvent('badmin:notify', assigned, string.format('📋 Nouveau ticket assigné: #%d - %s', ticketId, data.title))
        end
    end

    -- Webhook Discord
    if Config.Webhooks.reports then
        local embed = {
            title = '📋 Nouveau Ticket: ' .. data.title,
            description = string.format('**Reporter:** %s\n**Catégorie:** %s\n**Priorité:** %s\n**Description:**\n%s',
                name, data.category, priority, data.description
            ),
            color = priority == 'urgent' and 16711680 or (priority == 'high' and 16776960 or 65280),
            footer = { text = 'Ticket ID: ' .. ticketId },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%S')
        }
        PerformHttpRequest(Config.Webhooks.reports, function() end, 'POST', json.encode({ embeds = { embed } }), { ['Content-Type'] = 'application/json' })
    end
end)

--- Get Tickets List
ESX.RegisterServerCallback('badmin:getTickets', function(source, cb, filter)
    if not HasPermission(source, 'admin.reports.view') then
        cb({})
        return
    end

    local query = 'SELECT * FROM `z_admin_tickets`'
    local params = {}

    if filter then
        if filter.status then
            query = query .. ' WHERE `status` = ?'
            table.insert(params, filter.status)
        elseif filter.my_tickets then
            query = query .. ' WHERE `assigned_to` = ?'
            table.insert(params, GetPlayerLicense(source))
        end
    end

    query = query .. ' ORDER BY FIELD(`priority`, "urgent", "high", "normal", "low"), `created_at` DESC LIMIT 50'

    local tickets = MySQL.query.await(query, params)
    cb(tickets or {})
end)

--- Resolve Ticket
RegisterNetEvent('badmin:resolveTicket', function(ticketId, resolutionNote, rating)
    local source = source
    if not HasPermission(source, 'admin.reports.manage') then
        TriggerClientEvent('badmin:notify', source, Config.Messages.NoPermission)
        return
    end

    local license = GetPlayerLicense(source)
    local name = GetPlayerName(source)

    MySQL.update('UPDATE `z_admin_tickets` SET `status` = "resolved", `resolved_by` = ?, `resolved_at` = NOW(), `resolution_note` = ? WHERE `id` = ?', {
        license, resolutionNote, ticketId
    })

    MySQL.insert('INSERT INTO `z_admin_ticket_timeline` (`ticket_id`, `actor_license`, `actor_name`, `event_type`, `event_data`) VALUES (?, ?, ?, ?, ?)', {
        ticketId, license, name, 'resolved', json.encode({ note = resolutionNote })
    })

    TriggerClientEvent('badmin:notify', source, '✅ Ticket résolu #' .. ticketId)

    LogStaffAction(source, nil, 'ticket_resolved', 'reports', { ticket_id = ticketId, note = resolutionNote }, true, nil, ticketId)
end)

print('^2[B_ADMIN2]^7 Système de Tickets chargé ✓')
