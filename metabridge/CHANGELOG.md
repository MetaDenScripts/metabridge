## [1.0.4] - 2026-03-03

### Fixed
- `MetaBridge:invokeCallback` server net event now **silently returns** when the requested callback is not registered in the current Lua state, instead of immediately firing a `MetaBridge:callbackResponse` error back to the client. This eliminates a race condition where the `metabridge` resource's own Lua state (which holds no downstream resource callbacks) would respond with `success = false` before the resource that actually owns the callback could respond with the real result. The previous behaviour caused every `requestCallbackAwait` call in resources that embed `metabridge` via `@metabridge/init.lua` (without `ox_lib` in their own `shared_scripts`) to silently receive `nil`.

### Compatibility
- Public exports, events, and method signatures remain unchanged.
- Both resource mode and `@metabridge/init.lua` include mode remain supported.

---

## [1.0.3] - 2026-02-20

### Added
- Server bridge inventory methods:
  - `getItemDefinition(source, itemName)`
  - `removeItemExact(source, itemName, amount, meta, slot)`
  - `registerCreateItemHook(handler, options)`
- Server callbacks for client-side inventory abstractions:
  - `MetaBridge:getItemCount`
  - `MetaBridge:getItemDefinition`
- Client bridge methods:
  - `getItemCount(itemName, meta)`
  - `hasItem(itemName, amount, meta)`
  - `displayMetadata(metadataMap)`
  - `addTargetLocalEntity(entity, options)` — adds target options to a local (non-networked) entity; routes to `ox_target`, `qb-target`, or `qtarget`.
  - `removeTargetLocalEntity(entity)` — removes all target options from a local entity; same fallback chain.
  - `removeTargetModel(models)` — removes model-based targets registered via `addTargetModel`.
  - `alertDialog(data)` — shows a confirm/cancel alert dialog; defaults to `lib.alertDialog`, overridable via `BridgeConfig.alertDialog.client`.
  - `addZoneSphere(data)` — creates a proximity sphere zone; defaults to `lib.zones.sphere`, overridable via `BridgeConfig.zones.sphere`.
  - `addPoint(data)` — creates a proximity tracking point; defaults to `lib.points.new`, overridable via `BridgeConfig.points.new`.
  - `requestModel(model, timeoutMs)` — loads a model hash and waits until ready; returns `boolean`.

### Fixed
- Fixed `requestCallbackAwait` in `resource/client.lua` to preserve all return values from `lib.callback.await` (including multi-return responses).
- Hardened `getJob` resolution for QBCore/Qbox and added fallback extraction from normalized player payloads to reduce unexpected `nil` job results.

### Changed
- Added bridge debug mode support via `BridgeConfig.debug` and runtime diagnostics in shared/core adapter paths.
- Centralized repeated vehicle helper logic (`setFuel`, `giveVehicleKeys`) in `resource/shared.lua` and reused it across framework adapters.
- Converted `adapters/*.lua` and `inventories/*.lua` to shim-only compatibility files that forward-load canonical implementations.
- Removed leftover duplicate/unused helper logic from active framework files during cleanup.
- Extended inventory adapters with item-definition and exact-removal support.
- Updated `ox_inventory` adapter to support bridge-level `createItem` hook registration.
- Enabled downstream resources to stop calling `ox_inventory` directly for item counts, metadata display, and slot-targeted removals.

### Compatibility
- Public exports, events, and method signatures remain unchanged.
- Both resource mode and `@metabridge/init.lua` include mode remain supported.

## [1.0.2] - 2026-02-20

### Changed
- Added shared helper utilities in `resource/shared.lua` for safe export invocation and notification payload normalization.
- Updated runtime bridge code (`resource/client.lua`, `resource/bridge.lua`) to use shared helpers instead of duplicated local implementations.
- Removed duplicate client export declarations from `resource/client.lua`; client export registration now has a single source of truth in `exports/client.lua`.
- Added legacy compatibility forward-load shims in `adapters/*.lua` and `inventories/*.lua` so those paths always execute canonical implementations in `links/frameworks/*.lua` and `links/inventories/*.lua`.

### Compatibility
- Public exports, events, and method signatures remain unchanged.
- Both resource mode and `@metabridge/init.lua` include mode remain supported.

## [1.0.1] - 2026-02-19

### Added
- Server bridge API methods:
  - `canCarryWeight(source, weight)`
  - `getEmptySlot(source)`
  - `getSlotsWithItem(source, itemName, meta)`
  - `setItemMetadata(source, slot, metadata)`
- `ox_inventory` adapter support for the methods above.
- Framework inventory adapter fallback implementations for safer cross-inventory behavior.

### Notes
- These additions are exported through `exports/server.lua` automatically with the rest of `MetaBridge` methods.
- This update fixes missing-method runtime issues in resources that rely on inventory capacity checks, slot scans, and metadata updates.
