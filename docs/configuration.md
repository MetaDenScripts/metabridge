# Configuration

Create `BridgeConfig` in a shared file loaded **before** the bridge (for example, a `config.lua` loaded as a `shared_script`).

```lua
BridgeConfig = BridgeConfig or {}

-- Optional: force a framework instead of auto-detection
BridgeConfig.framework = 'qbcore' -- qbcore | esx | qbox

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
```

## Notes
- If `framework` is omitted, detection is automatic.
- If you override `keysClient.give`, the server event is not used.
- If you override `fuel.set`, the built-in fuel integrations are skipped.
