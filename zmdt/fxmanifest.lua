fx_version 'cerulean'
game 'gta5'

name 'zmdt'
description 'MDT System - Police / DOJ / EMS'
author 'Claude AI'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/police.lua',
    'client/doj.lua',
    'client/ems.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/police.lua',
    'server/doj.lua',
    'server/ems.lua',
    'server/permissions.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/img/*.png',
    'html/img/*.jpg'
}

dependencies {
    'es_extended',
    'oxmysql'
}
