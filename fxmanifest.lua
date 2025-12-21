fx_version 'cerulean'
game 'gta5'

author 'ZaK2BaK5906'
description 'Tablette de gestion pour tous les jobs - ESX avec UI custom'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

dependencies {
    'es_extended',
    'oxmysql'
}

lua54 'yes'
