BridgeAdapters = BridgeAdapters or {}

BridgeAdapters.qbox = {
    name = 'qbox'
}

local function getExportFunction(method)
    if not exports or not exports['qbx_core'] then
        return nil
    end

    local resource = exports['qbx_core']
    local fn = resource[method]
    if type(fn) ~= 'function' then
        return nil
    end

    return function(...)
        return fn(resource, ...)
    end
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

function BridgeAdapters.qbox.getPlayer(source)
    local getPlayer = getExportFunction('GetPlayer')
    if not getPlayer then
        return nil
    end

    return getPlayer(source)
end

function BridgeAdapters.qbox.getPlayerData(source)
    local getPlayerData = getExportFunction('GetPlayerData')
    if getPlayerData then
        return getPlayerData(source)
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    return player and player.PlayerData or nil
end

function BridgeAdapters.qbox.getIdentifier(source)
    local playerData = BridgeAdapters.qbox.getPlayerData(source)
    if playerData and playerData.citizenid then
        return playerData.citizenid
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    return player and player.citizenid or nil
end

function BridgeAdapters.qbox.getJob(source)
    local playerData = BridgeAdapters.qbox.getPlayerData(source)
    if playerData and playerData.job then
        return playerData.job
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    return player and player.job or nil
end

function BridgeAdapters.qbox.getMoney(source, moneyType)
    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    local getMoney = getExportFunction('GetMoney')
    if getMoney then
        return getMoney(source, moneyType)
    end

    local playerData = BridgeAdapters.qbox.getPlayerData(source)
    if not playerData or not playerData.money then
        return nil
    end

    return playerData.money[moneyType]
end

function BridgeAdapters.qbox.hasItem(source, itemName, amount)
    local hasItem = getExportFunction('HasItem')
    if hasItem then
        return hasItem(source, itemName, amount or 1)
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    if not player or not player.Functions or not player.Functions.GetItemByName then
        return false
    end

    local item = player.Functions.GetItemByName(itemName)
    if not item then
        return false
    end

    amount = amount or 1
    return item.amount >= amount
end

function BridgeAdapters.qbox.getItemData(source, itemName, meta)
    local getItem = getExportFunction('GetItemByName')
    if getItem then
        return getItem(source, itemName)
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    if not player or not player.Functions or not player.Functions.GetItemByName then
        return nil
    end

    return player.Functions.GetItemByName(itemName)
end

function BridgeAdapters.qbox.getItemCount(source, itemName, meta)
    local data = BridgeAdapters.qbox.getItemData(source, itemName, meta)
    if not data then
        return 0
    end

    return data.amount or data.count or 0
end

function BridgeAdapters.qbox.addItem(source, itemName, amount, meta)
    local addItem = getExportFunction('AddItem')
    if addItem then
        return addItem(source, itemName, amount or 1, false, meta) == true
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    if not player or not player.Functions or not player.Functions.AddItem then
        return false
    end

    return player.Functions.AddItem(itemName, amount or 1, false, meta) == true
end

function BridgeAdapters.qbox.removeItem(source, itemName, amount, meta)
    local removeItem = getExportFunction('RemoveItem')
    if removeItem then
        return removeItem(source, itemName, amount or 1, false, meta) == true
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    if not player or not player.Functions or not player.Functions.RemoveItem then
        return false
    end

    return player.Functions.RemoveItem(itemName, amount or 1, false, meta) == true
end

function BridgeAdapters.qbox.setFuel(vehicle, fuel)
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

function BridgeAdapters.qbox.giveVehicleKeys(source, plate)
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
