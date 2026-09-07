fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'bucu_multicharacter'
author 'BUCU SuperApp Team'
description 'Cinematic Multicharacter Selection, Citizen Registration & Spawn Selector for BUCU Scripts'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js'
}

shared_scripts {
    '@bucu_shared/shared/constants.lua',
    '@bucu_shared/shared/config.lua',
    '@bucu_shared/shared/items.lua',
    '@bucu_shared/shared/helpers.lua',
    'locales/en.lua',
    'locales/id.lua',
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_scripts {
    'client/nui.lua',
    'client/main.lua'
}
