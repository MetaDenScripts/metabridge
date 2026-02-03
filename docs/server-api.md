# Server API

All server helpers delegate to the active adapter. The goal is to call one function regardless of framework.

## Framework
- `MetaBridge.getFramework()` → `string|nil`
  - Returns `qbcore`, `esx`, `qbox`, or `nil` if none detected.
- `MetaBridge.isReady()` → `boolean`
  - True when a framework is detected and an adapter is loaded.

## Player Helpers
- `MetaBridge.getPlayer(source)`
  - Returns the native framework player object.
- `MetaBridge.getPlayerData(source)`
  - Returns a normalized data table when available.
- `MetaBridge.getIdentifier(source)`
  - Returns citizen/identifier depending on framework.
- `MetaBridge.getJob(source)`
  - Returns the job table or `nil`.
- `MetaBridge.getMoney(source, moneyType)`
  - `moneyType` defaults to `cash`.
- `MetaBridge.hasItem(source, itemName, amount)`
  - `amount` defaults to `1`.

## Vehicle Helpers
- `MetaBridge.setFuel(vehicle, fuel)`
  - Attempts to call common fuel resources, then returns `false` if none.
- `MetaBridge.giveVehicleKeys(source, plate)`
  - Delegates to key resources or your override.

## Dispatcher
- `MetaBridge.call(methodName, ...)`
  - Calls a method on the active adapter by name.
  - Throws if the adapter does not support the method.

## Custom Overrides
Override any method at runtime (useful for custom frameworks/resources):

```lua
MetaBridge.register('getIdentifier', function(source)
    return 'custom-id'
end)
```

## Events
The bridge exposes a server event for client key requests:

- `MetaBridge:giveVehicleKeys`
  - args: `plate`
  - source: player id (from event)

The handler calls `MetaBridge.giveVehicleKeys(source, plate)` internally.
