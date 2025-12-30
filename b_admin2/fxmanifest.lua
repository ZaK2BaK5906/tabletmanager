fx_version 'cerulean'
game 'gta5'

author 'B_Admin2 Team'
description 'Système d\'administration FiveM ultra-complet avec NUI vanilla + Bot Discord'
version '1.0.0'

lua54 'yes'

-- Dépendances
dependencies {
    'es_extended',
    'oxmysql',
    'ox_inventory'
}

-- Scripts partagés
shared_scripts {
    '@es_extended/imports.lua',
    'config/*.lua'
}

-- Scripts serveur
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/utils/*.lua',
    'server/permissions.lua',
    'server/logging.lua',
    'server/nui_callbacks.lua',
    'server/actions/*.lua',
    'server/discord_api.lua',
    'server/tickets.lua',
    'server/main.lua'
}

-- Scripts client
client_scripts {
    'client/utils/*.lua',
    'client/spectate.lua',
    'client/staffmode.lua',
    'client/nui.lua',
    'client/main.lua'
}

-- UI (NUI)
ui_page 'nui/html/index.html'

files {
    'nui/html/index.html',
    'nui/css/*.css',
    'nui/js/*.js'
}
