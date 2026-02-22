InventoryAdapters = InventoryAdapters or {}

InventoryAdapters['codem-inventory'] = {
    name = 'codem-inventory'
}

local codemInventory = InventoryAdapters['codem-inventory']

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

function codemInventory.getItemData(source, itemName, meta)
    return callExport('codem-inventory', 'GetItemsByName', source, itemName) or {}
end

function codemInventory.getItemDefinition(source, itemName)
    return {
        name = itemName,
        label = itemName,
        weight = 0,
    }
end

function codemInventory.getItemCount(source, itemName, meta)
    return callExport('codem-inventory', 'GetItemsTotalAmount', source, itemName) or 0
end

function codemInventory.addItem(source, itemName, amount, meta)
    return callExport('codem-inventory', 'AddItem', source, itemName, amount or 1, nil, meta) == true
end

function codemInventory.removeItem(source, itemName, amount, meta)
    return callExport('codem-inventory', 'RemoveItem', source, itemName, amount or 1, nil) == true
end

function codemInventory.removeItemExact(source, itemName, amount, meta, slot)
    return codemInventory.removeItem(source, itemName, amount, meta)
end
