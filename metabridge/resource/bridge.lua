MetaBridge = MetaBridge or {}

local activeAdapter = nil
local activeFramework = nil
local overrides = {}
local fallbackCallbacks = {}

local function isCallable(value)
    local valueType = type(value)
    if valueType == 'function' then
        return true
    end

    if valueType == 'table' then
        local mt = getmetatable(value)
        if mt and type(mt.__call) == 'function' then
            return true
        end
    end

    return false
end

local function resolveFramework()
    if BridgeConfig and BridgeConfig.framework then
        if BridgeShared and BridgeShared.normalizeFramework then
            local normalized = BridgeShared.normalizeFramework(BridgeConfig.framework)
            if normalized then
                return normalized
            end
        else
            return BridgeConfig.framework
        end
    end

    if BridgeShared and BridgeShared.detectFramework then
        return BridgeShared.detectFramework()
    end

    return nil
end

function MetaBridge.init()
    activeFramework = resolveFramework()
    BridgeShared.debug('server.init', 'Resolved framework', { framework = activeFramework })
    if not activeFramework then
        activeAdapter = nil
        return nil
    end

    if BridgeAdapters and BridgeAdapters[activeFramework] then
        activeAdapter = BridgeAdapters[activeFramework]
        if activeAdapter.init then
            activeAdapter.init()
        end
    else
        activeAdapter = nil
    end

    return activeFramework
end

function MetaBridge.getFramework()
    if not activeFramework then
        MetaBridge.init()
    end

    return activeFramework
end

function MetaBridge.isReady()
    return MetaBridge.getFramework() ~= nil and activeAdapter ~= nil
end

function MetaBridge.register(methodName, handler)
    overrides[methodName] = handler
end

function MetaBridge.call(methodName, ...)
    if overrides[methodName] then
        return overrides[methodName](...)
    end

    if not activeAdapter then
        MetaBridge.init()
    end

    if not activeAdapter then
        error('MetaBridge has no active adapter.')
    end

    local handler = activeAdapter[methodName]
    if not handler then
        error(('MetaBridge method "%s" is not supported for %s.'):format(methodName, activeFramework or 'unknown'))
    end

    local result = handler(...)
    BridgeShared.debug('server.call', 'Adapter call executed', {
        framework = activeFramework,
        method = methodName,
        hasResult = result ~= nil,
        resultType = type(result)
    })
    return result
end

function MetaBridge.getPlayer(source)
    return MetaBridge.call('getPlayer', source)
end

function MetaBridge.getPlayerData(source)
    return MetaBridge.call('getPlayerData', source)
end

function MetaBridge.getIdentifier(source)
    return MetaBridge.call('getIdentifier', source)
end

function MetaBridge.getJob(source)
    local job = MetaBridge.call('getJob', source)
    if job ~= nil then
        return job
    end

    local playerData = MetaBridge.getPlayerData(source)
    local fallbackJob = BridgeShared.resolveJobData(playerData)

    BridgeShared.debug('server.getJob', 'Job resolution fallback used', {
        source = source,
        framework = activeFramework,
        directWasNil = true,
        fallbackHasJob = fallbackJob ~= nil
    })

    return fallbackJob
end

function MetaBridge.getMoney(source, moneyType)
    return MetaBridge.call('getMoney', source, moneyType)
end

function MetaBridge.hasItem(source, itemName, amount)
    local inventoryHas = BridgeInventory and BridgeInventory.call
        and BridgeInventory.call('getItemCount', source, itemName) ~= nil

    if inventoryHas then
        local count = BridgeInventory.call('getItemCount', source, itemName)
        amount = amount or 1
        return (count or 0) >= amount
    end

    return MetaBridge.call('hasItem', source, itemName, amount)
end

function MetaBridge.getItemData(source, itemName, meta)
    if BridgeInventory and BridgeInventory.call then
        local data = BridgeInventory.call('getItemData', source, itemName, meta)
        if data ~= nil then
            return data
        end
    end

    return nil
end

function MetaBridge.getItemDefinition(source, itemName)
    if BridgeInventory and BridgeInventory.call then
        local definition = BridgeInventory.call('getItemDefinition', source, itemName)
        if definition ~= nil then
            return definition
        end
    end

    local itemData = MetaBridge.getItemData(source, itemName)
    if type(itemData) == 'table' then
        return itemData
    end

    return nil
end

function MetaBridge.getItemCount(source, itemName, meta)
    if BridgeInventory and BridgeInventory.call then
        local count = BridgeInventory.call('getItemCount', source, itemName, meta)
        if count ~= nil then
            return count
        end
    end

    local fallback = MetaBridge.call('hasItem', source, itemName, 1)
    if fallback then
        return 1
    end

    return 0
end

function MetaBridge.getItemFromSlot(source, slot)
    if BridgeInventory and BridgeInventory.call then
        local itemData = BridgeInventory.call('getItemFromSlot', source, slot)
        if itemData ~= nil then
            return itemData
        end
    end

    return nil
end

function MetaBridge.notify(source, data)
    if BridgeConfig and BridgeConfig.notify and BridgeConfig.notify.server then
        return BridgeConfig.notify.server(source, data)
    end

    local payload = BridgeShared.normalizeNotifyPayload(data)

    if BridgeShared and BridgeShared.isStarted and BridgeShared.isStarted('ox_lib') then
        TriggerClientEvent('ox_lib:notify', source, payload)
        return true
    end

    local message = payload.description or payload.message or payload.text or ''
    local notifyType = payload.type or 'primary'
    local length = payload.duration or payload.length or 5000

    local framework = MetaBridge.getFramework()
    if framework == 'qbcore' or framework == 'qbox' then
        TriggerClientEvent('QBCore:Notify', source, message, notifyType, length)
        return true
    end

    if framework == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
        return true
    end

    return false
end

function MetaBridge.registerCallback(...)
    local args = table.pack(...)
    local name = nil
    local handler = nil

    if type(args[1]) == 'string' and isCallable(args[2]) then
        name = args[1]
        handler = args[2]
    else
        for i = 1, args.n do
            if type(args[i]) == 'string' then
                name = args[i]
                for j = i + 1, args.n do
                    if isCallable(args[j]) then
                        handler = args[j]
                        break
                    end
                end
                if handler then
                    break
                end
            end
        end
    end

    if type(name) ~= 'string' or not isCallable(handler) then
        local signature = {}
        for i = 1, args.n do
            signature[i] = type(args[i])
        end

        BridgeShared.debug('server.callback', 'Rejected callback registration due to invalid args', {
            signature = signature,
            resolvedNameType = type(name),
            resolvedHandlerType = type(handler)
        })
        return false
    end

    if not (type(args[1]) == 'string' and isCallable(args[2])) then
        BridgeShared.debug('server.callback', 'Normalized registerCallback argument layout', {
            callbackName = name
        })
    end

    fallbackCallbacks[name] = handler
    BridgeShared.debug('server.callback', 'Registered fallback callback', { name = name })
    local registered = false

    if BridgeConfig and BridgeConfig.callback and BridgeConfig.callback.serverRegister then
        local ok, result = pcall(BridgeConfig.callback.serverRegister, name, handler)
        if ok and result ~= false then
            registered = true
            BridgeShared.debug('server.callback', 'Registered via BridgeConfig callback provider', { name = name })
        end
    end

    if lib and lib.callback and lib.callback.register then
        local okOx, oxErr = pcall(lib.callback.register, name, handler)
        if okOx then
            registered = true
            BridgeShared.debug('server.callback', 'Registered via ox_lib callback provider', { name = name })
        else
            BridgeShared.debug('server.callback', 'ox_lib callback registration failed', {
                name = name,
                error = tostring(oxErr)
            })
        end
    end

    return registered
end

function MetaBridge.addItem(source, itemName, amount, meta)
    if BridgeInventory and BridgeInventory.call then
        local result = BridgeInventory.call('addItem', source, itemName, amount, meta)
        if result ~= nil then
            return result
        end
    end

    return MetaBridge.call('addItem', source, itemName, amount, meta)
end

function MetaBridge.removeItem(source, itemName, amount, meta)
    if BridgeInventory and BridgeInventory.call then
        local result = BridgeInventory.call('removeItem', source, itemName, amount, meta)
        if result ~= nil then
            return result
        end
    end

    return MetaBridge.call('removeItem', source, itemName, amount, meta)
end

function MetaBridge.removeItemExact(source, itemName, amount, meta, slot)
    if BridgeInventory and BridgeInventory.call then
        local result = BridgeInventory.call('removeItemExact', source, itemName, amount, meta, slot)
        if result ~= nil then
            return result
        end
    end

    return MetaBridge.removeItem(source, itemName, amount, meta)
end

function MetaBridge.canCarryWeight(source, weight)
    if BridgeInventory and BridgeInventory.call then
        local result = BridgeInventory.call('canCarryWeight', source, weight)
        if result ~= nil then
            return result ~= false
        end
    end

    return true
end

function MetaBridge.getEmptySlot(source)
    if BridgeInventory and BridgeInventory.call then
        local result = BridgeInventory.call('getEmptySlot', source)
        if result ~= nil then
            return result
        end
    end

    return true
end

function MetaBridge.getSlotsWithItem(source, itemName, meta)
    if BridgeInventory and BridgeInventory.call then
        local result = BridgeInventory.call('getSlotsWithItem', source, itemName, meta)
        if type(result) == 'table' then
            return result
        end
    end

    return {}
end

function MetaBridge.setItemMetadata(source, slot, metadata)
    if BridgeInventory and BridgeInventory.call then
        local result = BridgeInventory.call('setItemMetadata', source, slot, metadata)
        if result ~= nil then
            return result ~= false
        end
    end

    return false
end

function MetaBridge.registerCreateItemHook(handler, options)
    if BridgeInventory and BridgeInventory.call then
        local result = BridgeInventory.call('registerCreateItemHook', handler, options)
        if result ~= nil then
            return result ~= false
        end
    end

    return false
end

function MetaBridge.setFuel(vehicle, fuel)
    return MetaBridge.call('setFuel', vehicle, fuel)
end

function MetaBridge.giveVehicleKeys(source, plate)
    return MetaBridge.call('giveVehicleKeys', source, plate)
end

function MetaBridge.createOwnedVehicle(request)
    if BridgeConfig and BridgeConfig.vehicle and BridgeConfig.vehicle.server and BridgeConfig.vehicle.server.create then
        return BridgeConfig.vehicle.server.create(request)
    end

    return MetaBridge.call('createOwnedVehicle', request)
end

function MetaBridge.getOwnedVehicle(lookup)
    if BridgeConfig and BridgeConfig.vehicle and BridgeConfig.vehicle.server and BridgeConfig.vehicle.server.get then
        return BridgeConfig.vehicle.server.get(lookup)
    end

    return MetaBridge.call('getOwnedVehicle', lookup)
end

function MetaBridge.spawnOwnedVehicle(request)
    if BridgeConfig and BridgeConfig.vehicle and BridgeConfig.vehicle.server and BridgeConfig.vehicle.server.spawn then
        return BridgeConfig.vehicle.server.spawn(request)
    end

    return MetaBridge.call('spawnOwnedVehicle', request)
end

if IsDuplicityVersion and IsDuplicityVersion() then
    local registerCoreCallbacks = GetCurrentResourceName and GetCurrentResourceName() == 'metabridge'

    RegisterNetEvent('MetaBridge:invokeCallback', function(requestId, callbackName, packedArgs)
        local src = source

        BridgeShared.debug('server.callback', 'Received fallback callback invocation', {
            source = src,
            requestId = requestId,
            callbackName = callbackName
        })

        if type(requestId) ~= 'number' or type(callbackName) ~= 'string' then
            return
        end

        local handler = fallbackCallbacks[callbackName]
        if type(handler) ~= 'function' then
            BridgeShared.debug('server.callback', 'Fallback callback missing', { callbackName = callbackName })
            TriggerClientEvent('MetaBridge:callbackResponse', src, requestId, false, {
                n = 1,
                [1] = ('callback %s does not exist'):format(callbackName)
            })
            return
        end

        local args = type(packedArgs) == 'table' and packedArgs or {}
        local argCount = tonumber(args.n) or #args

        local invocation = table.pack(pcall(function()
            return handler(src, table.unpack(args, 1, argCount))
        end))

        BridgeShared.debug('server.callback', 'Fallback callback executed', {
            callbackName = callbackName,
            source = src,
            success = invocation[1] == true
        })

        if not invocation[1] then
            TriggerClientEvent('MetaBridge:callbackResponse', src, requestId, false, {
                n = 1,
                [1] = invocation[2]
            })
            return
        end

        local response = { n = invocation.n - 1 }
        for i = 2, invocation.n do
            response[i - 1] = invocation[i]
        end

        TriggerClientEvent('MetaBridge:callbackResponse', src, requestId, true, response)
    end)

    RegisterNetEvent('MetaBridge:giveVehicleKeys', function(plate)
        local src = source
        MetaBridge.giveVehicleKeys(src, plate)
    end)

    if registerCoreCallbacks then
        MetaBridge.registerCallback('MetaBridge:getPlayerData', function(source)
            return MetaBridge.getPlayerData(source)
        end)

        MetaBridge.registerCallback('MetaBridge:getIdentifier', function(source)
            return MetaBridge.getIdentifier(source)
        end)

        MetaBridge.registerCallback('MetaBridge:getJob', function(source)
            return MetaBridge.getJob(source)
        end)

        MetaBridge.registerCallback('MetaBridge:getItemCount', function(source, itemName, meta)
            return MetaBridge.getItemCount(source, itemName, meta)
        end)

        MetaBridge.registerCallback('MetaBridge:getItemDefinition', function(source, itemName)
            return MetaBridge.getItemDefinition(source, itemName)
        end)
    end
end
