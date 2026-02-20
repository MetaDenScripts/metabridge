-- Legacy compatibility shim: canonical implementation lives in links/inventories/framework.lua
local resource = GetCurrentResourceName()
local targetPath = 'links/inventories/framework.lua'
local chunk = LoadResourceFile(resource, targetPath)
if not chunk then return end
local fn, err = load(chunk, ('@@%s/%s'):format(resource, targetPath))
if not fn then error(err) end
fn()
