BridgeAdapters = BridgeAdapters or {}

BridgeAdapters.qbcore = {
    name = 'qbcore'
}

local QBCore = nil

local function getCore()
    if not QBCore then
        QBCore = exports['qb-core']:GetCoreObject()
    end

    return QBCore
end

local cachedJobDefinitions = nil

local function loadJobDefinitions()
    if cachedJobDefinitions ~= nil then
        return cachedJobDefinitions or nil
    end

    local fileContents = LoadResourceFile('qb-core', 'shared/jobs.lua')
    if type(fileContents) ~= 'string' or fileContents == '' then
        cachedJobDefinitions = false
        return nil
    end

    local chunk, loadError = load(fileContents, '@qb-core/shared/jobs.lua', 't', {})
    if not chunk then
        BridgeShared.debug('adapter.qbcore', 'Failed to parse shared/jobs.lua', { error = tostring(loadError) })
        cachedJobDefinitions = false
        return nil
    end

    local success, jobs = pcall(chunk)
    if not success or type(jobs) ~= 'table' then
        BridgeShared.debug('adapter.qbcore', 'Failed to evaluate shared/jobs.lua', {
            success = success,
            resultType = type(jobs)
        })
        cachedJobDefinitions = false
        return nil
    end

    cachedJobDefinitions = jobs
    return jobs
end

local function generatePlate()
    if lib and lib.string and lib.string.random then
        return lib.string.random('........'):upper()
    end

    return ('MB%s'):format(math.random(100000, 999999))
end

local function decodeJsonTable(value)
    if type(value) == 'table' then
        return value
    end

    if type(value) ~= 'string' or value == '' then
        return nil
    end

    local ok, decoded = pcall(json.decode, value)
    if not ok or type(decoded) ~= 'table' then
        return nil
    end

    return decoded
end

function BridgeAdapters.qbcore.getPlayer(source)
    local core = getCore()
    if not core or not core.Functions then
        BridgeShared.debug('adapter.qbcore', 'Core unavailable for GetPlayer')
        return nil
    end

    local playerSource = tonumber(source) or source
    local player = core.Functions.GetPlayer(playerSource)
    BridgeShared.debug('adapter.qbcore', 'Fetched player', {
        source = playerSource,
        hasPlayer = player ~= nil,
        playerType = type(player)
    })
    return player
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
    local player = BridgeAdapters.qbcore.getPlayer(source)
    local job = BridgeShared.resolveJobData(player)
    if job ~= nil then
        return job
    end

    local playerData = BridgeAdapters.qbcore.getPlayerData(source)
    job = BridgeShared.resolveJobData(playerData)

    BridgeShared.debug('adapter.qbcore', 'Job resolution result', {
        source = source,
        hasPlayer = player ~= nil,
        hasPlayerData = playerData ~= nil,
        hasJob = job ~= nil
    })

    return job
end

function BridgeAdapters.qbcore.getJobDefinitions()
    return loadJobDefinitions()
end

function BridgeAdapters.qbcore.getGang(source)
    local player = BridgeAdapters.qbcore.getPlayer(source)
    local gang = BridgeShared.resolveGangData(player)
    if gang ~= nil then
        return gang
    end

    local playerData = BridgeAdapters.qbcore.getPlayerData(source)
    return BridgeShared.resolveGangData(playerData)
end

function BridgeAdapters.qbcore.getMetadata(source, key)
    local playerData = BridgeAdapters.qbcore.getPlayerData(source)
    local metadata = type(playerData) == 'table' and playerData.metadata or nil
    if type(metadata) ~= 'table' then
        return nil
    end

    if type(key) ~= 'string' or key == '' then
        return metadata
    end

    local current = metadata
    for segment in key:gmatch('[^%.]+') do
        if type(current) ~= 'table' then
            return nil
        end

        current = current[segment]
    end

    return current
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

function BridgeAdapters.qbcore.setPlayerMetadata(source, key, value)
    local player = BridgeAdapters.qbcore.getPlayer(source)
    if not player or not player.Functions or not player.Functions.SetMetaData then
        return false
    end

    player.Functions.SetMetaData(key, value)
    return true
end

function BridgeAdapters.qbcore.addMoney(source, moneyType, amount, reason)
    local player = BridgeAdapters.qbcore.getPlayer(source)
    if not player or not player.Functions or not player.Functions.AddMoney then
        return false
    end

    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    return player.Functions.AddMoney(moneyType, tonumber(amount) or 0, reason) == true
end

function BridgeAdapters.qbcore.removeMoney(source, moneyType, amount, reason)
    local player = BridgeAdapters.qbcore.getPlayer(source)
    if not player or not player.Functions or not player.Functions.RemoveMoney then
        return false
    end

    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    return player.Functions.RemoveMoney(moneyType, tonumber(amount) or 0, reason) == true
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
    return BridgeShared.setFuel(vehicle, fuel)
end

function BridgeAdapters.qbcore.giveVehicleKeys(source, plate)
    return BridgeShared.giveVehicleKeys(source, plate)
end

function BridgeAdapters.qbcore.createOwnedVehicle(request)
    if type(request) ~= 'table' then
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

    local props = type(request.props) == 'table' and request.props or {}
    if not props.plate then
        props.plate = generatePlate()
    end
    props.model = props.model or joaat(model)

    local vehicleId = MySQL.insert.await(
        'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state, garage) VALUES ((SELECT license FROM players WHERE citizenid = ? LIMIT 1), ?, ?, ?, ?, ?, ?, ?)',
        {
            ownerIdentifier,
            ownerIdentifier,
            model,
            props.model,
            json.encode(props),
            props.plate,
            request.garage and 1 or 0,
            request.garage
        }
    )

    if not vehicleId then
        return nil
    end

    return {
        id = vehicleId,
        model = model,
        plate = props.plate,
        props = props,
        ownerIdentifier = ownerIdentifier,
    }
end

function BridgeAdapters.qbcore.getOwnedVehicle(lookup)
    if type(lookup) ~= 'table' then
        return nil
    end

    local record = nil
    if lookup.id then
        record = MySQL.single.await('SELECT id, citizenid, vehicle, mods, plate FROM player_vehicles WHERE id = ? LIMIT 1',
            { lookup.id })
    elseif lookup.plate then
        record = MySQL.single.await(
            'SELECT id, citizenid, vehicle, mods, plate FROM player_vehicles WHERE plate = ? LIMIT 1',
            { lookup.plate })
    end

    if not record then
        return nil
    end

    return {
        id = record.id,
        model = record.vehicle,
        plate = record.plate,
        props = decodeJsonTable(record.mods),
        ownerIdentifier = record.citizenid,
    }
end

function BridgeAdapters.qbcore.spawnOwnedVehicle(request)
    if type(request) ~= 'table' then
        return nil
    end

    local coords = request.coords
    local model = request.model
    if type(coords) ~= 'table' or not model then
        return nil
    end

    if type(CreateVehicleServerSetter) ~= 'function' then
        return nil
    end

    local modelHash = type(model) == 'number' and model or joaat(model)
    local heading = tonumber(request.heading) or tonumber(coords.w) or 0.0
    local veh = CreateVehicleServerSetter(modelHash, 'automobile', coords.x, coords.y, coords.z, heading)
    if not veh or veh == 0 then
        return nil
    end

    local plate = request.plate or (request.props and request.props.plate)
    if plate then
        SetVehicleNumberPlateText(veh, plate)
    end

    return {
        entity = veh,
        netId = NetworkGetNetworkIdFromEntity(veh),
        plate = plate,
    }
end
