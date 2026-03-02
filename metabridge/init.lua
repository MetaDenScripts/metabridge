if GetCurrentResourceName() == 'metabridge' then
    return
end

local resource = 'metabridge'
if GetResourceState(resource) == 'missing' then
    resource = GetCurrentResourceName()
end

BridgeConfig = BridgeConfig or {}
BridgeConfig.debug = false

local function loadFile(path)
    local chunk = LoadResourceFile(resource, path)
    if not chunk then
        return
    end

    local fn, err = load(chunk, ('@@%s/%s'):format(resource, path))
    if not fn then
        error(err)
    end

    return fn()
end

loadFile('resource/shared.lua')

if IsDuplicityVersion() then
    loadFile('resource/bridge.lua')
    loadFile('resource/inventory.lua')
    loadFile('links/dispatch/server.lua')

    loadFile('links/frameworks/standalone.lua')
    loadFile('links/frameworks/esx.lua')
    loadFile('links/frameworks/ox.lua')
    loadFile('links/frameworks/qbcore.lua')
    loadFile('links/frameworks/qbox.lua')
    loadFile('links/frameworks/vrp.lua')

    loadFile('links/inventories/framework.lua')
    loadFile('links/inventories/ox_inventory.lua')
    loadFile('links/inventories/qb_inventory.lua')
    loadFile('links/inventories/ps_inventory.lua')
    loadFile('links/inventories/qs_inventory.lua')
    loadFile('links/inventories/codem_inventory.lua')
    loadFile('links/inventories/core_inventory.lua')
    loadFile('links/inventories/origen_inventory.lua')
    loadFile('links/inventories/ak47_inventory.lua')

    loadFile('exports/server.lua')
else
    loadFile('resource/client.lua')
    loadFile('links/dispatch/client.lua')
    loadFile('exports/client.lua')
end
