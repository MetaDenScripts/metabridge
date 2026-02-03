# MetaBridge

A lightweight FiveM bridge to support **qbcore**, **esx**, and **qbox** with a single, simple API.

## Features
- Automatic framework detection
- Single `MetaBridge.call` dispatcher
- Friendly helper methods like `MetaBridge.getIdentifier`
- Optional override via `BridgeConfig.framework`

## Installation
1. Drop this folder into your server resources.
2. Ensure it starts **after** your framework resource.

```
ensure metabridge
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
- `MetaBridge.register(methodName, handler)`

Client helpers:
- `MetaBridgeClient.getFramework()`
- `MetaBridgeClient.setFuel(vehicle, fuel)`
- `MetaBridgeClient.giveVehicleKeys(plate)`
- `MetaBridgeClient.spawnPed(model, coords, heading, networked)`
- `MetaBridgeClient.spawnVehicle(model, coords, heading, networked)`
- `MetaBridgeClient.setEntityAsNoLongerNeeded(entity)`

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
- If your qbox export names differ, use `MetaBridge.register` to override.
- This bridge is intended for server-side usage.
