# Client API

Client helpers are intentionally small, and focus on common vehicle actions that are safe to run client-side.

## Helpers
    - Reads the same detection logic as the server.
    - True when a framework is detected.
    - Sets fuel locally; returns `true` when applied.
    - Triggers a server event to grant keys to the player.
 - `BridgeClient.requestModel(model, timeoutMs)` → `boolean`
     - Requests a model and waits until loaded (default timeout 10s).
 - `BridgeClient.setModelAsNoLongerNeeded(model)` → `boolean`
     - Releases a loaded model.
 - `BridgeClient.spawnPed(model, coords, heading, networked)` → `entity|nil`
     - Spawns a ped using the model and releases it afterward.
 - `BridgeClient.spawnVehicle(model, coords, heading, networked)` → `entity|nil`
     - Spawns a vehicle using the model and releases it afterward.
 - `BridgeClient.setEntityAsNoLongerNeeded(entity)` → `boolean`
     - Releases a ped/vehicle entity.

## Fuel Behavior
`BridgeClient.setFuel` tries (in order):
1. `LegacyFuel` export
2. `ps-fuel` export
3. `cdn-fuel` export
4. Native `SetVehicleFuelLevel` fallback

## Keys Behavior
`BridgeClient.giveVehicleKeys` triggers the server event `Bridge:giveVehicleKeys` unless you override it.

## Spawn Example
```lua
local ped = BridgeClient.spawnPed('a_m_m_business_01', vec3(0.0, 0.0, 72.0), 0.0, true)
local vehicle = BridgeClient.spawnVehicle('adder', vec3(5.0, 5.0, 72.0), 90.0, true)

BridgeClient.setEntityAsNoLongerNeeded(ped)
BridgeClient.setEntityAsNoLongerNeeded(vehicle)
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
