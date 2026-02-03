BridgeClient = BridgeClient or {}

local function getResourceExport(resourceName, methodName)
    if not exports or not exports[resourceName] then
        return nil
    end

    local resource = exports[resourceName]
    local fn = resource[methodName]
    if type(fn) ~= 'function' then
        return nil
    end

    return function(...)
        return fn(resource, ...)
    end
end

function BridgeClient.getFramework()
    if BridgeShared and BridgeShared.detectFramework then
        return BridgeShared.detectFramework()
    end

    return nil
end

function BridgeClient.isReady()
    return BridgeClient.getFramework() ~= nil
end

function BridgeClient.setFuel(vehicle, fuel)
    if BridgeConfig and BridgeConfig.fuel and BridgeConfig.fuel.set then
        return BridgeConfig.fuel.set(vehicle, fuel)
    end

    local setFuel = getResourceExport('LegacyFuel', 'SetFuel')
        or getResourceExport('ps-fuel', 'SetFuel')
        or getResourceExport('cdn-fuel', 'SetFuel')

    if setFuel then
        return setFuel(vehicle, fuel)
    end

    if vehicle and DoesEntityExist(vehicle) then
        SetVehicleFuelLevel(vehicle, fuel)
        return true
    end

    return false
end

function BridgeClient.giveVehicleKeys(plate)
    if BridgeConfig and BridgeConfig.keysClient and BridgeConfig.keysClient.give then
        return BridgeConfig.keysClient.give(plate)
    end

    TriggerServerEvent('Bridge:giveVehicleKeys', plate)
    return true
end
