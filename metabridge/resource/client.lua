MetaBridgeClient = MetaBridgeClient or {}

local QBCore = QBCore
local callbackRequestId = 0
local pendingCallbacks = {}
local playerLoadedHandlers = {}
local hasEmittedPlayerLoaded = false

local function getQBCore()
    if QBCore then
        return QBCore
    end

    if exports and exports['qb-core'] and exports['qb-core'].GetCoreObject then
        local ok, core = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if ok and core then
            QBCore = core
            return QBCore
        end
    end

    return nil
end

local function getResourceExport(resourceName, methodName)
    if not BridgeShared or not BridgeShared.getExportFunction then
        return nil
    end

    return BridgeShared.getExportFunction(resourceName, methodName, true)
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

local function resolveJobData(data)
    if type(data) ~= 'table' then
        return nil
    end

    if data.job ~= nil then
        return data.job
    end

    if data.PlayerData and type(data.PlayerData) == 'table' and data.PlayerData.job ~= nil then
        return data.PlayerData.job
    end

    if data.playerData and type(data.playerData) == 'table' and data.playerData.job ~= nil then
        return data.playerData.job
    end

    if data.metadata and type(data.metadata) == 'table' and data.metadata.job ~= nil then
        return data.metadata.job
    end

    if data.groups and type(data.groups) == 'table' then
        if data.groups.job ~= nil then
            return data.groups.job
        end

        for groupName, groupData in pairs(data.groups) do
            if type(groupData) == 'table' and (groupData.name ~= nil or groupData.grade ~= nil or groupData.level ~= nil) then
                if type(groupName) == 'string' and groupData.name == nil then
                    groupData.name = groupName
                end
                return groupData
            end
        end
    end

    return nil
end

function MetaBridgeClient.getPlayerData()
    local framework = MetaBridgeClient.getFramework()

    if framework == 'qbcore' then
        local core = getQBCore()
        if core and core.Functions and core.Functions.GetPlayerData then
            local playerData = core.Functions.GetPlayerData()
            if type(playerData) == 'table' then
                return playerData
            end
        end
    elseif framework == 'qbox' then
        if exports and exports.qbx_core and exports.qbx_core.GetPlayerData then
            local ok, playerData = pcall(function()
                return exports.qbx_core:GetPlayerData()
            end)
            if ok and type(playerData) == 'table' then
                return playerData
            end
        end

        if type(QBX) == 'table' and type(QBX.PlayerData) == 'table' then
            return QBX.PlayerData
        end
    elseif framework == 'esx' then
        if type(ESX) == 'table' and type(ESX.PlayerData) == 'table' then
            return ESX.PlayerData
        end
    end

    local serverData = MetaBridgeClient.requestCallbackAwait('MetaBridge:getPlayerData')
    if type(serverData) == 'table' then
        return serverData
    end

    return nil
end

function MetaBridgeClient.getIdentifier()
    local playerData = MetaBridgeClient.getPlayerData()
    if type(playerData) == 'table' then
        if type(playerData.citizenid) == 'string' and playerData.citizenid ~= '' then
            return playerData.citizenid
        end

        if type(playerData.identifier) == 'string' and playerData.identifier ~= '' then
            return playerData.identifier
        end
    end

    return MetaBridgeClient.requestCallbackAwait('MetaBridge:getIdentifier')
end

function MetaBridgeClient.getJob()
    local playerData = MetaBridgeClient.getPlayerData()
    local job = resolveJobData(playerData)
    if job ~= nil then
        return job
    end

    return MetaBridgeClient.requestCallbackAwait('MetaBridge:getJob')
end

local function emitPlayerLoaded(payload)
    hasEmittedPlayerLoaded = true
    for _, handler in ipairs(playerLoadedHandlers) do
        handler(payload)
    end
end

function MetaBridgeClient.onPlayerLoaded(handler)
    if type(handler) ~= 'function' then
        return false
    end

    playerLoadedHandlers[#playerLoadedHandlers + 1] = handler

    if hasEmittedPlayerLoaded then
        handler({
            source = GetPlayerServerId(PlayerId()),
            playerData = MetaBridgeClient.getPlayerData(),
            framework = MetaBridgeClient.getFramework()
        })
    end

    return true
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
    local definition = MetaBridgeClient.requestCallbackAwait('MetaBridge:getItemDefinition', itemName)
    if type(definition) == 'table' and type(definition.label) == 'string' and definition.label ~= '' then
        return definition.label
    end

    return itemName
end

function MetaBridgeClient.getItemCount(itemName, meta)
    local count = MetaBridgeClient.requestCallbackAwait('MetaBridge:getItemCount', itemName, meta)
    return tonumber(count) or 0
end

function MetaBridgeClient.hasItem(itemName, amount, meta)
    local requiredAmount = tonumber(amount) or 1
    if requiredAmount < 1 then
        requiredAmount = 1
    end

    return MetaBridgeClient.getItemCount(itemName, meta) >= requiredAmount
end

function MetaBridgeClient.displayMetadata(metadataMap)
    if BridgeConfig and BridgeConfig.inventory and BridgeConfig.inventory.displayMetadata then
        return BridgeConfig.inventory.displayMetadata(metadataMap)
    end

    if exports and exports.ox_inventory and exports.ox_inventory.displayMetadata then
        exports.ox_inventory:displayMetadata(metadataMap)
        return true
    end

    return false
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

function MetaBridgeClient.notify(data)
    if BridgeConfig and BridgeConfig.notify and BridgeConfig.notify.client then
        return BridgeConfig.notify.client(data)
    end

    local payload = BridgeShared.normalizeNotifyPayload(data)

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

function MetaBridgeClient.progressBar(data)
    if BridgeConfig and BridgeConfig.progressBar and BridgeConfig.progressBar.client then
        return BridgeConfig.progressBar.client(data)
    end

    if lib and lib.progressBar then
        return lib.progressBar(data)
    end

    return false
end

function MetaBridgeClient.registerContext(data)
    if BridgeConfig and BridgeConfig.context and BridgeConfig.context.register then
        return BridgeConfig.context.register(data)
    end

    if lib and lib.registerContext then
        lib.registerContext(data)
        return true
    end

    return false
end

function MetaBridgeClient.showContext(contextId)
    if BridgeConfig and BridgeConfig.context and BridgeConfig.context.show then
        return BridgeConfig.context.show(contextId)
    end

    if lib and lib.showContext then
        lib.showContext(contextId)
        return true
    end

    return false
end

RegisterNetEvent('MetaBridge:callbackResponse', function(requestId, success, payload)
    local pending = pendingCallbacks[requestId]
    if not pending then
        return
    end

    pendingCallbacks[requestId] = nil

    local packed = type(payload) == 'table' and payload or { n = 0 }
    if packed.n == nil then
        packed.n = #packed
    end

    pending.callback(success == true, packed)
end)

local function requestBridgeCallback(name, callback, ...)
    callbackRequestId = callbackRequestId + 1
    local requestId = callbackRequestId
    local packedArgs = table.pack(...)

    pendingCallbacks[requestId] = {
        callback = callback
    }

    TriggerServerEvent('MetaBridge:invokeCallback', requestId, name, packedArgs)
    return requestId
end

function MetaBridgeClient.requestCallback(name, cb, ...)
    if BridgeConfig and BridgeConfig.callback and BridgeConfig.callback.client then
        local ok, result = pcall(BridgeConfig.callback.client, name, cb, ...)
        if ok and result ~= nil then
            return result
        end
    end

    if lib and lib.callback then
        local cbType = type(lib.callback)
        local mt = getmetatable(lib.callback)
        if cbType == 'function' or (cbType == 'table' and mt and type(mt.__call) == 'function') then
            local ok, result = pcall(lib.callback, name, false, cb, ...)
            if ok then
                return result
            end
        end
    end

    local core = getQBCore()
    if core and core.Functions and type(core.Functions.TriggerCallback) == 'function' then
        return core.Functions.TriggerCallback(name, cb, ...)
    end

    if ESX and type(ESX.TriggerServerCallback) == 'function' then
        return ESX.TriggerServerCallback(name, cb, ...)
    end

    return requestBridgeCallback(name, function(success, packed)
        if type(cb) ~= 'function' then
            return
        end

        if not success then
            cb(nil)
            return
        end

        cb(table.unpack(packed, 1, packed.n or #packed))
    end, ...)
end

function MetaBridgeClient.requestCallbackAwait(name, ...)
    if lib and lib.callback and type(lib.callback.await) == 'function' then
        local oxResponse = table.pack(pcall(lib.callback.await, name, false, ...))
        if oxResponse[1] then
            return table.unpack(oxResponse, 2, oxResponse.n)
        end
    end

    local done = false
    local results = nil
    local failedMessage = nil

    requestBridgeCallback(name, function(success, packed)
        if success then
            results = packed
        else
            failedMessage = packed and packed[1] or nil
        end
        done = true
    end, ...)

    local start = GetGameTimer()
    while not done and GetGameTimer() - start < 10000 do
        Wait(0)
    end

    if not done then
        return nil
    end

    if not results then
        return nil, failedMessage
    end

    return table.unpack(results, 1, results.n or #results)
end

function MetaBridgeClient.inputDialog(title, rows)
    if BridgeConfig and BridgeConfig.input and BridgeConfig.input.dialog then
        return BridgeConfig.input.dialog(title, rows)
    end

    if lib and lib.inputDialog then
        return lib.inputDialog(title, rows)
    end

    return nil
end

local function targetExport(resourceName, methodName)
    if not BridgeShared or not BridgeShared.getExportFunction then
        return nil
    end

    return BridgeShared.getExportFunction(resourceName, methodName, false)
end

function MetaBridgeClient.addTargetBoxZone(data)
    if BridgeConfig and BridgeConfig.target and BridgeConfig.target.addBoxZone then
        return BridgeConfig.target.addBoxZone(data)
    end

    local addOxBoxZone = targetExport('ox_target', 'addBoxZone')
    if addOxBoxZone then
        return addOxBoxZone(data)
    end

    local addQbBoxZone = targetExport('qb-target', 'AddBoxZone') or targetExport('qtarget', 'AddBoxZone')
    if addQbBoxZone then
        local zoneName = data.name or ('metabridge_box_%s'):format(math.random(10000, 99999))
        local size = data.size or vec3(1.0, 1.0, 1.0)
        local heading = data.rotation or data.heading or 0.0
        local zoneOptions = {
            name = zoneName,
            heading = heading,
            debugPoly = data.debug == true,
            minZ = data.coords.z - (size.z / 2),
            maxZ = data.coords.z + (size.z / 2)
        }
        local targetOptions = {
            options = data.options or {},
            distance = data.distance or 2.5
        }
        addQbBoxZone(zoneName, data.coords, size.x, size.y, zoneOptions, targetOptions)
        return zoneName
    end

    return nil
end

function MetaBridgeClient.addTargetSphereZone(data)
    if BridgeConfig and BridgeConfig.target and BridgeConfig.target.addSphereZone then
        return BridgeConfig.target.addSphereZone(data)
    end

    local addOxSphereZone = targetExport('ox_target', 'addSphereZone')
    if addOxSphereZone then
        return addOxSphereZone(data)
    end

    local addQbCircleZone = targetExport('qb-target', 'AddCircleZone') or targetExport('qtarget', 'AddCircleZone')
    if addQbCircleZone then
        local zoneName = data.name or ('metabridge_sphere_%s'):format(math.random(10000, 99999))
        local size = data.size or vec3(1.0, 1.0, 1.0)
        local radius = data.radius or size.x or 1.0
        local zoneOptions = {
            name = zoneName,
            debugPoly = data.debug == true,
            useZ = true
        }
        local targetOptions = {
            options = data.options or {},
            distance = data.distance or 2.5
        }
        addQbCircleZone(zoneName, data.coords, radius, zoneOptions, targetOptions)
        return zoneName
    end

    return nil
end

function MetaBridgeClient.removeTargetZone(zoneId)
    if BridgeConfig and BridgeConfig.target and BridgeConfig.target.removeZone then
        return BridgeConfig.target.removeZone(zoneId)
    end

    local removeOxZone = targetExport('ox_target', 'removeZone')
    if removeOxZone then
        removeOxZone(zoneId)
        return true
    end

    local removeQbZone = targetExport('qb-target', 'RemoveZone') or targetExport('qtarget', 'RemoveZone')
    if removeQbZone then
        removeQbZone(zoneId)
        return true
    end

    return false
end

function MetaBridgeClient.showTextUI(text)
    if BridgeConfig and BridgeConfig.textui and BridgeConfig.textui.show then
        return BridgeConfig.textui.show(text)
    end

    if lib and lib.showTextUI then
        lib.showTextUI(text)
        return true
    end

    return false
end

function MetaBridgeClient.hideTextUI()
    if BridgeConfig and BridgeConfig.textui and BridgeConfig.textui.hide then
        return BridgeConfig.textui.hide()
    end

    if lib and lib.hideTextUI then
        lib.hideTextUI()
        return true
    end

    return false
end

function MetaBridgeClient.isTextUIOpen()
    if BridgeConfig and BridgeConfig.textui and BridgeConfig.textui.isOpen then
        return BridgeConfig.textui.isOpen()
    end

    if lib and lib.isTextUIOpen then
        return lib.isTextUIOpen()
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

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function(...)
    emitPlayerLoaded({
        source = GetPlayerServerId(PlayerId()),
        playerData = MetaBridgeClient.getPlayerData(),
        framework = MetaBridgeClient.getFramework(),
        event = 'QBCore:Client:OnPlayerLoaded',
        args = { ... }
    })
end)

RegisterNetEvent('esx:playerLoaded', function(...)
    emitPlayerLoaded({
        source = GetPlayerServerId(PlayerId()),
        playerData = MetaBridgeClient.getPlayerData(),
        framework = MetaBridgeClient.getFramework(),
        event = 'esx:playerLoaded',
        args = { ... }
    })
end)

CreateThread(function()
    Wait(500)
    local playerData = MetaBridgeClient.getPlayerData()
    if type(playerData) == 'table' and next(playerData) ~= nil then
        emitPlayerLoaded({
            source = GetPlayerServerId(PlayerId()),
            playerData = playerData,
            framework = MetaBridgeClient.getFramework(),
            event = 'bootstrap'
        })
    end
end)
