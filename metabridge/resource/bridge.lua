MetaBridge = MetaBridge or {}

local activeAdapter = nil
local activeFramework = nil
local overrides = {}

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

    return handler(...)
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
    return MetaBridge.call('getJob', source)
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

    if type(slot) == 'number' and exports and exports.ox_inventory and exports.ox_inventory.GetSlot then
        local itemInSlot = exports.ox_inventory:GetSlot(source, slot)
        if itemInSlot then
            return { name = itemInSlot.name, metadata = itemInSlot.metadata }
        end
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

function MetaBridge.notify(source, data)
    if BridgeConfig and BridgeConfig.notify and BridgeConfig.notify.server then
        return BridgeConfig.notify.server(source, data)
    end

    local payload = normalizeNotifyPayload(data)

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

function MetaBridge.setFuel(vehicle, fuel)
    return MetaBridge.call('setFuel', vehicle, fuel)
end

function MetaBridge.giveVehicleKeys(source, plate)
    return MetaBridge.call('giveVehicleKeys', source, plate)
end

if IsDuplicityVersion and IsDuplicityVersion() then
    RegisterNetEvent('MetaBridge:giveVehicleKeys', function(plate)
        local src = source
        MetaBridge.giveVehicleKeys(src, plate)
    end)
end
