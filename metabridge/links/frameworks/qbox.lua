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

local cachedJobDefinitions = nil

local function loadJobDefinitions()
    if cachedJobDefinitions ~= nil then
        return cachedJobDefinitions or nil
    end

    local fileContents = LoadResourceFile('qbx_core', 'shared/jobs.lua')
    if type(fileContents) ~= 'string' or fileContents == '' then
        cachedJobDefinitions = false
        return nil
    end

    local chunk, loadError = load(fileContents, '@qbx_core/shared/jobs.lua', 't', {})
    if not chunk then
        BridgeShared.debug('adapter.qbox', 'Failed to parse shared/jobs.lua', { error = tostring(loadError) })
        cachedJobDefinitions = false
        return nil
    end

    local success, jobs = pcall(chunk)
    if not success or type(jobs) ~= 'table' then
        BridgeShared.debug('adapter.qbox', 'Failed to evaluate shared/jobs.lua', {
            success = success,
            resultType = type(jobs)
        })
        cachedJobDefinitions = false
        return nil
    end

    cachedJobDefinitions = jobs
    return jobs
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

function BridgeAdapters.qbox.getJobDefinitions()
    return loadJobDefinitions()
end

function BridgeAdapters.qbox.getGang(source)
    local player = BridgeAdapters.qbox.getPlayer(source)
    local gang = BridgeShared.resolveGangData(player)
    if gang ~= nil then
        return gang
    end

    local playerData = BridgeAdapters.qbox.getPlayerData(source)
    return BridgeShared.resolveGangData(playerData)
end

function BridgeAdapters.qbox.getMetadata(source, key)
    local playerData = BridgeAdapters.qbox.getPlayerData(source)
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

function BridgeAdapters.qbox.getMoney(source, moneyType)
    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    local getMoney = getExportFunction('GetMoney')
    if getMoney then
        local amount = getMoney(source, moneyType)
        if amount ~= false then
            return amount
        end
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    if player and player.PlayerData and player.PlayerData.money then
        return player.PlayerData.money[moneyType]
    end

    local playerData = BridgeAdapters.qbox.getPlayerData(source)
    if not playerData or not playerData.money then
        return nil
    end

    return playerData.money[moneyType]
end

function BridgeAdapters.qbox.setPlayerMetadata(source, key, value)
    local setMetadata = getExportFunction('SetMetadata')
    if setMetadata then
        setMetadata(source, key, value)
        return true
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    if not player or not player.Functions or not player.Functions.SetMetaData then
        return false
    end

    player.Functions.SetMetaData(key, value)
    return true
end

function BridgeAdapters.qbox.addMoney(source, moneyType, amount, reason)
    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    amount = tonumber(amount) or 0
    if amount < 0 then
        return false
    end

    local addMoney = getExportFunction('AddMoney')
    if addMoney then
        local success = addMoney(source, moneyType, amount, reason)
        if success == true then
            return true
        end
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    if not player or not player.Functions or not player.Functions.AddMoney then
        return false
    end

    return player.Functions.AddMoney(moneyType, amount, reason) == true
end

function BridgeAdapters.qbox.removeMoney(source, moneyType, amount, reason)
    moneyType = moneyType or 'cash'
    if moneyType == 'money' then
        moneyType = 'cash'
    end

    amount = tonumber(amount) or 0
    if amount < 0 then
        return false
    end

    local currentMoney = tonumber(BridgeAdapters.qbox.getMoney(source, moneyType)) or 0
    if currentMoney < amount then
        return false
    end

    local removeMoney = getExportFunction('RemoveMoney')
    if removeMoney then
        local success = removeMoney(source, moneyType, amount, reason)
        if success == true then
            return true
        end
    end

    local player = BridgeAdapters.qbox.getPlayer(source)
    if not player or not player.Functions or not player.Functions.RemoveMoney then
        return false
    end

    return player.Functions.RemoveMoney(moneyType, amount, reason) == true
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

    local model  = request.model
    local coords = request.coords
    if type(model) ~= 'string' or model == '' or type(coords) ~= 'table' then
        return nil
    end

    local heading   = tonumber(request.heading) or tonumber(coords.w) or 0.0
    local props     = request.props
    local modelHash = joaat(model)

    -- qbx.spawnVehicle is a script-local inside qbx_core and is NOT accessible
    -- from other resources. Use the cross-resource export instead.
    local vehicleType
    local ok, vehData = pcall(function()
        return exports.qbx_core:GetVehiclesByHash(modelHash)
    end)
    if ok and type(vehData) == 'table' and type(vehData.type) == 'string' then
        vehicleType = vehData.type
    else
        -- Fallback: spawn a temp vehicle off-map to read its type then discard it.
        local tempVeh = CreateVehicle(modelHash, 0, 0, -200, 0, true, true)
        local deadline = GetGameTimer() + 3000
        while not DoesEntityExist(tempVeh) and GetGameTimer() < deadline do Wait(0) end
        if DoesEntityExist(tempVeh) then
            vehicleType = GetVehicleType(tempVeh)
            DeleteEntity(tempVeh)
        end
    end

    if not vehicleType then
        BridgeShared.debug('adapter.qbox', 'spawnOwnedVehicle: could not determine vehicleType', { model = model })
        return nil
    end

    -- Spawn at the stored prop Z; the ground surface is at this level.
    local spawnZ = (tonumber(coords.z) or 0.0)

    local veh, netId
    for attempt = 1, 3 do
        veh = CreateVehicleServerSetter(modelHash, vehicleType, coords.x, coords.y, spawnZ, heading)

        local deadline = GetGameTimer() + 5000
        while not DoesEntityExist(veh) and GetGameTimer() < deadline do Wait(0) end

        if not DoesEntityExist(veh) then
            BridgeShared.debug('adapter.qbox', 'spawnOwnedVehicle: entity missing after spawn', { attempt = attempt })
            veh = nil
        else
            -- Wait for the game to assign an initial plate.
            deadline = GetGameTimer() + 3000
            while GetVehicleNumberPlateText(veh) == '' and GetGameTimer() < deadline do Wait(0) end

            netId = NetworkGetNetworkIdFromEntity(veh)

            -- Apply props (including the correct plate) via the owning client.
            if props and type(props) == 'table' and props.plate then
                local owner = NetworkGetEntityOwner(veh)
                if owner and owner >= 0 then
                    TriggerClientEvent('qbx_core:client:setVehicleProperties', owner, netId, props)

                    -- Wait up to 2 s for the plate to be confirmed server-side.
                    local expected = props.plate:match('^%s*(.-)%s*$')
                    local plateOk  = false
                    deadline = GetGameTimer() + 2000
                    while GetGameTimer() < deadline do
                        Wait(100)
                        local current = GetVehicleNumberPlateText(veh):match('^%s*(.-)%s*$')
                        if current == expected then
                            plateOk = true
                            break
                        end
                    end

                    if not plateOk then
                        BridgeShared.debug('adapter.qbox', 'spawnOwnedVehicle: plate mismatch, retrying', { attempt = attempt })
                        DeleteEntity(veh)
                        veh = nil
                    end
                end
            end
        end

        if veh and DoesEntityExist(veh) then
            break
        end
    end

    if not veh or not DoesEntityExist(veh) then
        BridgeShared.debug('adapter.qbox', 'spawnOwnedVehicle: failed after 3 attempts', { model = model })
        return nil
    end

    -- Prevent the server culling a vehicle with no nearby players.
    SetEntityOrphanMode(veh, 2)
    pcall(function() exports.qbx_core:EnablePersistence(veh) end)

    return {
        netId  = netId,
        entity = veh,
        plate  = request.plate or (props and props.plate),
    }
end
