fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Ianarosh (FabioRosado)'
description 'MetaDen Scripts | Bridge implementation to support various frameworks and inventories.'
version '1.0.0'
repository 'https://github.com/MetaDenScripts/metabridge'
documentation 'https://github.com/MetaDenScripts/metabridge/tree/main/docs'

shared_scripts {
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