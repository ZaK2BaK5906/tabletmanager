fx_version 'cerulean'
game 'gta5'

author 'MDT Premium Team'
description 'Tablette MDT Premium pour Entreprises ESX - Design First'
version '1.0.0'

lua54 'yes'

-- Dependencies
dependencies {
    'es_extended',
    'oxmysql'
}

-- Shared
shared_scripts {
    '@es_extended/imports.lua',
    'config/config.lua',
    'config/modules.lua'
}

-- Server
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core/permissions.lua',
    'server/core/logger.lua',
    'server/core/callbacks.lua',
    'server/modules/company/main.lua',
    'server/modules/invoices/main.lua',
    'server/modules/taxes_doj/main.lua',
    'server/modules/commissions/main.lua',
    'server/modules/dealership/main.lua',
    'server/main.lua'
}

-- Client
client_scripts {
    'client/core/controls.lua',
    'client/core/keybinds.lua',
    'client/main.lua'
}

-- NUI
ui_page 'nui/dist/index.html'

files {
    'nui/dist/**/*'
}
