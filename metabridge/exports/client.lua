MetaBridgeClient = MetaBridgeClient or {}

local function exportWrapper(name)
    exports(name, function(...)
        local fn = MetaBridgeClient and MetaBridgeClient[name]
        if type(fn) ~= 'function' then
            return nil
        end
        return fn(...)
    end)
end

local function exportAll(tbl)
    if type(tbl) ~= 'table' then
        return
    end
    for name, fn in pairs(tbl) do
        if type(fn) == 'function' then
            exportWrapper(name)
        end
    end
end

exportAll(MetaBridgeClient)

local alwaysExport = {
    'getFramework',
    'isReady',
    'getPlayerData',
    'getIdentifier',
    'getJob',
    'onPlayerLoaded',
    'setFuel',
    'giveVehicleKeys',
    'spawnPed',
    'spawnVehicle',
    'setEntityAsNoLongerNeeded',
    'getItemLabel',
    'getItemImage',
    'getItemCount',
    'hasItem',
    'displayMetadata',
    'notify',
    'progressBar',
    'registerContext',
    'showContext',
    'requestCallback',
    'requestCallbackAwait',
    'inputDialog',
    'addTargetModel',
    'addTargetBoxZone',
    'addTargetSphereZone',
    'removeTargetZone',
    'showTextUI',
    'hideTextUI',
    'isTextUIOpen'
}

for _, name in ipairs(alwaysExport) do
    exportWrapper(name)
end
