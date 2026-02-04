# MetaBridge

A lightweight FiveM bridge to support **qbcore**, **esx**, **qbox**, **ox_core**, and **vrp** with a single, simple API.

## Features
- Automatic framework detection
- Single `MetaBridge.call` dispatcher
- Friendly helper methods like `MetaBridge.getIdentifier`
- Optional override via `BridgeConfig.framework`
- Inventory adapters with a unified API
- Optional dispatch helper for common dispatch systems

## Installation
1. Drop this folder into your server resources.
2. Ensure it starts **after** your framework resource.

```
ensure metaden-scripts-bridge
```

## Documentation
- `docs/overview.md`
- `docs/server-api.md`
- `docs/client-api.md`
- `docs/configuration.md`
- `docs/adapters.md`

## Usage (Server)
```lua
local framework = MetaBridge.getFramework()
print('Framework:', framework or 'none')

local identifier = MetaBridge.getIdentifier(source)
local job = MetaBridge.getJob(source)
local cash = MetaBridge.getMoney(source, 'cash')
```

## Usage (Client)
```lua
local framework = MetaBridgeClient.getFramework()
print('Framework:', framework or 'none')

MetaBridgeClient.setFuel(vehicle, 75.0)
MetaBridgeClient.giveVehicleKeys(GetVehicleNumberPlateText(vehicle))
```

## API
All helpers delegate to the active framework adapter.

- `MetaBridge.getFramework()`
- `MetaBridge.call(methodName, ...)`
- `MetaBridge.getPlayer(source)`
- `MetaBridge.getPlayerData(source)`
- `MetaBridge.getIdentifier(source)`
- `MetaBridge.getJob(source)`
- `MetaBridge.getMoney(source, moneyType)`
- `MetaBridge.hasItem(source, itemName, amount)`
- `MetaBridge.setFuel(vehicle, fuel)`
- `MetaBridge.giveVehicleKeys(source, plate)`
- `MetaBridge.getItemData(source, itemName, meta)`
- `MetaBridge.getItemCount(source, itemName, meta)`
- `MetaBridge.addItem(source, itemName, amount, meta)`
- `MetaBridge.removeItem(source, itemName, amount, meta)`
- `MetaBridge.register(methodName, handler)`

Client helpers:
- `MetaBridgeClient.getFramework()`
- `MetaBridgeClient.setFuel(vehicle, fuel)`
- `MetaBridgeClient.giveVehicleKeys(plate)`
- `MetaBridgeClient.sendDispatch(data)`
- `MetaBridgeClient.spawnPed(model, coords, heading, networked)`
- `MetaBridgeClient.spawnVehicle(model, coords, heading, networked)`
- `MetaBridgeClient.setEntityAsNoLongerNeeded(entity)`

## Configuration
Override detection if you want to force a framework:

```lua
BridgeConfig = BridgeConfig or {}
BridgeConfig.framework = 'qbcore' -- qbcore | esx | qbox | ox | vrp | standalone (aliases supported)

-- Optional: inventory system override
BridgeConfig.inventory = 'ox_inventory' -- framework | ox_inventory | qs-inventory | ps-inventory | qb-inventory | codem-inventory | core_inventory | ak47_inventory | origen_inventory

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

-- Optional helpers for fuel/keys if your resource names differ
BridgeConfig.fuel = {
    set = function(vehicle, fuel)
        -- custom fuel setter
    end
}

BridgeConfig.keys = {
    give = function(source, plate)
        -- custom keys giver
    end
}

-- Client-side override
BridgeConfig.keysClient = {
    give = function(plate)
        -- custom client keys logic
    end
}
```

## Test Command
The resource includes a simple command for quick validation:

```
/bridge_test
```

## Notes
- Detection order is: `qbox`, `qbcore`, `esx`, `ox`, `vrp`.
- Qbox uses `qbx_core` exports (no framework object).
- If your qbox export names differ, use `MetaBridge.register` to override.
- This bridge is intended for server-side usage.
