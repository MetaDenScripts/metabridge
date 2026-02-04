MetaBridgeClient = MetaBridgeClient or {}

local function getResourceExport(resourceName, methodName)
    if BridgeShared and BridgeShared.isStarted and not BridgeShared.isStarted(resourceName) then
        return nil
    end

    if not exports or not exports[resourceName] then
        return nil
    end

    local resource = exports[resourceName]
    local fn = resource[methodName]
    if type(fn) ~= 'function' then
        return nil
    end

    return function(...)
        return fn(resource, ...)
    end
end

function MetaBridgeClient.getFramework()
    if BridgeShared and BridgeShared.detectFramework then
        return BridgeShared.detectFramework()
    end

    return nil
end

function MetaBridgeClient.isReady()
    return MetaBridgeClient.getFramework() ~= nil
end

function MetaBridgeClient.setFuel(vehicle, fuel)
    if BridgeConfig and BridgeConfig.fuel and BridgeConfig.fuel.set then
        return BridgeConfig.fuel.set(vehicle, fuel)
    end

    local setFuel = getResourceExport('LegacyFuel', 'SetFuel')
        or getResourceExport('ps-fuel', 'SetFuel')
        or getResourceExport('cdn-fuel', 'SetFuel')

    if setFuel then
        return setFuel(vehicle, fuel)
    end

    if vehicle and DoesEntityExist(vehicle) then
        SetVehicleFuelLevel(vehicle, fuel)
        return true
    end

    return false
end

function MetaBridgeClient.giveVehicleKeys(plate)
    if BridgeConfig and BridgeConfig.keysClient and BridgeConfig.keysClient.give then
        return BridgeConfig.keysClient.give(plate)
    end

    TriggerServerEvent('MetaBridge:giveVehicleKeys', plate)
    return true
end

local function toModelHash(model)
    if type(model) == 'number' then
        return model
    end

    return GetHashKey(model)
end

local function requestModel(model, timeoutMs)
    local modelHash = toModelHash(model)
    if not IsModelInCdimage(modelHash) then
        return false
    end

    RequestModel(modelHash)

    local timeout = timeoutMs or 10000
    local startTime = GetGameTimer()
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() - startTime > timeout then
            return false
        end

        Wait(0)
    end

    return true
end

local function setModelAsNoLongerNeeded(model)
    local modelHash = toModelHash(model)
    if not IsModelInCdimage(modelHash) then
        return false
    end

    SetModelAsNoLongerNeeded(modelHash)
    return true
end

function MetaBridgeClient.spawnPed(model, coords, heading, networked)
    if not requestModel(model) then
        return nil
    end

    local modelHash = toModelHash(model)
    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z, heading or 0.0, networked == true, false)
    setModelAsNoLongerNeeded(modelHash)
    return ped
end

function MetaBridgeClient.spawnVehicle(model, coords, heading, networked)
    if not requestModel(model) then
        return nil
    end

    local modelHash = toModelHash(model)
    local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading or 0.0, networked == true, false)
    setModelAsNoLongerNeeded(modelHash)
    return vehicle
end

function MetaBridgeClient.setEntityAsNoLongerNeeded(entity)
    if not entity or entity == 0 then
        return false
    end

    SetEntityAsNoLongerNeeded(entity)
    return true
end

function MetaBridgeClient.getItemLabel(itemName)
    if exports and exports.ox_inventory and exports.ox_inventory.Items then
        local oxItem = exports.ox_inventory:Items(itemName)
        if oxItem and oxItem.label then
            return oxItem.label
        end
    end

    return itemName
end

function MetaBridgeClient.getItemImage(itemName)
    if BridgeConfig and BridgeConfig.inventory and BridgeConfig.inventory.getItemImage then
        return BridgeConfig.inventory.getItemImage(itemName)
    end

    if exports and exports.ox_inventory then
        return string.format("nui://%s/web/images/%s.png", 'ox_inventory', itemName)
    end

    return nil
end

local function normalizeNotifyPayload(data)
    if type(data) == 'string' then
        return { description = data, type = 'inform' }
    end

    if type(data) == 'table' then
        if data.message and not data.description then
            data.description = data.message
        end
        return data
    end

    return { description = tostring(data), type = 'inform' }
end

function MetaBridgeClient.notify(data)
    if BridgeConfig and BridgeConfig.notify and BridgeConfig.notify.client then
        return BridgeConfig.notify.client(data)
    end

    local payload = normalizeNotifyPayload(data)

    if lib and lib.notify then
        lib.notify(payload)
        return true
    end

    local message = payload.description or payload.message or payload.text or ''
    local notifyType = payload.type or 'primary'
    local length = payload.duration or payload.length or 5000

    if type(QBCore) == 'table' and QBCore.Functions and QBCore.Functions.Notify then
        QBCore.Functions.Notify(message, notifyType, length)
        return true
    end

    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(message)
        return true
    end

    if TriggerEvent then
        TriggerEvent('QBCore:Notify', message, notifyType, length)
        return true
    end

    return false
end

function MetaBridgeClient.addTargetModel(models, options)
    if BridgeConfig and BridgeConfig.target and BridgeConfig.target.addModel then
        return BridgeConfig.target.addModel(models, options)
    end

    if exports and exports.ox_target and exports.ox_target.addModel then
        exports.ox_target:addModel(models, options)
        return true
    end

    if exports and exports.qtarget and exports.qtarget.AddTargetModel then
        exports.qtarget:AddTargetModel(models, { options = options, distance = 5.0 })
        return true
    end

    if exports and exports['qb-target'] and exports['qb-target'].AddTargetModel then
        exports['qb-target']:AddTargetModel(models, { options = options, distance = 5.0 })
        return true
    end

    return false
end
