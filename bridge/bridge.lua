Bridge = Bridge or {}

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

function Bridge.init()
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

function Bridge.getFramework()
    if not activeFramework then
        Bridge.init()
    end

    return activeFramework
end

function Bridge.isReady()
    return Bridge.getFramework() ~= nil and activeAdapter ~= nil
end

function Bridge.register(methodName, handler)
    overrides[methodName] = handler
end

function Bridge.call(methodName, ...)
    if overrides[methodName] then
        return overrides[methodName](...)
    end

    if not activeAdapter then
        Bridge.init()
    end

    if not activeAdapter then
        error('Bridge has no active adapter.')
    end

    local handler = activeAdapter[methodName]
    if not handler then
        error(('Bridge method "%s" is not supported for %s.'):format(methodName, activeFramework or 'unknown'))
    end

    return handler(...)
end

function Bridge.getPlayer(source)
    return Bridge.call('getPlayer', source)
end

function Bridge.getPlayerData(source)
    return Bridge.call('getPlayerData', source)
end

function Bridge.getIdentifier(source)
    return Bridge.call('getIdentifier', source)
end

function Bridge.getJob(source)
    return Bridge.call('getJob', source)
end

function Bridge.getMoney(source, moneyType)
    return Bridge.call('getMoney', source, moneyType)
end

function Bridge.hasItem(source, itemName, amount)
    return Bridge.call('hasItem', source, itemName, amount)
end

function Bridge.setFuel(vehicle, fuel)
    return Bridge.call('setFuel', vehicle, fuel)
end

function Bridge.giveVehicleKeys(source, plate)
    return Bridge.call('giveVehicleKeys', source, plate)
end

if IsDuplicityVersion and IsDuplicityVersion() then
    RegisterNetEvent('Bridge:giveVehicleKeys', function(plate)
        local src = source
        Bridge.giveVehicleKeys(src, plate)
    end)
end
