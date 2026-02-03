MetaBridge = MetaBridge or {}

local activeAdapter = nil
local activeFramework = nil
local overrides = {}

local function resolveFramework()
    if BridgeConfig and BridgeConfig.framework then
        return BridgeConfig.framework
    end

    if BridgeShared and BridgeShared.detectFramework then
        return BridgeShared.detectFramework()
    end

    return nil
end

function MetaBridge.init()
    activeFramework = resolveFramework()
    if not activeFramework then
        activeAdapter = nil
        return nil
    end

    if BridgeAdapters and BridgeAdapters[activeFramework] then
        activeAdapter = BridgeAdapters[activeFramework]
        if activeAdapter.init then
            activeAdapter.init()
        end
    else
        activeAdapter = nil
    end

    return activeFramework
end

function MetaBridge.getFramework()
    if not activeFramework then
        MetaBridge.init()
    end

    return activeFramework
end

function MetaBridge.isReady()
    return MetaBridge.getFramework() ~= nil and activeAdapter ~= nil
end

function MetaBridge.register(methodName, handler)
    overrides[methodName] = handler
end

function MetaBridge.call(methodName, ...)
    if overrides[methodName] then
        return overrides[methodName](...)
    end

    if not activeAdapter then
        MetaBridge.init()
    end

    if not activeAdapter then
        error('MetaBridge has no active adapter.')
    end

    local handler = activeAdapter[methodName]
    if not handler then
        error(('MetaBridge method "%s" is not supported for %s.'):format(methodName, activeFramework or 'unknown'))
    end

    return handler(...)
end

function MetaBridge.getPlayer(source)
    return MetaBridge.call('getPlayer', source)
end

function MetaBridge.getPlayerData(source)
    return MetaBridge.call('getPlayerData', source)
end

function MetaBridge.getIdentifier(source)
    return MetaBridge.call('getIdentifier', source)
end

function MetaBridge.getJob(source)
    return MetaBridge.call('getJob', source)
end

function MetaBridge.getMoney(source, moneyType)
    return MetaBridge.call('getMoney', source, moneyType)
end

function MetaBridge.hasItem(source, itemName, amount)
    return MetaBridge.call('hasItem', source, itemName, amount)
end

function MetaBridge.setFuel(vehicle, fuel)
    return MetaBridge.call('setFuel', vehicle, fuel)
end

function MetaBridge.giveVehicleKeys(source, plate)
    return MetaBridge.call('giveVehicleKeys', source, plate)
end

if IsDuplicityVersion and IsDuplicityVersion() then
    RegisterNetEvent('MetaBridge:giveVehicleKeys', function(plate)
        local src = source
        MetaBridge.giveVehicleKeys(src, plate)
    end)
end
