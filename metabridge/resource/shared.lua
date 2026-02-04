BridgeShared = BridgeShared or {}

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
