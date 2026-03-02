BridgeAdapters = BridgeAdapters or {}

BridgeAdapters.standalone = {
    name = 'standalone'
}

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
    return BridgeShared.setFuel(vehicle, fuel)
end

function BridgeAdapters.standalone.giveVehicleKeys(source, plate)
    return BridgeShared.giveVehicleKeys(source, plate)
end

function BridgeAdapters.standalone.createOwnedVehicle(request)
    return nil
end

function BridgeAdapters.standalone.getOwnedVehicle(lookup)
    return nil
end

function BridgeAdapters.standalone.spawnOwnedVehicle(request)
    return nil
end
