local T = text
local check = string.find(T, "::pos")
if check then
    -- parse
    local w = parseWaypoint(T)
    system.print(string.format("::pos{%d,%d,%s,%s,%s}\n", w.systemId, w.bodyId, w.latitude, w.longitude, w.altitude))
    system.print(w.systemId .. w.bodyId)
    system.print(atlas[w.systemId][w.bodyId].name[1])
end