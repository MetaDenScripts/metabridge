InventoryAdapters = InventoryAdapters or {}

InventoryAdapters.ak47_inventory = {
    name = 'ak47_inventory'
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

function InventoryAdapters.ak47_inventory.getItemData(source, itemName, meta)
    return callExport('ak47_inventory', 'GetItem', source, itemName) or {}
end

function InventoryAdapters.ak47_inventory.getItemDefinition(source, itemName)
    local data = InventoryAdapters.ak47_inventory.getItemData(source, itemName)
    return {
        name = itemName,
        label = data.label or itemName,
        weight = data.weight or 0,
    }
end

function InventoryAdapters.ak47_inventory.getItemCount(source, itemName, meta)
    local data = InventoryAdapters.ak47_inventory.getItemData(source, itemName, meta)
    return data.count or data.amount or 0
end

function InventoryAdapters.ak47_inventory.addItem(source, itemName, amount, meta)
    local success = callExport('ak47_inventory', 'AddItem', source, itemName, amount or 1, nil)
    return success == true
end

function InventoryAdapters.ak47_inventory.removeItem(source, itemName, amount, meta)
    local success = callExport('ak47_inventory', 'RemoveItem', source, itemName, amount or 1)
    return success == true
end

function InventoryAdapters.ak47_inventory.removeItemExact(source, itemName, amount, meta, slot)
    return InventoryAdapters.ak47_inventory.removeItem(source, itemName, amount, meta)
end
