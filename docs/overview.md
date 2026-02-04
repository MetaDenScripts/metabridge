# MetaBridge Overview

This bridge provides a **single, stable API** for **qbcore**, **esx**, **qbox**, **ox_core**, and **vrp** so your scripts can call one function and receive the correct framework-specific data without manual branching. It also includes optional inventory and dispatch helpers.

## What It Does
- **Detects** the active framework at runtime.
- **Routes** calls through the right adapter automatically.
- **Normalizes** common player/vehicle operations to the same function names.
- **Lets you override** behavior when your server uses custom resources.
- **Unifies** inventory operations with optional inventory adapters.
- **Sends** dispatch alerts via common dispatch systems.

## Detection Order
Detection is done via resource state checks:
1. `qbox` (`qbx_core`)
2. `qbcore` (`qb-core`)
3. `esx` (`es_extended`)
4. `ox` (`ox_core`)
5. `vrp` (`vRP` / `vrp`)

If you want to force a framework, set `BridgeConfig.framework`.

## File Layout (Why Each File Exists)
- `metabridge/init.lua`: loader for all resource/links/exports files.
- `metabridge/resource/bridge.lua`: server dispatcher (`MetaBridge.call`) + server helpers.
- `metabridge/resource/client.lua`: client helpers (`MetaBridgeClient.*`).
- `metabridge/resource/shared.lua`: detection helpers and shared utilities.
- `metabridge/links/frameworks/*.lua`: framework-specific logic mapped to the same API.
- `metabridge/links/inventories/*.lua`: inventory adapters.
- `metabridge/links/dispatch/*.lua`: dispatch integration.
- `metabridge/exports/*.lua`: auto-export of `MetaBridge` / `MetaBridgeClient` helpers.

## Typical Flow
1. Your script calls `MetaBridge.getIdentifier(source)`.
2. The bridge determines the framework.
3. The correct adapter runs (qbcore/esx/qbox).
4. The identifier is returned in the same format, regardless of framework.

## Quick Start
Add this to your resource shared scripts:

```lua
'@metabridge/init.lua'
```

Server:
```lua
local framework = MetaBridge.getFramework()
local identifier = MetaBridge.getIdentifier(source)
local job = MetaBridge.getJob(source)
```

Client:
```lua
MetaBridgeClient.setFuel(vehicle, 75.0)
MetaBridgeClient.giveVehicleKeys(GetVehicleNumberPlateText(vehicle))
```
