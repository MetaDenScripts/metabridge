BridgeAdapters = BridgeAdapters or {}

BridgeAdapters.esx = {
    name = 'esx'
}

local ESX = nil
local cachedJobDefinitions = nil

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

function BridgeAdapters.esx.getJobDefinitions()
    if cachedJobDefinitions ~= nil then
        return cachedJobDefinitions or nil
    end

    if type(MySQL) ~= 'table' or type(MySQL.query) ~= 'table' or type(MySQL.query.await) ~= 'function' then
        cachedJobDefinitions = false
        return nil
    end

    local jobs = MySQL.query.await('SELECT name, label FROM jobs', {}) or {}
    local grades = MySQL.query.await('SELECT job_name, grade, label FROM job_grades ORDER BY job_name, grade', {}) or {}
    local mapped = {}

    for _, job in ipairs(jobs) do
        if type(job.name) == 'string' and job.name ~= '' then
            mapped[job.name] = {
                label = job.label or job.name,
                grades = {}
            }
        end
    end

    for _, grade in ipairs(grades) do
        local jobName = grade.job_name
        if type(jobName) == 'string' and jobName ~= '' then
            mapped[jobName] = mapped[jobName] or {
                label = jobName,
                grades = {}
            }

            local numericLevel = tonumber(grade.grade)
            if numericLevel ~= nil then
                mapped[jobName].grades[#mapped[jobName].grades + 1] = {
                    level = numericLevel,
                    name = grade.label,
                    isBoss = false,
                }
            end
        end
    end

    cachedJobDefinitions = mapped
    return mapped
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

function BridgeAdapters.esx.addMoney(source, moneyType, amount, reason)
    local player = BridgeAdapters.esx.getPlayer(source)
    if not player then
        return false
    end

    amount = tonumber(amount) or 0
    moneyType = moneyType or 'money'
    if moneyType == 'cash' then
        moneyType = 'money'
    end

    if moneyType ~= 'money' and player.addAccountMoney then
        player.addAccountMoney(moneyType, amount, reason)
        return true
    end

    if player.addMoney then
        player.addMoney(amount, reason)
        return true
    end

    return false
end

function BridgeAdapters.esx.removeMoney(source, moneyType, amount, reason)
    local player = BridgeAdapters.esx.getPlayer(source)
    if not player then
        return false
    end

    amount = tonumber(amount) or 0
    moneyType = moneyType or 'money'
    if moneyType == 'cash' then
        moneyType = 'money'
    end

    if moneyType ~= 'money' and player.removeAccountMoney then
        local account = player.getAccount and player.getAccount(moneyType) or nil
        local currentMoney = account and tonumber(account.money) or 0
        if currentMoney < amount then
            return false
        end

        player.removeAccountMoney(moneyType, amount, reason)
        return true
    end

    local currentMoney = player.getMoney and tonumber(player.getMoney()) or 0
    if currentMoney < amount or not player.removeMoney then
        return false
    end

    player.removeMoney(amount, reason)
    return true
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
    return BridgeShared.setFuel(vehicle, fuel)
end

function BridgeAdapters.esx.giveVehicleKeys(source, plate)
    return BridgeShared.giveVehicleKeys(source, plate, {
        { resource = 'esx_vehiclelock', methods = { 'givePlayerKeys', 'GiveKeys' }, successOnStarted = true }
    })
end

function BridgeAdapters.esx.createOwnedVehicle(request)
    if type(request) ~= 'table' then
        return nil
    end

    local ownerIdentifier = request.ownerIdentifier
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
        'INSERT INTO owned_vehicles (`owner`, `plate`, `vehicle`, `type`, `stored`) VALUES (?, ?, ?, ?, ?)',
        {
            ownerIdentifier,
            props.plate,
            json.encode(props),
            request.vehicleType or 'car',
            1,
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

function BridgeAdapters.esx.getOwnedVehicle(lookup)
    if type(lookup) ~= 'table' then
        return nil
    end

    local record = nil
    if lookup.id then
        record = MySQL.single.await('SELECT id, owner, plate, vehicle FROM owned_vehicles WHERE id = ? LIMIT 1',
            { lookup.id })
    elseif lookup.plate then
        record = MySQL.single.await('SELECT id, owner, plate, vehicle FROM owned_vehicles WHERE plate = ? LIMIT 1',
            { lookup.plate })
    end

    if not record then
        return nil
    end

    local props = decodeJsonTable(record.vehicle)
    return {
        id = record.id,
        model = props and props.model,
        plate = record.plate,
        props = props,
        ownerIdentifier = record.owner,
    }
end

function BridgeAdapters.esx.spawnOwnedVehicle(request)
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
