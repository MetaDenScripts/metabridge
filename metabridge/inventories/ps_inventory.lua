InventoryAdapters = InventoryAdapters or {}

InventoryAdapters['ps-inventory'] = {
    name = 'ps-inventory'
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

function InventoryAdapters['ps-inventory'].getItemData(source, itemName, meta)
    return callExport('ps-inventory', 'GetItemByName', source, itemName)
end

function InventoryAdapters['ps-inventory'].getItemCount(source, itemName, meta)
    local data = InventoryAdapters['ps-inventory'].getItemData(source, itemName, meta)
    return data and (data.amount or data.count or 0) or 0
end

function InventoryAdapters['ps-inventory'].addItem(source, itemName, amount, meta)
    return callExport('ps-inventory', 'AddItem', source, itemName, amount or 1, nil, meta) == true
end

function InventoryAdapters['ps-inventory'].removeItem(source, itemName, amount, meta)
    return callExport('ps-inventory', 'RemoveItem', source, itemName, amount or 1, nil) == true
end
