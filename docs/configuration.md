# Configuration

Create `BridgeConfig` in a shared file loaded **before** the bridge (for example, a `config.lua` loaded as a `shared_script`).

```lua
BridgeConfig = BridgeConfig or {}

-- Optional: force a framework instead of auto-detection
BridgeConfig.framework = 'qbcore' -- qbcore | esx | qbox | ox | vrp | standalone (aliases supported)

-- Optional: inventory system override
BridgeConfig.inventory = 'ox_inventory' -- framework | ox_inventory | qs-inventory | ps-inventory | qb-inventory | codem-inventory | core_inventory | ak47_inventory | origen_inventory

-- Optional: inventory UI helpers
BridgeConfig.inventory = BridgeConfig.inventory or {}
BridgeConfig.inventory.getItemImage = function(itemName)
    -- return an image URI for your inventory system
end

-- Optional: dispatch system override
BridgeConfig.dispatch = {
    system = 'ps', -- ps | qs | rcore | cd | standalone
    send = function(data)
        -- custom dispatch send logic
    end,
    filter = function(data)
        -- client-side filter for incoming alerts
        return true
    end,
    filterServer = function(data)
        -- server-side filter before broadcast
        return true
    end
}

-- Optional: notification overrides
BridgeConfig.notify = {
    client = function(data)
        -- custom client notify
    end,
    server = function(source, data)
        -- custom server notify (usually TriggerClientEvent)
    end
}

-- Optional: override fuel integration
BridgeConfig.fuel = {
    set = function(vehicle, fuel)
        -- custom fuel setter
    end
}

-- Optional: override server-side key integration
BridgeConfig.keys = {
    give = function(source, plate)
        -- custom server-side key logic
    end
}

-- Optional: override client-side key integration
BridgeConfig.keysClient = {
    give = function(plate)
        -- custom client-side key logic
    end
}

-- Optional: callback override (client-side)
BridgeConfig.callback = {
    client = function(name, cb, ...)
        -- custom callback handler
    end
}

-- Optional: override target integration
BridgeConfig.target = {
    addModel = function(models, options)
        -- custom target addModel logic
    end
}
```

## Notes
- If `framework` is omitted, detection is automatic.
- If you override `keysClient.give`, the server event is not used.
- If you override `fuel.set`, the built-in fuel integrations are skipped.
