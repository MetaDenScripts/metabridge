BridgeAdapters = BridgeAdapters or {}

BridgeAdapters.qbox = {
    name = 'qbox'
}

local function getExportFunction(method)
    if not BridgeShared or not BridgeShared.getExportFunction then
        return nil
    end
    return BridgeShared.getExportFunction('qbx_core', method, false)
end

function BridgeAdapters.qbox.getPlayer(source)
    local getPlayer = getExportFunction('GetPlayer')
    if not getPlayer then
        BridgeShared.debug('adapter.qbox', 'GetPlayer export not found')
        return nil
    end

    local playerSource = tonumber(source) or source
    local player = getPlayer(playerSource)
    BridgeShared.debug('adapter.qbox', 'Fetched player', {
        source = playerSource,
        hasPlayer = player ~= nil,
        playerType = type(player)
    })
    return player
end

local function extractPlayerData(player)
    if not player then
        return nil
    end

    if type(player) == 'table' then
        return player.PlayerData or player.playerData or player
    end

    return nil
end

function BridgeAdapters.qbox.getPlayerData(source)
    local player = BridgeAdapters.qbox.getPlayer(source)
    return extractPlayerData(player)
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
    local player = BridgeAdapters.qbox.getPlayer(source)
    local job = BridgeShared.resolveJobData(player)
    if job ~= nil then
        BridgeShared.debug('adapter.qbox', 'Resolved job from player payload', {
            source = source,
            jobType = type(job)
        })
        return job
    end

    local playerData = BridgeAdapters.qbox.getPlayerData(source)
    job = BridgeShared.resolveJobData(playerData)

    BridgeShared.debug('adapter.qbox', 'Job resolution result', {
        source = source,
        hasPlayer = player ~= nil,
        hasPlayerData = playerData ~= nil,
        hasJob = job ~= nil
    })

    return job
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
    return BridgeShared.setFuel(vehicle, fuel)
end

function BridgeAdapters.qbox.giveVehicleKeys(source, plate)
    return BridgeShared.giveVehicleKeys(source, plate)
end

function BridgeAdapters.qbox.createOwnedVehicle(request)
    if type(request) ~= 'table' then
        return nil
    end

    if not exports or not exports.qbx_vehicles then
        return nil
    end

    local ownerIdentifier = request.ownerIdentifier or request.citizenid
    if type(ownerIdentifier) ~= 'string' or ownerIdentifier == '' then
        return nil
    end

    local model = request.model
    if type(model) ~= 'string' or model == '' then
        return nil
    end

    local createRequest = {
        model = model,
        citizenid = ownerIdentifier,
        garage = request.garage,
        props = request.props
    }

    local vehicleId = exports.qbx_vehicles:CreatePlayerVehicle(createRequest)
    if not vehicleId then
        return nil
    end

    local ownedVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    if not ownedVehicle then
        return {
            id = vehicleId,
            model = model,
            ownerIdentifier = ownerIdentifier,
        }
    end

    return {
        id = vehicleId,
        plate = ownedVehicle.plate or (ownedVehicle.props and ownedVehicle.props.plate),
        model = ownedVehicle.modelName or ownedVehicle.vehicle or model,
        props = ownedVehicle.props,
        ownerIdentifier = ownedVehicle.citizenid or ownerIdentifier,
    }
end

function BridgeAdapters.qbox.getOwnedVehicle(lookup)
    if type(lookup) ~= 'table' or not exports or not exports.qbx_vehicles then
        return nil
    end

    local vehicleId = lookup.id or lookup.vehicleId
    if vehicleId == nil then
        return nil
    end

    local ownedVehicle = exports.qbx_vehicles:GetPlayerVehicle(vehicleId)
    if not ownedVehicle then
        return nil
    end

    return {
        id = ownedVehicle.id or vehicleId,
        plate = ownedVehicle.plate or (ownedVehicle.props and ownedVehicle.props.plate),
        model = ownedVehicle.modelName or ownedVehicle.vehicle,
        props = ownedVehicle.props,
        ownerIdentifier = ownedVehicle.citizenid,
    }
end

function BridgeAdapters.qbox.spawnOwnedVehicle(request)
    if type(request) ~= 'table' then
        return nil
    end

    if type(qbx) ~= 'table' or type(qbx.spawnVehicle) ~= 'function' then
        return nil
    end

    local model = request.model
    local coords = request.coords
    if type(coords) ~= 'table' then
        return nil
    end

    local heading = tonumber(request.heading) or tonumber(coords.w) or 0.0

    local netId, vehicle = qbx.spawnVehicle({
        model = model,
        spawnSource = vector4(coords.x, coords.y, coords.z, heading),
        props = request.props,
        warp = request.warp
    })

    if not vehicle then
        return nil
    end

    return {
        netId = netId,
        entity = vehicle,
        plate = request.plate or (request.props and request.props.plate),
    }
end
