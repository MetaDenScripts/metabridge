InventoryAdapters = InventoryAdapters or {}

InventoryAdapters.origen_inventory = {
    name = 'origen_inventory'
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

function InventoryAdapters.origen_inventory.getItemData(source, itemName, meta)
    return callExport('origen_inventory', 'GetItem', source, itemName) or {}
end

function InventoryAdapters.origen_inventory.getItemCount(source, itemName, meta)
    local data = InventoryAdapters.origen_inventory.getItemData(source, itemName, meta)
    return data.count or data.amount or 0
end

function InventoryAdapters.origen_inventory.addItem(source, itemName, amount, meta)
    local success = callExport('origen_inventory', 'AddItem', source, itemName, amount or 1, meta)
    return success == true
end

function InventoryAdapters.origen_inventory.removeItem(source, itemName, amount, meta)
    local success = callExport('origen_inventory', 'RemoveItem', source, itemName, amount or 1)
    return success == true
end
