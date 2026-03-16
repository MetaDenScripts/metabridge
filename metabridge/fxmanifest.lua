fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Ianarosh | MetaDen Scripts'
description 'MetaDen Scripts | Bridge implementation to support various frameworks and inventories.'
version '1.0.4'

shared_scripts {
    '@ox_lib/init.lua',
    'resource/shared.lua',
    'init.lua'
}

client_scripts {
    'resource/client.lua',
    'links/dispatch/client.lua',
    'exports/client.lua'
}

server_scripts {
    'resource/bridge.lua',
    'resource/jobs.lua',
    'resource/inventory.lua',
    'links/dispatch/server.lua',
    'links/frameworks/*.lua',
    'links/inventories/*.lua',
    'exports/server.lua'
}

files {
    'resource/*.lua',
    'links/dispatch/*.lua',
    'exports/*.lua'
}

escrow_ignore {
    '**',
}

dependencies {
    'ox_lib'
}