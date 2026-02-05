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
    'setFuel',
    'giveVehicleKeys',
    'spawnPed',
    'spawnVehicle',
    'setEntityAsNoLongerNeeded',
    'getItemLabel',
    'getItemImage',
    'notify',
    'requestCallback',
    'addTargetModel'
}

for _, name in ipairs(alwaysExport) do
    exportWrapper(name)
end
