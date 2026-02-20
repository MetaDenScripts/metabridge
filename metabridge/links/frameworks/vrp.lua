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
    return BridgeShared.setFuel(vehicle, fuel)
end

function BridgeAdapters.vrp.giveVehicleKeys(source, plate)
    return BridgeShared.giveVehicleKeys(source, plate)
end
