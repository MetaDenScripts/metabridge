# MetaBridge API

This document lists all available helpers and their export names. All functions are exported automatically under the same name.

> Example (client): `exports['metabridge']:notify({ type = 'inform', description = 'Hello' })`
>
> Example (server): `exports['metabridge']:getIdentifier(source)`

## Client API (MetaBridgeClient)

### Framework
- `getFramework()` → `string|nil`
  - Returns the detected framework name.
- `isReady()` → `boolean`
  - `true` when a framework is detected.

### Vehicle
- `setFuel(vehicle, fuel)` → `boolean`
  - Sets fuel using supported fuel resources or native fallback.
- `giveVehicleKeys(plate)` → `boolean`
  - Triggers server key grant (unless overridden).

### Spawning
- `spawnPed(model, coords, heading, networked)` → `entity|nil`
  - Spawns a ped and releases the model.
- `spawnVehicle(model, coords, heading, networked)` → `entity|nil`
  - Spawns a vehicle and releases the model.
- `setEntityAsNoLongerNeeded(entity)` → `boolean`
  - Releases a ped/vehicle entity.

### Inventory UI
- `getItemLabel(itemName)` → `string`
  - Returns item label (fallback to item name).
- `getItemImage(itemName)` → `string|nil`
  - Returns item image URI if supported.

### Notifications
- `notify(data)` → `boolean`
  - Shows a notification (ox_lib/qbcore/esx or override).

### Callbacks
- `requestCallback(name, cb, ...)` → `any`
  - Runs a server callback using ox_lib, qbcore, esx, or your override.

### Targeting
- `addTargetModel(models, options)` → `boolean`
  - Registers target models across ox_target/qtarget/qb-target or override.

### Dispatch
- `sendDispatch(data)` → `void`
  - Sends a dispatch alert using configured system.

## Server API (MetaBridge)

### Framework
- `getFramework()` → `string|nil`
- `isReady()` → `boolean`
- `register(methodName, handler)` → `void`
- `call(methodName, ...)` → `any`

### Player
- `getPlayer(source)` → `table|nil`
- `getPlayerData(source)` → `table|nil`
- `getIdentifier(source)` → `string|nil`
- `getJob(source)` → `table|nil`
- `getMoney(source, moneyType)` → `number|nil`

### Inventory
- `hasItem(source, itemName, amount)` → `boolean`
- `getItemData(source, itemName, meta)` → `table|nil`
- `getItemCount(source, itemName, meta)` → `number`
- `addItem(source, itemName, amount, meta)` → `boolean`
- `removeItem(source, itemName, amount, meta)` → `boolean`
- `getItemFromSlot(source, slot)` → `{ name, metadata }|nil`

### Notifications
- `notify(source, data)` → `boolean`

### Vehicle
- `setFuel(vehicle, fuel)` → `boolean`
- `giveVehicleKeys(source, plate)` → `boolean`

## Exports
All functions above are exported automatically using the same name. For example:

```lua
-- client
exports['metabridge']:notify({ type = 'inform', description = 'Hello' })
exports['metabridge']:requestCallback('my:callback', function(result)
  print(result)
end)
exports['metabridge']:addTargetModel(models, options)

-- server
exports['metabridge']:getItemCount(source, 'water')
exports['metabridge']:notify(source, { type = 'error', description = 'Nope' })
```
