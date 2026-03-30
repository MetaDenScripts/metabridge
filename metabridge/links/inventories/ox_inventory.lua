InventoryAdapters = InventoryAdapters or {}

InventoryAdapters.ox_inventory = {
    name = 'ox_inventory'
}

local function callExport(resourceName, methodName, ...)
    if not BridgeShared or not BridgeShared.isStarted or not BridgeShared.isStarted(resourceName) then
        return nil
    end

    local resource = exports[resourceName]
    local ok, fn = pcall(function() return resource[methodName] end)
    if not ok or type(fn) ~= 'function' then
        return nil
    end

    local args = table.pack(...)
    local invokeOk, result = pcall(function()
        return fn(resource, table.unpack(args, 1, args.n))
    end)
    if not invokeOk then
        return nil
    end

    return result
end

function InventoryAdapters.ox_inventory.getItemData(source, itemName, meta)
    return callExport('ox_inventory', 'GetItem', source, itemName, meta) or {}
end

function InventoryAdapters.ox_inventory.getItemDefinition(source, itemName)
    return callExport('ox_inventory', 'Items', itemName)
end

function InventoryAdapters.ox_inventory.getItemCount(source, itemName, meta)
    local data = InventoryAdapters.ox_inventory.getItemData(source, itemName, meta)
    return data.count or data.amount or 0
end

function InventoryAdapters.ox_inventory.addItem(source, itemName, amount, meta)
    amount = amount or 1

    local success = callExport('ox_inventory', 'AddItem', source, itemName, amount, meta)
    if type(success) == 'boolean' then
        return success
    end

    if type(success) == 'table' then
        return success[1] == true
    end

    return false
end

function InventoryAdapters.ox_inventory.removeItem(source, itemName, amount, meta)
    amount = amount or 1

    local items = callExport('ox_inventory', 'Search', source, 'slots', itemName)
    if not items or #items == 0 then
        return false
    end

    local total = 0
    for _, itemData in ipairs(items) do
        total = total + itemData.count
    end
    if total < amount then
        return false
    end

    local remaining = amount
    for _, itemData in ipairs(items) do
        if remaining <= 0 then
            break
        end

        local remove = math.min(itemData.count, remaining)
        if callExport('ox_inventory', 'RemoveItem', source, itemName, remove, itemData.metadata, itemData.slot) then
            remaining = remaining - remove
        end
    end

    return remaining == 0
end

function InventoryAdapters.ox_inventory.removeItemExact(source, itemName, amount, meta, slot)
    amount = amount or 1

    if type(slot) == 'number' then
        local removed = callExport('ox_inventory', 'RemoveItem', source, itemName, amount, meta, slot)
        return removed == true
    end

    return InventoryAdapters.ox_inventory.removeItem(source, itemName, amount, meta)
end

function InventoryAdapters.ox_inventory.getItemFromSlot(source, slot)
    if type(slot) ~= 'number' then
        return nil
    end

    local itemInSlot = callExport('ox_inventory', 'GetSlot', source, slot)
    if not itemInSlot then
        return nil
    end

    return { name = itemInSlot.name, metadata = itemInSlot.metadata }
end

function InventoryAdapters.ox_inventory.canCarryWeight(source, weight)
    weight = tonumber(weight) or 0
    if weight <= 0 then
        return true
    end

    local canCarry = callExport('ox_inventory', 'CanCarryWeight', source, weight)
    if canCarry == nil then
        return true
    end

    if type(canCarry) == 'boolean' then
        return canCarry
    end

    if type(canCarry) == 'number' then
        return canCarry >= weight
    end

    return canCarry ~= false
end

function InventoryAdapters.ox_inventory.getEmptySlot(source)
    local slot = callExport('ox_inventory', 'GetEmptySlot', source)
    if slot == nil or slot == false then
        return false
    end

    return slot
end

function InventoryAdapters.ox_inventory.getSlotsWithItem(source, itemName, meta)
    if type(itemName) ~= 'string' or itemName == '' then
        return {}
    end

    local items = callExport('ox_inventory', 'Search', source, 'slots', itemName, meta)
    if type(items) ~= 'table' then
        return {}
    end

    local slots = {}
    for slotKey, itemData in pairs(items) do
        if type(itemData) == 'table' then
            if itemData.slot == nil and type(slotKey) == 'number' then
                itemData.slot = slotKey
            end
            slots[#slots + 1] = itemData
        end
    end

    return slots
end

function InventoryAdapters.ox_inventory.setItemMetadata(source, slot, metadata)
    if type(slot) ~= 'number' then
        return false
    end

    if type(metadata) ~= 'table' then
        metadata = {}
    end

    local result = callExport('ox_inventory', 'SetMetadata', source, slot, metadata)
    if type(result) == 'boolean' then
        return result
    end

    return result ~= nil
end

function InventoryAdapters.ox_inventory.registerCreateItemHook(handler, options)
    if type(handler) ~= 'function' then
        return false
    end

    local hookId = callExport('ox_inventory', 'registerHook', 'createItem', handler, options)
    return hookId ~= nil
end
