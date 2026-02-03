BridgeAdapters = BridgeAdapters or {}

BridgeAdapters.esx = {
    name = 'esx'
}

local ESX = nil

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

local function getESX()
    if not ESX then
        ESX = exports['es_extended']:getSharedObject()
    end

    return ESX
end

function BridgeAdapters.esx.getPlayer(source)
    local esx = getESX()
    if not esx then
        return nil
    end

    return esx.GetPlayerFromId(source)
end

function BridgeAdapters.esx.getPlayerData(source)
    local player = BridgeAdapters.esx.getPlayer(source)
    if not player then
        return nil
    end

    if player.getData then
        return player.getData()
    end

    return player
end

function BridgeAdapters.esx.getIdentifier(source)
    local player = BridgeAdapters.esx.getPlayer(source)
    return player and player.identifier or nil
end

function BridgeAdapters.esx.getJob(source)
    local player = BridgeAdapters.esx.getPlayer(source)
    return player and player.job or nil
end

function BridgeAdapters.esx.getMoney(source, moneyType)
    local player = BridgeAdapters.esx.getPlayer(source)
    if not player then
        return nil
    end

    if moneyType == 'bank' and player.getAccount then
        local account = player.getAccount('bank')
        return account and account.money or nil
    end

    if player.getMoney then
        return player.getMoney()
    end

    return nil
end

function BridgeAdapters.esx.hasItem(source, itemName, amount)
    local player = BridgeAdapters.esx.getPlayer(source)
    if not player or not player.getInventoryItem then
        return false
    end

    local item = player.getInventoryItem(itemName)
    if not item then
        return false
    end

    amount = amount or 1
    return item.count >= amount
end

function BridgeAdapters.esx.setFuel(vehicle, fuel)
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

function BridgeAdapters.esx.giveVehicleKeys(source, plate)
    if BridgeConfig and BridgeConfig.keys and BridgeConfig.keys.give then
        return BridgeConfig.keys.give(source, plate)
    end

    if BridgeShared and BridgeShared.isStarted then
        if BridgeShared.isStarted('esx_vehiclelock') then
            local result = callExport('esx_vehiclelock', 'givePlayerKeys', source, plate)
            if result ~= nil then
                return result
            end

            result = callExport('esx_vehiclelock', 'GiveKeys', source, plate)
            if result ~= nil then
                return result
            end

            return true
        end
    end

    return false
end
