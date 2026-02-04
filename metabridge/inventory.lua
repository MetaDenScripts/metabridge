BridgeInventory = BridgeInventory or {}

local activeInventory = nil
local overrides = {}

local function resolveInventory()
    if BridgeConfig and BridgeConfig.inventory then
        if BridgeShared and BridgeShared.normalizeInventory then
            local normalized = BridgeShared.normalizeInventory(BridgeConfig.inventory)
            if normalized then
                return normalized
            end
        else
            return BridgeConfig.inventory
        end
    end

    if BridgeShared and BridgeShared.detectInventory then
        return BridgeShared.detectInventory()
    end

    return 'framework'
end

function BridgeInventory.init()
    local inventoryName = resolveInventory()
    if not inventoryName then
        activeInventory = nil
        return nil
    end

    if InventoryAdapters and InventoryAdapters[inventoryName] then
        activeInventory = InventoryAdapters[inventoryName]
        if activeInventory.init then
            activeInventory.init()
        end
    else
        activeInventory = nil
    end

    return inventoryName
end

function BridgeInventory.getInventory()
    if not activeInventory then
        BridgeInventory.init()
    end

    return activeInventory
end

function BridgeInventory.isReady()
    return BridgeInventory.getInventory() ~= nil
end

function BridgeInventory.register(methodName, handler)
    overrides[methodName] = handler
end

function BridgeInventory.call(methodName, ...)
    if overrides[methodName] then
        return overrides[methodName](...)
    end

    if not activeInventory then
        BridgeInventory.init()
    end

    if not activeInventory then
        return nil
    end

    local handler = activeInventory[methodName]
    if not handler then
        return nil
    end

    return handler(...)
end
