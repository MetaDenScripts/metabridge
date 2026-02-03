# MetaDen Scripts Bridge

A lightweight FiveM bridge to support **qbcore**, **esx**, and **qbox** with a single, simple API.

## Features
- Automatic framework detection
- Single `Bridge.call` dispatcher
- Friendly helper methods like `Bridge.getIdentifier`
- Optional override via `BridgeConfig.framework`

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
local framework = Bridge.getFramework()
print('Framework:', framework or 'none')

local identifier = Bridge.getIdentifier(source)
local job = Bridge.getJob(source)
local cash = Bridge.getMoney(source, 'cash')
```

## Usage (Client)
```lua
local framework = BridgeClient.getFramework()
print('Framework:', framework or 'none')

BridgeClient.setFuel(vehicle, 75.0)
BridgeClient.giveVehicleKeys(GetVehicleNumberPlateText(vehicle))
```

## API
All helpers delegate to the active framework adapter.

- `Bridge.getFramework()`
- `Bridge.call(methodName, ...)`
- `Bridge.getPlayer(source)`
- `Bridge.getPlayerData(source)`
- `Bridge.getIdentifier(source)`
- `Bridge.getJob(source)`
- `Bridge.getMoney(source, moneyType)`
- `Bridge.hasItem(source, itemName, amount)`
- `Bridge.setFuel(vehicle, fuel)`
- `Bridge.giveVehicleKeys(source, plate)`
- `Bridge.register(methodName, handler)`

Client helpers:
- `BridgeClient.getFramework()`
- `BridgeClient.setFuel(vehicle, fuel)`
- `BridgeClient.giveVehicleKeys(plate)`
- `BridgeClient.requestModel(model, timeoutMs)`
- `BridgeClient.setModelAsNoLongerNeeded(model)`
- `BridgeClient.spawnPed(model, coords, heading, networked)`
- `BridgeClient.spawnVehicle(model, coords, heading, networked)`
- `BridgeClient.setEntityAsNoLongerNeeded(entity)`

## Configuration
Override detection if you want to force a framework:

```lua
BridgeConfig = BridgeConfig or {}
BridgeConfig.framework = 'qbcore' -- qbcore | esx | qbox

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
- Detection order is: `qbox`, `qbcore`, `esx`.
- Qbox uses `qbx_core` exports (no framework object).
- If your qbox export names differ, use `Bridge.register` to override.
- This bridge is intended for server-side usage.
