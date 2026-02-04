InventoryAdapters = InventoryAdapters or {}

InventoryAdapters['codem-inventory'] = {
    name = 'codem-inventory'
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

function InventoryAdapters['codem-inventory'].getItemData(source, itemName, meta)
    return callExport('codem-inventory', 'GetItemsByName', source, itemName) or {}
end

function InventoryAdapters['codem-inventory'].getItemCount(source, itemName, meta)
    return callExport('codem-inventory', 'GetItemsTotalAmount', source, itemName) or 0
end

function InventoryAdapters['codem-inventory'].addItem(source, itemName, amount, meta)
    return callExport('codem-inventory', 'AddItem', source, itemName, amount or 1, nil, meta) == true
end

function InventoryAdapters['codem-inventory'].removeItem(source, itemName, amount, meta)
    return callExport('codem-inventory', 'RemoveItem', source, itemName, amount or 1, nil) == true
end
