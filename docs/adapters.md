# Adapters

Adapters translate the bridge API into framework-specific calls. Each adapter exposes the same method names so the bridge can dispatch consistently.

## QBCore (`qbcore`)
Resource: `qb-core`

**Player helpers**
- `getPlayer`, `getPlayerData`, `getIdentifier`, `getJob`, `getMoney`, `hasItem`

**Vehicle helpers**
- `setFuel`: tries `LegacyFuel`, `ps-fuel`, `cdn-fuel`
- `giveVehicleKeys`: tries `qb-vehiclekeys` exports (`GiveKeys` or `AddKeys`)

## ESX (`esx`)
Resource: `es_extended`

**Player helpers**
- `getPlayer`, `getPlayerData`, `getIdentifier`, `getJob`, `getMoney`, `hasItem`

**Vehicle helpers**
- `setFuel`: tries `LegacyFuel`, `ps-fuel`, `cdn-fuel`
- `giveVehicleKeys`: tries `esx_vehiclelock` exports (`givePlayerKeys` or `GiveKeys`)

## Qbox (`qbox`)
Resource: `qbx_core`

**Player helpers**
- Uses qbox exports when available (`GetPlayer`, `GetPlayerData`)
- Falls back to player data if an export is missing

**Vehicle helpers**
- `setFuel`: tries `LegacyFuel`, `ps-fuel`, `cdn-fuel`
- `giveVehicleKeys`: tries `qb-vehiclekeys` exports (`GiveKeys` or `AddKeys`)

## Custom Overrides
If your resource names or exports differ, override using:
- `MetaBridge.register(methodName, handler)`
- `BridgeConfig.fuel.set`
- `BridgeConfig.keys.give`
- `BridgeConfig.keysClient.give`
