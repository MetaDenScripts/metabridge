MetaBridgeClient = MetaBridgeClient or {}

local function getResourceExport(resourceName, methodName)
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
