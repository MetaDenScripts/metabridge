# Client API

Client helpers are intentionally small, and focus on common vehicle actions that are safe to run client-side.

## Helpers
- `MetaBridgeClient.getFramework()` → `string|nil`
    - Reads the same detection logic as the server.
- `MetaBridgeClient.isReady()` → `boolean`
    - True when a framework is detected.
- `MetaBridgeClient.setFuel(vehicle, fuel)` → `boolean`
    - Sets fuel locally; returns `true` when applied.
- `MetaBridgeClient.giveVehicleKeys(plate)` → `boolean`
    - Triggers a server event to grant keys to the player.
- `MetaBridgeClient.spawnPed(model, coords, heading, networked)` → `entity|nil`
    - Spawns a ped using the model and releases it afterward.
- `MetaBridgeClient.spawnVehicle(model, coords, heading, networked)` → `entity|nil`
    - Spawns a vehicle using the model and releases it afterward.
- `MetaBridgeClient.setEntityAsNoLongerNeeded(entity)` → `boolean`
    - Releases a ped/vehicle entity.

## Fuel Behavior
`MetaBridgeClient.setFuel` tries (in order):
1. `LegacyFuel` export
2. `ps-fuel` export
3. `cdn-fuel` export
4. Native `SetVehicleFuelLevel` fallback

## Keys Behavior
`MetaBridgeClient.giveVehicleKeys` triggers the server event `MetaBridge:giveVehicleKeys` unless you override it.

## Spawn Example
```lua
local ped = MetaBridgeClient.spawnPed('a_m_m_business_01', vec3(0.0, 0.0, 72.0), 0.0, true)
local vehicle = MetaBridgeClient.spawnVehicle('adder', vec3(5.0, 5.0, 72.0), 90.0, true)

MetaBridgeClient.setEntityAsNoLongerNeeded(ped)
MetaBridgeClient.setEntityAsNoLongerNeeded(vehicle)
```

## Client Overrides
Use this if your key system requires client-only logic:

```lua
BridgeConfig = BridgeConfig or {}
BridgeConfig.keysClient = {
        give = function(plate)
                -- custom client keys logic
        end
}
```
