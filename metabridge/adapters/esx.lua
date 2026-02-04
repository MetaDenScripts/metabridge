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
        if exports and exports['es_extended'] and exports['es_extended'].getSharedObject then
            ESX = exports['es_extended']:getSharedObject()
        end

        if not ESX then
            TriggerEvent('esx:getSharedObject', function(obj)
                ESX = obj
            end)
        end
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

    moneyType = moneyType or 'money'
    if moneyType == 'cash' then
        moneyType = 'money'
    end

    if moneyType ~= 'money' and player.getAccount then
        local account = player.getAccount(moneyType)
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
    local itemCount = item.count or item.amount or 0
    return itemCount >= amount
end

function BridgeAdapters.esx.getItemData(source, itemName, meta)
    local player = BridgeAdapters.esx.getPlayer(source)
    if not player or not player.getInventoryItem then
        return nil
    end

    return player.getInventoryItem(itemName)
end

function BridgeAdapters.esx.getItemCount(source, itemName, meta)
    local data = BridgeAdapters.esx.getItemData(source, itemName, meta)
    if not data then
        return 0
    end

    return data.count or data.amount or 0
end

function BridgeAdapters.esx.addItem(source, itemName, amount, meta)
    local player = BridgeAdapters.esx.getPlayer(source)
    if not player or not player.addInventoryItem then
        return false
    end

    amount = amount or 1
    if player.canCarryItem and not player.canCarryItem(itemName, amount) then
        return false
    end

    player.addInventoryItem(itemName, amount, meta)
    return true
end

function BridgeAdapters.esx.removeItem(source, itemName, amount, meta)
    local player = BridgeAdapters.esx.getPlayer(source)
    if not player or not player.removeInventoryItem then
        return false
    end

    amount = amount or 1
    local count = BridgeAdapters.esx.getItemCount(source, itemName, meta)
    if count < amount then
        return false
    end

    player.removeInventoryItem(itemName, amount)
    return true
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
