metabridge
==========

Summary
- Framework and inventory bridge for FiveM resources.
- Exposes a stable server/client export API while delegating to configured adapters.

Requirements
- `ox_lib` (declared dependency in `fxmanifest.lua`).
- At least one supported framework adapter in `links/frameworks`.
- Optional inventory adapter in `links/inventories` (falls back to `framework` inventory adapter).

Setup
- Ensure resource is started before resources that use it.
- Configure `BridgeConfig` in `init.lua` as needed:
  - `framework`
  - `inventory`
  - `debug` (set to `true` to log bridge resolution and adapter call diagnostics)
  - optional custom handlers for notify, callbacks, target, etc.

Server API Reference
--------------------

Core
- `init()` → resolves framework adapter and initializes bridge.
- `getFramework()` → returns active framework key.
- `isReady()` → returns `true` if active framework adapter is ready.
- `register(methodName, handler)` → registers override handler.
- `call(methodName, ...)` → calls active adapter method.

Player / Framework
- `getPlayer(source)`
- `getPlayerData(source)`
- `getIdentifier(source)`
- `getJob(source)`
- `getMoney(source, moneyType)`

Inventory
- `hasItem(source, itemName, amount)`
- `getItemData(source, itemName, meta)`
- `getItemCount(source, itemName, meta)`
- `getItemFromSlot(source, slot)`
- `addItem(source, itemName, amount, meta)`
- `removeItem(source, itemName, amount, meta)`
- `canCarryWeight(source, weight)`
- `getEmptySlot(source)`
- `getSlotsWithItem(source, itemName, meta)`
- `setItemMetadata(source, slot, metadata)`

Notify / Callback
- `notify(source, data)`
- `registerCallback(name, handler)`

Vehicle
- `setFuel(vehicle, fuel)`
- `giveVehicleKeys(source, plate)`

Client API Reference
--------------------

General
- `getFramework()`
- `isReady()`

Vehicle / Entity
- `setFuel(vehicle, fuel)`
- `giveVehicleKeys(plate)`
- `spawnPed(model, coords, heading, networked)`
- `spawnVehicle(model, coords, heading, networked)`
- `setEntityAsNoLongerNeeded(entity)`

Item / UI
- `getItemLabel(itemName)`
- `getItemImage(itemName)`
- `notify(data)`
- `progressBar(data)`
- `registerContext(data)`
- `showContext(contextId)`
- `inputDialog(title, rows)`

Callbacks
- `requestCallback(name, cb, ...)`
- `requestCallbackAwait(name, ...)`

Target / TextUI
- `addTargetModel(models, options)`
- `addTargetBoxZone(data)`
- `addTargetSphereZone(data)`
- `removeTargetZone(zoneId)`
- `showTextUI(text, options)`
- `hideTextUI()`
- `isTextUIOpen()`

Notes
- All server exports are auto-published from `MetaBridge` in `exports/server.lua`.
- All client exports are wrapped in `exports/client.lua`.
- Adapter capability varies by framework/inventory; methods return safe defaults where adapters do not implement a feature.
- Canonical framework adapters live in `links/frameworks/*.lua`.
- Canonical inventory adapters live in `links/inventories/*.lua`.
- `adapters/*.lua` and `inventories/*.lua` are shim-only compatibility files and should not contain runtime logic.
- New adapter or inventory logic should only be implemented in `links/frameworks/*.lua` and `links/inventories/*.lua`.
