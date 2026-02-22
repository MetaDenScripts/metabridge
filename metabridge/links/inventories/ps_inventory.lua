InventoryAdapters = InventoryAdapters or {}

InventoryAdapters['ps-inventory'] = {
    name = 'ps-inventory'
}

local psInventory = InventoryAdapters['ps-inventory']

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

function psInventory.getItemData(source, itemName, meta)
    return callExport('ps-inventory', 'GetItemByName', source, itemName)
end

function psInventory.getItemDefinition(source, itemName)
    local data = psInventory.getItemData(source, itemName)
    if type(data) ~= 'table' then
        return nil
    end

    return {
        name = itemName,
        label = data.label or itemName,
        weight = data.weight or 0,
    }
end

function psInventory.getItemCount(source, itemName, meta)
    local data = psInventory.getItemData(source, itemName, meta)
    return data and (data.amount or data.count or 0) or 0
end

function psInventory.addItem(source, itemName, amount, meta)
    return callExport('ps-inventory', 'AddItem', source, itemName, amount or 1, nil, meta) == true
end

function psInventory.removeItem(source, itemName, amount, meta)
    return callExport('ps-inventory', 'RemoveItem', source, itemName, amount or 1, nil) == true
end

function psInventory.removeItemExact(source, itemName, amount, meta, slot)
    return psInventory.removeItem(source, itemName, amount, meta)
end
