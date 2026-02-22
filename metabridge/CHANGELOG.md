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
