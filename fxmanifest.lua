fx_version 'cerulean'

game 'gta5'

lua54 'yes'

shared_scripts {
    'bridge/shared.lua',
    'bridge/adapters/qbcore.lua',
    'bridge/adapters/esx.lua',
    'bridge/adapters/qbox.lua',
    'bridge/bridge.lua'
}

client_scripts {
    'bridge/client.lua'
}

server_scripts {
    'bridge/example.lua'
}
