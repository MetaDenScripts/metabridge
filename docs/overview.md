# Bridge Overview

This bridge provides a **single, stable API** for **qbcore**, **esx**, and **qbox** so your scripts can call one function and receive the correct framework-specific data without manual branching.

## What It Does
- **Detects** the active framework at runtime.
- **Routes** calls through the right adapter automatically.
- **Normalizes** common player/vehicle operations to the same function names.
- **Lets you override** behavior when your server uses custom resources.

## Detection Order
Detection is done via resource state checks:
1. `qbox` (`qbx_core`)
2. `qbcore` (`qb-core`)
3. `esx` (`es_extended`)

If you want to force a framework, set `BridgeConfig.framework`.

## File Layout (Why Each File Exists)
- `bridge/bridge.lua`: server dispatcher (`Bridge.call`) + server helpers.
- `bridge/client.lua`: client helpers (`BridgeClient.*`) for fuel/keys.
- `bridge/shared.lua`: detection helpers and shared utilities.
- `bridge/adapters/*.lua`: framework-specific logic mapped to the same API.

## Typical Flow
1. Your script calls `Bridge.getIdentifier(source)`.
2. The bridge determines the framework.
3. The correct adapter runs (qbcore/esx/qbox).
4. The identifier is returned in the same format, regardless of framework.

## Quick Start
Server:
```lua
local framework = Bridge.getFramework()
local identifier = Bridge.getIdentifier(source)
local job = Bridge.getJob(source)
```

Client:
```lua
BridgeClient.setFuel(vehicle, 75.0)
BridgeClient.giveVehicleKeys(GetVehicleNumberPlateText(vehicle))
```
