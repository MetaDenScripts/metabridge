BridgeAdapters = BridgeAdapters or {}

BridgeAdapters.ox = {
    name = 'ox'
}

local Ox = nil

local function getOx()
    if Ox then
        return Ox
    end

    if BridgeShared and BridgeShared.isStarted and not BridgeShared.isStarted('ox_core') then
        return nil
    end

    local ok, lib = pcall(function()
        return require '@ox_core/lib/init.lua'
    end)

    if ok then
        Ox = lib
    end

    return Ox
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

function BridgeAdapters.ox.getPlayer(source)
    local ox = getOx()
    if ox and ox.GetPlayer then
        return ox.GetPlayer(source)
    end

    if exports and exports.ox_core and exports.ox_core.GetPlayer then
        return exports.ox_core:GetPlayer(source)
    end

    return nil
end

function BridgeAdapters.ox.getPlayerData(source)
    local player = BridgeAdapters.ox.getPlayer(source)
    if not player then
        return nil
    end

    if player.get then
        return player.get()
    end

    return player
end

function BridgeAdapters.ox.getIdentifier(source)
    local player = BridgeAdapters.ox.getPlayer(source)
    if not player then
        return nil
    end

    return player.charId or player.charid or player.identifier or player.id
end

function BridgeAdapters.ox.getJob(source)
    local player = BridgeAdapters.ox.getPlayer(source)
    return player and player.job or nil
end

function BridgeAdapters.ox.getMoney(source, moneyType)
    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    local player = BridgeAdapters.ox.getPlayer(source)
    if player and player.getMoney then
        return player.getMoney(moneyType)
    end

    return nil
end

function BridgeAdapters.ox.addMoney(source, moneyType, amount, reason)
    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    local player = BridgeAdapters.ox.getPlayer(source)
    if player and player.addMoney then
        player.addMoney(moneyType, tonumber(amount) or 0, reason)
        return true
    end

    return false
end

function BridgeAdapters.ox.removeMoney(source, moneyType, amount, reason)
    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    local player = BridgeAdapters.ox.getPlayer(source)
    if not player or not player.removeMoney then
        return false
    end

    local currentMoney = BridgeAdapters.ox.getMoney(source, moneyType) or 0
    if currentMoney < (tonumber(amount) or 0) then
        return false
    end

    player.removeMoney(moneyType, tonumber(amount) or 0, reason)
    return true
end

function BridgeAdapters.ox.hasItem(source, itemName, amount)
    amount = amount or 1

    if BridgeShared and BridgeShared.isStarted and BridgeShared.isStarted('ox_inventory') then
        local count = callExport('ox_inventory', 'GetItemCount', source, itemName)
        if type(count) == 'number' then
            return count >= amount
        end
    end

    return false
end

function BridgeAdapters.ox.getItemData(source, itemName, meta)
    if BridgeShared and BridgeShared.isStarted and BridgeShared.isStarted('ox_inventory') then
        return callExport('ox_inventory', 'GetItem', source, itemName, meta) or {}
    end

    return nil
end

function BridgeAdapters.ox.getItemCount(source, itemName, meta)
    if BridgeShared and BridgeShared.isStarted and BridgeShared.isStarted('ox_inventory') then
        local count = callExport('ox_inventory', 'GetItemCount', source, itemName)
        if type(count) == 'number' then
            return count
        end
    end

    return 0
end

function BridgeAdapters.ox.addItem(source, itemName, amount, meta)
    if BridgeShared and BridgeShared.isStarted and BridgeShared.isStarted('ox_inventory') then
        local success = callExport('ox_inventory', 'AddItem', source, itemName, amount or 1, meta)
        if type(success) == 'boolean' then
            return success
        end
    end

    return false
end

function BridgeAdapters.ox.removeItem(source, itemName, amount, meta)
    if BridgeShared and BridgeShared.isStarted and BridgeShared.isStarted('ox_inventory') then
        local success = callExport('ox_inventory', 'RemoveItem', source, itemName, amount or 1, meta)
        if type(success) == 'boolean' then
            return success
        end
    end

    return false
end

function BridgeAdapters.ox.setFuel(vehicle, fuel)
    return BridgeShared.setFuel(vehicle, fuel)
end

function BridgeAdapters.ox.giveVehicleKeys(source, plate)
    return BridgeShared.giveVehicleKeys(source, plate)
end
