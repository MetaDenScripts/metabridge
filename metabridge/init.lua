local bridgeResource = 'metabridge'

if BridgeConfig and BridgeConfig.bridgeResource then
    bridgeResource = BridgeConfig.bridgeResource
end

local function loadBridge(path)
    local code = LoadResourceFile(bridgeResource, path)
    if not code then
        error(('[MetaBridge] Failed to load %s from %s'):format(path, bridgeResource))
    end

    local chunk, loadError = load(code, ('@@%s/%s'):format(bridgeResource, path))
    if not chunk then
        error(('[MetaBridge] Failed to compile %s: %s'):format(path, loadError or 'unknown error'))
    end

    return chunk()
end

loadBridge('metabridge/shared.lua')
loadBridge('metabridge/inventory.lua')
loadBridge('metabridge/inventories/framework.lua')
loadBridge('metabridge/inventories/ox_inventory.lua')
loadBridge('metabridge/inventories/ps_inventory.lua')
loadBridge('metabridge/inventories/qs_inventory.lua')
loadBridge('metabridge/inventories/codem_inventory.lua')
loadBridge('metabridge/inventories/core_inventory.lua')
loadBridge('metabridge/inventories/ak47_inventory.lua')
loadBridge('metabridge/inventories/origen_inventory.lua')
loadBridge('metabridge/inventories/qb_inventory.lua')
loadBridge('metabridge/adapters/qbcore.lua')
loadBridge('metabridge/adapters/esx.lua')
loadBridge('metabridge/adapters/qbox.lua')
loadBridge('metabridge/adapters/ox.lua')
loadBridge('metabridge/adapters/vrp.lua')
loadBridge('metabridge/adapters/standalone.lua')
loadBridge('metabridge/bridge.lua')

if IsDuplicityVersion and IsDuplicityVersion() then
    loadBridge('metabridge/dispatch_server.lua')
else
    loadBridge('metabridge/client.lua')
    loadBridge('metabridge/dispatch_client.lua')
end
