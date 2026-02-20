-- Legacy compatibility shim: canonical implementation lives in links/frameworks/qbcore.lua
local resource = GetCurrentResourceName()
local targetPath = 'links/frameworks/qbcore.lua'
local chunk = LoadResourceFile(resource, targetPath)
if not chunk then return end
local fn, err = load(chunk, ('@@%s/%s'):format(resource, targetPath))
if not fn then error(err) end
fn()
