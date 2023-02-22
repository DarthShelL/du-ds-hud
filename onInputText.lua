local T = text
local check = string.find(T, "::pos")
if check then
    -- parse
    waypoint = parseWaypoint(T) or {}
    system.print(string.format("Got WP: ::pos{%d,%d,%s,%s,%s}\n", waypoint.systemId, waypoint.bodyId, waypoint.latitude, waypoint.longitude, waypoint.altitude))
end