InventoryAdapters = InventoryAdapters or {}

InventoryAdapters['qb-inventory'] = {
    name = 'qb-inventory'
}

local qbInventory = InventoryAdapters['qb-inventory']

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

function qbInventory.getItemData(source, itemName, meta)
    local data = callExport('qb-inventory', 'GetItemByName', source, itemName)
    return data
end

function qbInventory.getItemCount(source, itemName, meta)
    local data = qbInventory.getItemData(source, itemName, meta)
    return data and (data.amount or data.count or 0) or 0
end

function qbInventory.addItem(source, itemName, amount, meta)
    return callExport('qb-inventory', 'AddItem', source, itemName, amount or 1, false, meta) == true
end

function qbInventory.removeItem(source, itemName, amount, meta)
    return callExport('qb-inventory', 'RemoveItem', source, itemName, amount or 1) == true
end
