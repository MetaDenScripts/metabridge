local function exportAll(tbl)
    for name, fn in pairs(tbl) do
        if type(fn) == 'function' then
            exports(name, fn)
        end
    end
end

exportAll(MetaBridge)
