BridgeAdapters = BridgeAdapters or {}

BridgeAdapters.qbcore = {
    name = 'qbcore'
}

local QBCore = nil

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

local function getCore()
    if not QBCore then
        QBCore = exports['qb-core']:GetCoreObject()
    end

    return QBCore
end

function BridgeAdapters.qbcore.getPlayer(source)
    local core = getCore()
    if not core or not core.Functions then
        return nil
    end

    return core.Functions.GetPlayer(source)
end

function BridgeAdapters.qbcore.getPlayerData(source)
    local player = BridgeAdapters.qbcore.getPlayer(source)
    return player and player.PlayerData or nil
end

function BridgeAdapters.qbcore.getIdentifier(source)
    local playerData = BridgeAdapters.qbcore.getPlayerData(source)
    return playerData and playerData.citizenid or nil
end

function BridgeAdapters.qbcore.getJob(source)
    local playerData = BridgeAdapters.qbcore.getPlayerData(source)
    return playerData and playerData.job or nil
end

function BridgeAdapters.qbcore.getMoney(source, moneyType)
    local player = BridgeAdapters.qbcore.getPlayer(source)
    local playerData = player and player.PlayerData or nil

    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    if player and player.Functions and player.Functions.GetMoney then
        return player.Functions.GetMoney(moneyType)
    end

    if not playerData or not playerData.money then
        return nil
    end

    return playerData.money[moneyType]
end

function BridgeAdapters.qbcore.hasItem(source, itemName, amount)
    local player = BridgeAdapters.qbcore.getPlayer(source)
    if not player or not player.Functions then
        return false
    end

    if player.Functions.HasItem then
        return player.Functions.HasItem(itemName, amount or 1)
    end

    local item = player.Functions.GetItemByName(itemName)
    if not item then
        return false
    end

    amount = amount or 1
    return item.amount >= amount
end

function BridgeAdapters.qbcore.getItemData(source, itemName, meta)
    local player = BridgeAdapters.qbcore.getPlayer(source)
    if not player or not player.Functions or not player.Functions.GetItemByName then
        return nil
    end

    return player.Functions.GetItemByName(itemName)
end

function BridgeAdapters.qbcore.getItemCount(source, itemName, meta)
    local data = BridgeAdapters.qbcore.getItemData(source, itemName, meta)
    if not data then
        return 0
    end

    return data.amount or data.count or 0
end

function BridgeAdapters.qbcore.addItem(source, itemName, amount, meta)
    local player = BridgeAdapters.qbcore.getPlayer(source)
    if not player or not player.Functions or not player.Functions.AddItem then
        return false
    end

    return player.Functions.AddItem(itemName, amount or 1, false, meta) == true
end

function BridgeAdapters.qbcore.removeItem(source, itemName, amount, meta)
    local player = BridgeAdapters.qbcore.getPlayer(source)
    if not player or not player.Functions or not player.Functions.RemoveItem then
        return false
    end

    return player.Functions.RemoveItem(itemName, amount or 1, false, meta) == true
end

function BridgeAdapters.qbcore.setFuel(vehicle, fuel)
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

function BridgeAdapters.qbcore.giveVehicleKeys(source, plate)
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
