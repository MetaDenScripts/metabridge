BridgeAdapters = BridgeAdapters or {}

BridgeAdapters.standalone = {
    name = 'standalone'
}

local function callExport(resourceName, methodName, ...)
    if not exports or not exports[resourceName] then
        return nil
    end

    local resource = exports[resourceName]
    local fn = resource[methodName]
    if type(fn) ~= 'function' then
        return nil
    end

    return fn(resource, ...)
end

function BridgeAdapters.standalone.getPlayer(source)
    return nil
end

function BridgeAdapters.standalone.getPlayerData(source)
    return nil
end

function BridgeAdapters.standalone.getIdentifier(source)
    return GetPlayerIdentifierByType(source, 'license')
end

function BridgeAdapters.standalone.getJob(source)
    return nil
end

function BridgeAdapters.standalone.getMoney(source, moneyType)
    return nil
end

function BridgeAdapters.standalone.hasItem(source, itemName, amount)
    return false
end

function BridgeAdapters.standalone.getItemData(source, itemName, meta)
    return nil
end

function BridgeAdapters.standalone.getItemCount(source, itemName, meta)
    return 0
end

function BridgeAdapters.standalone.addItem(source, itemName, amount, meta)
    return false
end

function BridgeAdapters.standalone.removeItem(source, itemName, amount, meta)
    return false
end

function BridgeAdapters.standalone.setFuel(vehicle, fuel)
    if BridgeConfig and BridgeConfig.fuel and BridgeConfig.fuel.set then
        return BridgeConfig.fuel.set(vehicle, fuel)
    end

    if BridgeShared and BridgeShared.isStarted then
        if BridgeShared.isStarted('LegacyFuel') then
            local result = callExport('LegacyFuel', 'SetFuel', vehicle, fuel)
            if result ~= nil then
                return result
            end
            return true
        end

        if BridgeShared.isStarted('ps-fuel') then
            local result = callExport('ps-fuel', 'SetFuel', vehicle, fuel)
            if result ~= nil then
                return result
            end
        end

        if BridgeShared.isStarted('cdn-fuel') then
            local result = callExport('cdn-fuel', 'SetFuel', vehicle, fuel)
            if result ~= nil then
                return result
            end
        end
    end

    return false
end

function BridgeAdapters.standalone.giveVehicleKeys(source, plate)
    if BridgeConfig and BridgeConfig.keys and BridgeConfig.keys.give then
        return BridgeConfig.keys.give(source, plate)
    end

    if BridgeShared and BridgeShared.isStarted then
        if BridgeShared.isStarted('qb-vehiclekeys') then
            local result = callExport('qb-vehiclekeys', 'GiveKeys', source, plate)
            if result ~= nil then
                return result
            end

            result = callExport('qb-vehiclekeys', 'AddKeys', source, plate)
            if result ~= nil then
                return result
            end

            return true
        end
    end

    return false
end
