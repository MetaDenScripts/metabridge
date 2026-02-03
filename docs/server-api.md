# Server API

All server helpers delegate to the active adapter. The goal is to call one function regardless of framework.

## Framework
- `Bridge.getFramework()` → `string|nil`
  - Returns `qbcore`, `esx`, `qbox`, or `nil` if none detected.
- `Bridge.isReady()` → `boolean`
  - True when a framework is detected and an adapter is loaded.

## Player Helpers
- `Bridge.getPlayer(source)`
  - Returns the native framework player object.
- `Bridge.getPlayerData(source)`
  - Returns a normalized data table when available.
- `Bridge.getIdentifier(source)`
  - Returns citizen/identifier depending on framework.
- `Bridge.getJob(source)`
  - Returns the job table or `nil`.
- `Bridge.getMoney(source, moneyType)`
  - `moneyType` defaults to `cash`.
- `Bridge.hasItem(source, itemName, amount)`
  - `amount` defaults to `1`.

## Vehicle Helpers
- `Bridge.setFuel(vehicle, fuel)`
  - Attempts to call common fuel resources, then returns `false` if none.
- `Bridge.giveVehicleKeys(source, plate)`
  - Delegates to key resources or your override.

## Dispatcher
- `Bridge.call(methodName, ...)`
  - Calls a method on the active adapter by name.
  - Throws if the adapter does not support the method.

## Custom Overrides
Override any method at runtime (useful for custom frameworks/resources):

```lua
Bridge.register('getIdentifier', function(source)
    return 'custom-id'
end)
```

## Events
The bridge exposes a server event for client key requests:

- `Bridge:giveVehicleKeys`
  - args: `plate`
  - source: player id (from event)

The handler calls `Bridge.giveVehicleKeys(source, plate)` internally.
