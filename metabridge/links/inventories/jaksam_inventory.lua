InventoryAdapters = InventoryAdapters or {}

InventoryAdapters['jaksam_inventory'] = {
    name = 'jaksam_inventory'
}

local jaksamInventory = InventoryAdapters['jaksam_inventory']

local function callExport(methodName, ...)
    if not BridgeShared or not BridgeShared.isStarted or not BridgeShared.isStarted('jaksam_inventory') then
        return nil
    end

    local resource = exports['jaksam_inventory']
    local ok, fn = pcall(function() return resource[methodName] end)
    if not ok or type(fn) ~= 'function' then
        return nil
    end

    local args = table.pack(...)
    local invokeOk, result = pcall(function()
        return fn(resource, table.unpack(args, 1, args.n))
    end)
    if not invokeOk then
        return nil
    end

    return result
end

function jaksamInventory.getItemData(source, itemName, meta)
    if type(itemName) ~= 'string' or itemName == '' then
        return {}
    end

    local item = callExport('getItemByName', source, itemName, meta)
    if type(item) ~= 'table' then
        return {}
    end

    return { count = item.amount or 0, amount = item.amount or 0, metadata = item.metadata }
end

function jaksamInventory.getItemDefinition(source, itemName)
    local label = callExport('getItemLabel', itemName)
    return {
        name  = itemName,
        label = type(label) == 'string' and label or itemName,
        -- jaksam does not expose item weight via export; live weight checks use
        -- canCarryWeight which queries the inventory total weight directly.
        weight = 0,
    }
end

function jaksamInventory.getItemCount(source, itemName, meta)
    if type(itemName) ~= 'string' or itemName == '' then
        return 0
    end

    local total = callExport('getTotalItemAmount', source, itemName, meta)
    return tonumber(total) or 0
end

function jaksamInventory.addItem(source, itemName, amount, meta)
    amount = amount or 1
    local success = callExport('addItem', source, itemName, amount, meta)
    if type(success) == 'boolean' then
        return success
    end
    -- jaksam returns (success, resultCode); pcall wraps it so we only see first value
    return success ~= false and success ~= nil
end

function jaksamInventory.removeItem(source, itemName, amount, meta)
    amount = amount or 1
    local success = callExport('removeItem', source, itemName, amount, meta)
    if type(success) == 'boolean' then
        return success
    end
    return success ~= false and success ~= nil
end

function jaksamInventory.removeItemExact(source, itemName, amount, meta, slot)
    amount = amount or 1
    if type(slot) == 'number' then
        local success = callExport('removeItem', source, itemName, amount, meta, slot)
        if type(success) == 'boolean' then
            return success
        end
        return success ~= false and success ~= nil
    end

    return jaksamInventory.removeItem(source, itemName, amount, meta)
end

function jaksamInventory.getItemFromSlot(source, slot)
    if type(slot) ~= 'number' then
        return nil
    end

    local item = callExport('getItemFromSlot', source, slot)
    if type(item) ~= 'table' then
        return nil
    end

    return { name = item.name, metadata = item.metadata }
end

-- canCarryWeight: queries the live inventory to compare currentWeight + proposed weight
-- against the inventory's maxWeight.  This is necessary because jaksam does not expose
-- a CanCarryWeight export (unlike ox_inventory), and its ox_inventory compatibility shim
-- does not forward that call.
function jaksamInventory.canCarryWeight(source, weight)
    weight = tonumber(weight) or 0
    if weight <= 0 then
        return true
    end

    local inv = callExport('getInventory', source)
    if type(inv) ~= 'table' then
        -- Cannot determine; allow the action so legitimate players are not blocked.
        return true
    end

    local maxWeight = type(inv.limits) == 'table' and tonumber(inv.limits.maxWeight)
        or tonumber(inv.maxWeight)
    local currentWeight = tonumber(inv.totalWeight) or 0

    if not maxWeight or maxWeight <= 0 then
        return true
    end

    return (currentWeight + weight) <= maxWeight
end

-- getEmptySlot: counts occupied slots and compares against maxSlots.
-- Returns the first empty slot number if available, false otherwise.
-- jaksam stores items in inv.items as a hash keyed by "SLOT-N" strings.
function jaksamInventory.getEmptySlot(source)
    local inv = callExport('getInventory', source)
    if type(inv) ~= 'table' then
        return true
    end

    local maxSlots = type(inv.limits) == 'table' and tonumber(inv.limits.maxSlots)
        or tonumber(inv.maxSlots)
    if not maxSlots or maxSlots <= 0 then
        return true
    end

    local items = type(inv.items) == 'table' and inv.items or {}

    -- Build a set of occupied slot indices.
    local occupied = {}
    for key, itemData in pairs(items) do
        -- Keys are in the format "SLOT-N" (1-based).
        local slotNum = tonumber(tostring(key):match('SLOT%-(%d+)'))
        if slotNum then
            occupied[slotNum] = true
        end
    end

    -- Return the first unoccupied slot number.
    for i = 1, maxSlots do
        if not occupied[i] then
            return i
        end
    end

    return false
end

function jaksamInventory.getSlotsWithItem(source, itemName, meta)
    if type(itemName) ~= 'string' or itemName == '' then
        return {}
    end

    local items = callExport('getItemsByName', source, itemName, meta)
    if type(items) ~= 'table' then
        return {}
    end

    local slots = {}
    for _, itemData in ipairs(items) do
        if type(itemData) == 'table' then
            slots[#slots + 1] = {
                slot     = itemData.slot,
                name     = itemData.name,
                count    = itemData.amount or 0,
                metadata = itemData.metadata,
            }
        end
    end

    return slots
end

function jaksamInventory.setItemMetadata(source, slot, metadata)
    if type(slot) ~= 'number' then
        return false
    end

    if type(metadata) ~= 'table' then
        metadata = {}
    end

    local result = callExport('setItemMetadataInSlot', source, slot, metadata)
    if type(result) == 'boolean' then
        return result
    end

    return result ~= nil
end

function jaksamInventory.registerCreateItemHook(handler, options)
    -- jaksam_inventory does not expose a hook system compatible with ox_inventory's
    -- registerHook API.  Return false so callers know hooks are unavailable.
    return false
end
