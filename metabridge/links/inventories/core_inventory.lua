InventoryAdapters = InventoryAdapters or {}

InventoryAdapters.core_inventory = {
    name = 'core_inventory'
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

function InventoryAdapters.core_inventory.getItemData(source, itemName, meta)
    return callExport('core_inventory', 'getItem', source, itemName) or {}
end

function InventoryAdapters.core_inventory.getItemDefinition(source, itemName)
    local data = InventoryAdapters.core_inventory.getItemData(source, itemName)
    return {
        name = itemName,
        label = data.label or itemName,
        weight = data.weight or 0,
    }
end

function InventoryAdapters.core_inventory.getItemCount(source, itemName, meta)
    local data = InventoryAdapters.core_inventory.getItemData(source, itemName, meta)
    return data.count or data.amount or 0
end

function InventoryAdapters.core_inventory.addItem(source, itemName, amount, meta)
    local success = callExport('core_inventory', 'addItem', source, itemName, amount or 1, meta)
    return success == true
end

function InventoryAdapters.core_inventory.removeItem(source, itemName, amount, meta)
    local success = callExport('core_inventory', 'removeItem', source, itemName, amount or 1)
    return success == true
end

function InventoryAdapters.core_inventory.removeItemExact(source, itemName, amount, meta, slot)
    return InventoryAdapters.core_inventory.removeItem(source, itemName, amount, meta)
end
