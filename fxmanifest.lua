fx_version 'cerulean'

game 'gta5'

lua54 'yes'

shared_scripts {
    'metabridge/shared.lua',
    'metabridge/inventory.lua',
    'metabridge/inventories/framework.lua',
    'metabridge/inventories/ox_inventory.lua',
    'metabridge/inventories/ps_inventory.lua',
    'metabridge/inventories/qs_inventory.lua',
    'metabridge/inventories/codem_inventory.lua',
    'metabridge/inventories/core_inventory.lua',
    'metabridge/inventories/ak47_inventory.lua',
    'metabridge/inventories/origen_inventory.lua',
    'metabridge/inventories/qb_inventory.lua',
    'metabridge/adapters/qbcore.lua',
    'metabridge/adapters/esx.lua',
    'metabridge/adapters/qbox.lua',
    'metabridge/adapters/ox.lua',
    'metabridge/adapters/vrp.lua',
    'metabridge/adapters/standalone.lua',
    'metabridge/bridge.lua'
}

client_scripts {
    'metabridge/client.lua',
    'metabridge/dispatch_client.lua'
}

server_scripts {
    'metabridge/dispatch_server.lua',
    'metabridge/example.lua'
}
