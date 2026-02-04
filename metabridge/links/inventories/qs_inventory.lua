InventoryAdapters = InventoryAdapters or {}

InventoryAdapters['qs-inventory'] = {
    name = 'qs-inventory'
}

local qsInventory = InventoryAdapters['qs-inventory']

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

function qsInventory.getItemData(source, itemName, meta)
    local count = callExport('qs-inventory', 'GetItemTotalAmount', source, itemName)
    return { amount = count or 0 }
end

function qsInventory.getItemCount(source, itemName, meta)
    return callExport('qs-inventory', 'GetItemTotalAmount', source, itemName) or 0
end

function qsInventory.addItem(source, itemName, amount, meta)
    return callExport('qs-inventory', 'AddItem', source, itemName, amount or 1, nil, meta) == true
end

function qsInventory.removeItem(source, itemName, amount, meta)
    return callExport('qs-inventory', 'RemoveItem', source, itemName, amount or 1, nil) == true
end
