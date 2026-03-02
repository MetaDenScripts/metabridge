InventoryAdapters = InventoryAdapters or {}

InventoryAdapters.framework = {
    name = 'framework'
}

function InventoryAdapters.framework.getItemData(source, itemName, meta)
    return nil
end

function InventoryAdapters.framework.getItemDefinition(source, itemName)
    return {
        name = itemName,
        label = itemName,
        weight = 0,
    }
end

function InventoryAdapters.framework.getItemCount(source, itemName, meta)
    return nil
end

function InventoryAdapters.framework.addItem(source, itemName, amount, meta)
    return nil
end

function InventoryAdapters.framework.removeItem(source, itemName, amount, meta)
    return nil
end

function InventoryAdapters.framework.removeItemExact(source, itemName, amount, meta, slot)
    return InventoryAdapters.framework.removeItem(source, itemName, amount, meta)
end

function InventoryAdapters.framework.canCarryWeight(source, weight)
    return true
end

function InventoryAdapters.framework.getEmptySlot(source)
    return true
end

function InventoryAdapters.framework.getSlotsWithItem(source, itemName, meta)
    return {}
end

function InventoryAdapters.framework.setItemMetadata(source, slot, metadata)
    return false
end

function InventoryAdapters.framework.registerCreateItemHook(handler, options)
    return false
end
