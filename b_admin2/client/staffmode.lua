-- ============================================
-- B_ADMIN2 - STAFF MODE
-- ============================================

local staffModeEnabled = false

RegisterNetEvent('badmin:setStaffMode', function(enabled)
    staffModeEnabled = enabled

    local ped = PlayerPedId()

    if enabled then
        -- God Mode
        if Config.StaffMode.EnableGodMode then
            SetEntityInvincible(ped, true)
        end

        -- Invisible
        if Config.StaffMode.EnableInvisible then
            SetEntityVisible(ped, false, false)
            SetEntityAlpha(ped, 0, false)
        end

        -- Noclip (via commande externe ou native)
        if Config.StaffMode.EnableNoclip then
            -- Trigger noclip (assume ressource externe ou commande)
            -- ExecuteCommand('noclip')
        end
    else
        -- Restore
        SetEntityInvincible(ped, false)
        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
    end
end)

-- ============================================
-- WATERMARK
-- ============================================

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if staffModeEnabled and Config.StaffMode.ShowWatermark then
            local text = Config.StaffMode.WatermarkText or '🛡️ STAFF MODE'
            local x = Config.StaffMode.WatermarkPosition.x or 0.5
            local y = Config.StaffMode.WatermarkPosition.y or 0.95

            SetTextFont(4)
            SetTextScale(0.5, 0.5)
            SetTextColour(255, 215, 0, 255) -- Gold
            SetTextDropshadow(0, 0, 0, 0, 255)
            SetTextEdge(2, 0, 0, 0, 255)
            SetTextEntry('STRING')
            AddTextComponentString(text)
            DrawText(x, y)
        end
    end
end)

print('^2[B_ADMIN2]^7 Client Staff Mode chargé ✓')
