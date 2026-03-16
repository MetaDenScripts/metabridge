# metabridge

Framework, inventory, callback, target/UI, and dispatch bridge for FiveM resources.

`metabridge` gives you one stable API (`MetaBridge` server, `MetaBridgeClient` client) and routes calls to the active framework/inventory/dispatch adapters.

## Architecture

- Core server runtime: `resource/bridge.lua`
- Core client runtime: `resource/client.lua`
- Dispatch client extension: `links/dispatch/client.lua`
- Export surfaces: `exports/server.lua`, `exports/client.lua`
- Global loader: `init.lua`

## Requirements

- `ox_lib` (dependency in `fxmanifest.lua`)
- One supported framework adapter (auto-detected or configured via `BridgeConfig.framework`)
- Optional inventory/dispatch systems (auto-detected or configured)

## Setup

### Style 1: Use exports (recommended)

Add dependency order in your resource manifest, then call bridge exports directly.

```lua
dependency 'metabridge'
```

Server example:

```lua
local Bridge = exports['metabridge']
local framework = Bridge:getFramework()
```

Client example:

```lua
local Bridge = exports['metabridge']
Bridge:notify({ type = 'success', description = 'Bridge ready' })
```

### Style 2: Import globals with `@metabridge/init.lua`

In your manifest:

```lua
shared_scripts {
  '@metabridge/init.lua'
}
```

This exposes globals:

- Server: `MetaBridge`
- Client: `MetaBridgeClient`

Important: `init.lua` force-sets `BridgeConfig.debug = true`.

## Typing Notes

- Signatures use lightweight Lua-friendly hints: `name:type` and `-> returnType`.
- Common scalar aliases used in this README: `source:number`, `itemName:string`, `plate:string`.
- Adapter-specific payloads/results are intentionally typed as `table`, `table|nil`, or `any`.
- `nil` in a return type indicates the method can fail or the adapter may not provide data.

## Server API (`MetaBridge`)

### Core

- `init() -> string|nil`
- `getFramework() -> string|nil`
- `isReady() -> boolean`
- `register(methodName:string, handler:function) -> nil`
- `call(methodName:string, ...) -> any`

### Player / Framework

- `getPlayer(source:number) -> any|nil`
- `getPlayerData(source:number) -> table|nil`
- `getIdentifier(source:number) -> string|nil`
- `getJob(source:number) -> table|nil`
- `getGang(source:number) -> table|nil`
- `getMetadata(source:number, key:string|nil) -> any|nil`
- `getMoney(source:number, moneyType:string|nil) -> number|nil`
- `setPlayerMetadata(source:number, key:string, value:any) -> boolean`
- `addMoney(source:number, moneyType:string|nil, amount:number, reason:string|nil) -> boolean`
- `removeMoney(source:number, moneyType:string|nil, amount:number, reason:string|nil) -> boolean`

### Inventory

- `hasItem(source:number, itemName:string, amount:number|nil) -> boolean`
- `getItemData(source:number, itemName:string, meta:table|nil) -> table|nil`
- `getItemDefinition(source:number, itemName:string) -> table|nil`
- `getItemCount(source:number, itemName:string, meta:table|nil) -> number`
- `getItemFromSlot(source:number, slot:number) -> table|nil`
- `addItem(source:number, itemName:string, amount:number, meta:table|nil) -> boolean`
- `removeItem(source:number, itemName:string, amount:number, meta:table|nil) -> boolean`
- `removeItemExact(source:number, itemName:string, amount:number, meta:table|nil, slot:number|nil) -> boolean`
- `canCarryWeight(source:number, weight:number) -> boolean`
- `getEmptySlot(source:number) -> number|boolean|nil`
- `getSlotsWithItem(source:number, itemName:string, meta:table|nil) -> table`
- `setItemMetadata(source:number, slot:number, metadata:table) -> boolean`
- `registerCreateItemHook(handler:function, options:table|nil) -> boolean`

### Notify / Callback

- `notify(source:number, data:table|string) -> boolean`
- `registerCallback(name:string, handler:function) -> boolean`

### Vehicle

- `setFuel(vehicle:number, fuel:number) -> boolean|nil`
- `giveVehicleKeys(source:number, plate:string) -> boolean|nil`

### Advanced Vehicle Ownership APIs

- `createOwnedVehicle(request:table) -> table|nil`
- `getOwnedVehicle(lookup:table) -> table|nil`
- `spawnOwnedVehicle(request:table) -> any|nil`

## Client API (`MetaBridgeClient`)

### Core / Player

- `getFramework() -> string|nil`
- `isReady() -> boolean`
- `getPlayerData() -> table|nil`
- `getIdentifier() -> string|nil`
- `getJob() -> table|nil`
- `getGang() -> table|nil`
- `getMetadata(key:string|nil) -> any|nil`
- `onPlayerLoaded(handler:function) -> boolean`
- `onPlayerUnloaded(handler:function) -> boolean`
- `onPlayerDataChanged(handler:function) -> boolean`
- `onJobChanged(handler:function) -> boolean`
- `onGangChanged(handler:function) -> boolean`
- `onMetadataChanged(handler:function) -> boolean`

### Vehicle / Entity

- `setFuel(vehicle:number, fuel:number) -> boolean|nil`
- `giveVehicleKeys(plate:string) -> boolean|nil`
- `spawnPed(model:string|number, coords:table, heading:number|nil, networked:boolean|nil) -> number|nil`
- `spawnVehicle(model:string|number, coords:table, heading:number|nil, networked:boolean|nil) -> number|nil`
- `setEntityAsNoLongerNeeded(entity:number) -> boolean`

### Inventory / UI

- `getItemLabel(itemName:string) -> string|nil`
- `getItemImage(itemName:string) -> string|nil`
- `getItemCount(itemName:string, meta:table|nil) -> number`
- `hasItem(itemName:string, amount:number|nil, meta:table|nil) -> boolean`
- `displayMetadata(metadataMap:table) -> nil`
- `notify(data:table|string) -> boolean`
- `progressBar(data:table) -> boolean|nil`
- `registerContext(data:table) -> boolean`
- `showContext(contextId:string) -> boolean`
- `inputDialog(title:string, rows:table) -> table|nil`

### Callbacks

- `requestCallback(name:string, cb:function, ...) -> any`
- `requestCallbackAwait(name:string, ...) -> any`

### Target / Text UI

- `addTargetModel(models:any, options:table) -> boolean`
- `addTargetBoxZone(data:table) -> any`
- `addTargetSphereZone(data:table) -> any`
- `removeTargetZone(zoneId:string|number) -> boolean`
- `removeTargetModel(models:any) -> boolean`
- `addTargetLocalEntity(entity:number, options:table) -> boolean`
- `removeTargetLocalEntity(entity:number) -> boolean`
- `showTextUI(text:string) -> boolean`
- `hideTextUI() -> boolean`
- `isTextUIOpen() -> boolean`

### Dialogs / Zones / Points

- `alertDialog(data:table) -> string|nil` — confirm/cancel dialog; returns `'confirm'` or `nil`.
- `addZoneSphere(data:table) -> any|nil` — proximity sphere zone; returns the zone object.
- `addPoint(data:table) -> any|nil` — proximity tracking point; returns the point object.
- `requestModel(model:string|number, timeoutMs:number|nil) -> boolean`

All four methods honour `BridgeConfig` overrides so server operators can swap ox_lib for another implementation without touching consumer resources.

### Advanced Dispatch API

- `sendDispatch(data:table) -> any|nil`

## Usage Examples

### Server (exports)

```lua
local Bridge = exports['metabridge']

RegisterCommand('paybonus', function(source)
  if Bridge:hasItem(source, 'id_card', 1) then
    Bridge:notify(source, {
      type = 'success',
      description = 'Bonus paid.'
    })
  else
    Bridge:notify(source, {
      type = 'error',
      description = 'You need an ID card.'
    })
  end
end)
```

### Client (globals via `@metabridge/init.lua`)

```lua
CreateThread(function()
  MetaBridgeClient.onPlayerLoaded(function(payload)
    MetaBridgeClient.showTextUI(('Welcome %s'):format(payload.framework or 'player'))
    Wait(2500)
    MetaBridgeClient.hideTextUI()
  end)
end)
```

### Advanced server owned vehicle flow

```lua
local Bridge = exports['metabridge']

local created = Bridge:createOwnedVehicle({
  source = source,
  model = 'sultan',
  plate = 'META123'
})

local owned = Bridge:getOwnedVehicle({ plate = 'META123' })
if owned then
  Bridge:spawnOwnedVehicle({
    source = source,
    plate = 'META123',
    coords = vec4(215.0, -810.0, 30.0, 70.0)
  })
end
```

### Advanced client dispatch flow

```lua
local Bridge = exports['metabridge']

Bridge:sendDispatch({
  code = '10-31',
  message = 'Store robbery in progress',
  description = 'Silent alarm triggered',
  jobs = { 'police' },
  coords = GetEntityCoords(PlayerPedId()),
  blip = {
    sprite = 161,
    color = 1,
    scale = 1.0,
    flash = true,
    text = 'Robbery Alert',
    duration = 120000
  }
})
```

## Notes

- Server exports are auto-published from the `MetaBridge` table.
- Client exports are wrapped from `MetaBridgeClient` after dispatch is loaded, so `sendDispatch` is export-available.
- If using globals via `@metabridge/init.lua`, expect debug mode to be forced on.
