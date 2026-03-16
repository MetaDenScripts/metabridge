BridgeShared = BridgeShared or {}
BridgeConfig = BridgeConfig or {}

if BridgeConfig.debug == nil then
    BridgeConfig.debug = false
end

function BridgeShared.isDebugEnabled()
    local cfg = BridgeConfig and BridgeConfig.debug
    if cfg == true then
        return true
    end

    if type(cfg) == 'table' then
        return cfg.enabled == true
    end

    return false
end

function BridgeShared.debug(scope, message, payload)
    if not BridgeShared.isDebugEnabled() then
        return
    end

    local prefix = ('[metabridge:%s] %s'):format(scope or 'core', message or '')

    if payload == nil then
        print(prefix)
        return
    end

    local encoded = nil
    if json and json.encode then
        local ok, result = pcall(json.encode, payload)
        if ok then
            encoded = result
        end
    end

    if encoded == nil then
        encoded = tostring(payload)
    end

    print(prefix .. ' | ' .. encoded)
end

function BridgeShared.resolveJobData(data)
    if type(data) ~= 'table' then
        return nil
    end

    if data.job ~= nil then
        return data.job
    end

    if data.PlayerData and type(data.PlayerData) == 'table' and data.PlayerData.job ~= nil then
        return data.PlayerData.job
    end

    if data.playerData and type(data.playerData) == 'table' and data.playerData.job ~= nil then
        return data.playerData.job
    end

    if data.metadata and type(data.metadata) == 'table' and data.metadata.job ~= nil then
        return data.metadata.job
    end

    if data.groups and type(data.groups) == 'table' then
        if data.groups.job ~= nil then
            return data.groups.job
        end

        for groupName, groupData in pairs(data.groups) do
            if type(groupData) == 'table' and (groupData.name ~= nil or groupData.grade ~= nil or groupData.level ~= nil) then
                if type(groupName) == 'string' and groupData.name == nil then
                    groupData.name = groupName
                end
                return groupData
            end
        end
    end

    return nil
end

function BridgeShared.resolveGangData(data)
    if type(data) ~= 'table' then
        return nil
    end

    if data.gang ~= nil then
        return data.gang
    end

    if data.PlayerData and type(data.PlayerData) == 'table' and data.PlayerData.gang ~= nil then
        return data.PlayerData.gang
    end

    if data.playerData and type(data.playerData) == 'table' and data.playerData.gang ~= nil then
        return data.playerData.gang
    end

    if data.groups and type(data.groups) == 'table' then
        if data.groups.gang ~= nil then
            return data.groups.gang
        end

        for groupName, groupData in pairs(data.groups) do
            if type(groupData) == 'table' and (groupData.label ~= nil or groupData.grade ~= nil or groupData.level ~= nil) then
                if type(groupName) == 'string' and groupData.name == nil then
                    groupData.name = groupName
                end
                return groupData
            end
        end
    end

    return nil
end

function BridgeShared.getExportFunction(resourceName, methodName, requireStarted)
    if requireStarted ~= false and BridgeShared.isStarted and not BridgeShared.isStarted(resourceName) then
        return nil
    end

    if not exports or not exports[resourceName] then
        return nil
    end

    local resource = exports[resourceName]
    local ok, fn = pcall(function()
        return resource[methodName]
    end)
    if not ok or type(fn) ~= 'function' then
        return nil
    end

    return function(...)
        local args = { ... }

        local invokeOk, result = pcall(function()
            return fn(table.unpack(args))
        end)
        if invokeOk and result ~= nil then
            return result
        end

        local invokeOkWithSelf, resultWithSelf = pcall(function()
            return fn(resource, table.unpack(args))
        end)
        if invokeOkWithSelf then
            return resultWithSelf
        end

        return nil
    end
end

function BridgeShared.normalizeNotifyPayload(data)
    if type(data) == 'string' then
        return { description = data, type = 'inform' }
    end

    if type(data) == 'table' then
        if data.message and not data.description then
            data.description = data.message
        end
        return data
    end

    return { description = tostring(data), type = 'inform' }
end

function BridgeShared.callStartedResourceMethods(resourceName, methodNames, ...)
    if not BridgeShared.isStarted(resourceName) then
        return nil, false
    end

    for _, methodName in ipairs(methodNames) do
        local fn = BridgeShared.getExportFunction(resourceName, methodName, true)
        if fn then
            local result = fn(...)
            if result ~= nil then
                return result, true
            end
        end
    end

    return nil, true
end

function BridgeShared.setFuel(vehicle, fuel)
    if BridgeConfig and BridgeConfig.fuel and BridgeConfig.fuel.set then
        return BridgeConfig.fuel.set(vehicle, fuel)
    end

    local result, started = BridgeShared.callStartedResourceMethods('LegacyFuel', { 'SetFuel' }, vehicle, fuel)
    if result ~= nil then
        return result
    end
    if started then
        return true
    end

    result = BridgeShared.getExportFunction('ps-fuel', 'SetFuel', true)
    if result then
        local value = result(vehicle, fuel)
        if value ~= nil then
            return value
        end
    end

    result = BridgeShared.getExportFunction('cdn-fuel', 'SetFuel', true)
    if result then
        local value = result(vehicle, fuel)
        if value ~= nil then
            return value
        end
    end

    return false
end

function BridgeShared.giveVehicleKeys(source, plate, systems)
    if BridgeConfig and BridgeConfig.keys and BridgeConfig.keys.give then
        return BridgeConfig.keys.give(source, plate)
    end

    systems = systems or {
        { resource = 'qb-vehiclekeys', methods = { 'GiveKeys', 'AddKeys' }, successOnStarted = true }
    }

    for _, system in ipairs(systems) do
        local methods = system.methods or {}
        local result, started = BridgeShared.callStartedResourceMethods(system.resource, methods, source, plate)
        if result ~= nil then
            return result
        end

        if started and system.successOnStarted ~= false then
            return true
        end
    end

    return false
end

local frameworkAliases = {
    ['qbcore'] = 'qbcore',
    ['qb-core'] = 'qbcore',
    ['qb'] = 'qbcore',
    ['esx'] = 'esx',
    ['es_extended'] = 'esx',
    ['qbox'] = 'qbox',
    ['qbx'] = 'qbox',
    ['qbx_core'] = 'qbox',
    ['qbx-core'] = 'qbox',
    ['ox'] = 'ox',
    ['ox_core'] = 'ox',
    ['ox-core'] = 'ox',
    ['vrp'] = 'vrp',
    ['vRP'] = 'vrp',
    ['vRP-framework'] = 'vrp',
    ['standalone'] = 'standalone',
    ['none'] = 'standalone'
}

function BridgeShared.getResourceState(resourceName)
    if GetResourceState then
        return GetResourceState(resourceName)
    end

    return 'missing'
end

function BridgeShared.isStarted(resourceName)
    return BridgeShared.getResourceState(resourceName) == 'started'
end

function BridgeShared.normalizeFramework(name)
    if not name then
        return nil
    end

    local key = tostring(name):lower()
    return frameworkAliases[key]
end

function BridgeShared.detectFramework()
    local candidates = {
        { resource = 'qbx_core', name = 'qbox' },
        { resource = 'qbx-core', name = 'qbox' },
        { resource = 'qb-core', name = 'qbcore' },
        { resource = 'es_extended', name = 'esx' },
        { resource = 'ox_core', name = 'ox' },
        { resource = 'vRP', name = 'vrp' },
        { resource = 'vrp', name = 'vrp' },
        { resource = 'vRP-framework', name = 'vrp' }
    }

    for _, entry in ipairs(candidates) do
        if BridgeShared.isStarted(entry.resource) then
            return entry.name
        end
    end

    return nil
end

local inventoryAliases = {
    ['framework'] = 'framework',
    ['qb-inventory'] = 'qb-inventory',
    ['qb_inventory'] = 'qb-inventory',
    ['ox'] = 'ox_inventory',
    ['ox_inventory'] = 'ox_inventory',
    ['qs'] = 'qs-inventory',
    ['qs-inventory'] = 'qs-inventory',
    ['ps'] = 'ps-inventory',
    ['ps-inventory'] = 'ps-inventory',
    ['codem'] = 'codem-inventory',
    ['codem-inventory'] = 'codem-inventory',
    ['core'] = 'core_inventory',
    ['core_inventory'] = 'core_inventory',
    ['ak47'] = 'ak47_inventory',
    ['ak47_inventory'] = 'ak47_inventory',
    ['origen'] = 'origen_inventory',
    ['origen_inventory'] = 'origen_inventory'
}

function BridgeShared.normalizeInventory(name)
    if not name then
        return nil
    end

    local key = tostring(name):lower()
    return inventoryAliases[key]
end

function BridgeShared.detectInventory()
    local candidates = {
        { resource = 'ox_inventory', name = 'ox_inventory' },
        { resource = 'qs-inventory', name = 'qs-inventory' },
        { resource = 'ps-inventory', name = 'ps-inventory' },
        { resource = 'ak47_inventory', name = 'ak47_inventory' },
        { resource = 'codem-inventory', name = 'codem-inventory' },
        { resource = 'core_inventory', name = 'core_inventory' },
        { resource = 'origen_inventory', name = 'origen_inventory' },
        { resource = 'qb-inventory', name = 'qb-inventory' }
    }

    for _, entry in ipairs(candidates) do
        if BridgeShared.isStarted(entry.resource) then
            return entry.name
        end
    end

    return 'framework'
end

local dispatchAliases = {
    ['ps'] = 'ps',
    ['ps-dispatch'] = 'ps',
    ['qs'] = 'qs',
    ['qs-dispatch'] = 'qs',
    ['rcore'] = 'rcore',
    ['rcore_dispatch'] = 'rcore',
    ['cd'] = 'cd',
    ['cd_dispatch'] = 'cd',
    ['standalone'] = 'standalone'
}

function BridgeShared.normalizeDispatch(name)
    if not name then
        return nil
    end

    local key = tostring(name):lower()
    return dispatchAliases[key]
end

function BridgeShared.detectDispatch()
    local candidates = {
        { resource = 'ps-dispatch', name = 'ps' },
        { resource = 'qs-dispatch', name = 'qs' },
        { resource = 'rcore_dispatch', name = 'rcore' },
        { resource = 'cd_dispatch', name = 'cd' }
    }

    for _, entry in ipairs(candidates) do
        if BridgeShared.isStarted(entry.resource) then
            return entry.name
        end
    end

    return 'standalone'
end
