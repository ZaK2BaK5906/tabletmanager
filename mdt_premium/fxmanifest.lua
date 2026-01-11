fx_version 'cerulean'
game 'gta5'

author 'MDT Premium Team'
description 'Tablette MDT Premium pour Entreprises ESX - California Edition 🇺🇸'
version '2.0.0'

lua54 'yes'

-- Dependencies
dependencies {
    'es_extended',
    'oxmysql',
    'esx_billing'
}

-- Server
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

-- Client
client_scripts {
    'client/main.lua'
}

-- NUI
ui_page 'nui/dist/index.html'

files {
    'nui/dist/**/*'
}
