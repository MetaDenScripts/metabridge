BridgeAdapters = BridgeAdapters or {}

BridgeAdapters.vrp = {
    name = 'vrp'
}

local vRP = nil

local function getvRP()
    if vRP then
        return vRP
    end

    if type(module) == 'function' then
        local ok, Proxy = pcall(function()
            return module('vrp', 'lib/Proxy')
        end)

        if ok and Proxy and Proxy.getInterface then
            vRP = Proxy.getInterface('vRP')
        end
    end

    return vRP
end

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

function BridgeAdapters.vrp.getPlayer(source)
    local vrp = getvRP()
    if not vrp or not vrp.getUserId then
        return nil
    end

    return vrp.getUserId({ source })
end

function BridgeAdapters.vrp.getPlayerData(source)
    local userId = BridgeAdapters.vrp.getPlayer(source)
    if not userId then
        return nil
    end

    return { user_id = userId }
end

function BridgeAdapters.vrp.getIdentifier(source)
    local userId = BridgeAdapters.vrp.getPlayer(source)
    if not userId then
        return nil
    end

    return tostring(userId)
end

function BridgeAdapters.vrp.getJob(source)
    return nil
end

function BridgeAdapters.vrp.getMoney(source, moneyType)
    local vrp = getvRP()
    if not vrp or not vrp.getUserId or not vrp.getMoney then
        return nil
    end

    local userId = vrp.getUserId({ source })
    if not userId then
        return nil
    end

    return vrp.getMoney({ userId })
end

function BridgeAdapters.vrp.hasItem(source, itemName, amount)
    local vrp = getvRP()
    if not vrp or not vrp.getUserId or not vrp.getInventoryItemAmount then
        return false
    end

    local userId = vrp.getUserId({ source })
    if not userId then
        return false
    end

    local count = vrp.getInventoryItemAmount({ userId, itemName })
    amount = amount or 1
    return (count or 0) >= amount
end

function BridgeAdapters.vrp.getItemData(source, itemName, meta)
    local vrp = getvRP()
    if not vrp or not vrp.getUserId or not vrp.getInventoryItemAmount then
        return nil
    end

    local userId = vrp.getUserId({ source })
    if not userId then
        return nil
    end

    local count = vrp.getInventoryItemAmount({ userId, itemName })
    return { count = count or 0 }
end

function BridgeAdapters.vrp.getItemCount(source, itemName, meta)
    local data = BridgeAdapters.vrp.getItemData(source, itemName, meta)
    return data and data.count or 0
end

function BridgeAdapters.vrp.addItem(source, itemName, amount, meta)
    local vrp = getvRP()
    if not vrp or not vrp.getUserId or not vrp.giveInventoryItem then
        return false
    end

    local userId = vrp.getUserId({ source })
    if not userId then
        return false
    end

    vrp.giveInventoryItem({ userId, itemName, amount or 1 })
    return true
end

function BridgeAdapters.vrp.removeItem(source, itemName, amount, meta)
    local vrp = getvRP()
    if not vrp or not vrp.getUserId or not vrp.tryGetInventoryItem then
        return false
    end

    local userId = vrp.getUserId({ source })
    if not userId then
        return false
    end

    return vrp.tryGetInventoryItem({ userId, itemName, amount or 1 }) == true
end

function BridgeAdapters.vrp.setFuel(vehicle, fuel)
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

function BridgeAdapters.vrp.giveVehicleKeys(source, plate)
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
