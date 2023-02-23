local pitch = gyro.getPitch()
local roll = gyro.getRoll()
local atmoDensity = unit.getAtmosphereDensity()

-- collecting data from screen
local data = getDataFromScreen(screen)
local stab = data.stab or 0
screen.clearScriptOutput()
-- ----

stabUpdate(stab, pitch, roll, pitchInput, rollInput, pitchPid, rollPid)

local vel = vec3.new(construct.getVelocity())
--local speed = vel:len() * 3.6
--local burnSpeed = 20

Nav:update()

local w = {}
if next(waypoint) ~= nil then
    local wpPos = vec3(wp2world(waypoint))
    local pos = vec3(construct.getWorldPosition())
    local path = vec3(wpPos - pos)
    local pathNorm = path:normalize()
    local up = vec3(construct.getWorldOrientationUp())
    local right = vec3(construct.getWorldOrientationRight())
    local forward = vec3(construct.getWorldOrientationForward())

    w.v = {
        pathNorm:dot(right),
        pathNorm:dot(up),
        pathNorm:dot(forward)
    }
    w.dist = path:len() / 1000
    if w.dist > 200 then
        w.dist = string.format("%.2f su", w.dist / 200)
    else
        w.dist = string.format("%.2f km", w.dist)
    end

    w.planet = getBodyNameFromWP(waypoint)
    local eft = getSpaceFlightTime(waypoint)
    w.eft = formatTime(eft)
    if atmoDensity > 0.01 then
        w.ttrb = 0
        w.ttbl = 0
    else
        w.ttrb, w.ttbl = getTTRB(eft)
        w.ttrb = formatTime(w.ttrb)
        w.ttbl = formatTime(w.ttbl)
    end
    --#TODO: getSustentationSpeed()
    w.ss = 300 --getSustentationSpeed()
end

local alt = 0
if (atmoDensity > 0.01) then
    alt = getTrimmedAltitude()
end

-- pack data for screen
data = {
    wp = w,
    alt = alt,
    pitch = pitch,
    roll = roll,
    cmp = getDeg2north(),
    aD = atmoDensity,
    vPX = vel.x * 1,
    vPY = -vel.z * 1,
    aP = getFuelPercentage(atmofueltank, atmofueltank_size),
    sP = getFuelPercentage(spacefueltank, spacefueltank_size)
}
sendData2Screen(screen, data)