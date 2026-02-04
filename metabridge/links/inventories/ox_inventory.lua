InventoryAdapters = InventoryAdapters or {}

InventoryAdapters.ox_inventory = {
    name = 'ox_inventory'
}

local function callExport(resourceName, methodName, ...)
    if not exports or not exports[resourceName] then
        return nil
    end

    local resource = exports[resourceName]
    local fn = resource[methodName]
    if type(fn) ~= 'function' then
        return nil
    end

    return fn(resource, ...)
end

function InventoryAdapters.ox_inventory.getItemData(source, itemName, meta)
    return callExport('ox_inventory', 'GetItem', source, itemName, meta) or {}
end

function InventoryAdapters.ox_inventory.getItemCount(source, itemName, meta)
    local data = InventoryAdapters.ox_inventory.getItemData(source, itemName, meta)
    return data.count or data.amount or 0
end

function InventoryAdapters.ox_inventory.addItem(source, itemName, amount, meta)
    amount = amount or 1

    local itemData = callExport('ox_inventory', 'Items', itemName)
    if itemData then
        local weight = itemData.weight or 0
        if weight > 0 then
            local totalWeight = weight * amount
            local canCarry = callExport('ox_inventory', 'CanCarryWeight', source, totalWeight)
            if canCarry == false then
                return false
            end
        end
    end

    local hasSlot = callExport('ox_inventory', 'GetEmptySlot', source)
    if hasSlot == false or hasSlot == nil then
        return false
    end

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
