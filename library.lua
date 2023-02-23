json = require('dkjson')
atlas = require('atlas')
-- CONSTANTS ----------
constants = {}
constants.deg2rad = 0.0174532925199
constants.rad2deg = 57.2957795130
constants.epsilon = 0.000001
constants.m2kph = 3.6
constants.kph2m = 0.27777777777
constants.g = 9.80665

-- HELPER -------------
function clamp(val, min, max)
    if val > max then
        val = max
    elseif val < min then
        val = min
    end
    return val
end

function getSurfaceDirection()
    local F = vec3(construct.getWorldOrientationForward())
    local up = -vec3(core.getWorldVertical())
    local forward = F
    forward = forward - forward:project_on(up)
    local north = vec3(0, 0, 1)
    north = north - north:project_on(up)
    local east = north:cross(up)
    local angle = north:angle_between(forward) * constants.rad2deg
    if forward:dot(east) < 0 then
        angle = math.floor((360 - angle) * 10) / 10
    end
end

function sendData2Screen(screen, data)
    screen.setScriptInput(json.encode(data))
end

function getDataFromScreen(screen)
    data = json.decode(screen.getScriptOutput()) or {}
    screen.clearScriptOutput()
    return data
end

function parseWaypoint(waypoint)
    local n = '*([+-]?%d+%.?%d*e?[+-]?%d*)'
    local pattern = '::pos{' .. n .. ',' .. n .. ',' .. n .. ',' .. n .. ',' .. n .. '}'
    local systemId, bodyId, latitude, longitude, altitude = string.match(waypoint, pattern)
    local w = {
        systemId = tonumber(systemId),
        bodyId = tonumber(bodyId),
        latitude = tonumber(latitude),
        longitude = tonumber(longitude),
        altitude = tonumber(altitude)
    }
    return w
end

function getFuelPercentage(tanks, number_of_tanks)
    local currentVolume = 0
    local maxVolume = tanks[1].getMaxVolume() * number_of_tanks
    for i = 1, number_of_tanks do
        currentVolume = currentVolume + tanks[i].getItemsVolume()
    end
    return currentVolume * 100 / maxVolume
end

function getDeg2north()
    local F = vec3(construct.getWorldOrientationForward())
    local up = -vec3(core.getWorldVertical())
    local forward = F
    forward = forward - forward:project_on(up)
    local north = vec3(0, 0, 1)
    north = north - north:project_on(up)
    local east = north:cross(up)
    local angle = north:angle_between(forward) * constants.rad2deg
    if forward:dot(east) < 0 then
        angle = math.floor((360 - angle) * 10) / 10
    end
    return angle
end

-- returns total thrust, total Isp and total deltaV
function getShipSpaceVars()
    if next(engines) == nil then
        collectEngines()
    end
    local shipMass = getShipTotalMass()
    local dryMass = getSpaceDryMass()
    local thrust = 0
    local isp = 0
    local deltaV = 0
    local e

    if engines.space.extrasmall ~= nil then
        e = engines.space.extrasmall
        local t = e.engine.getMaxThrust()
        local ffr = getFuelFlowRate(e.engine.getFuelConsumption(), 6)
        local i = getIsp(t, ffr)
        thrust = thrust + t * e.number
        isp = isp + i * e.number
        deltaV = deltaV + getDeltaV(shipMass, dryMass, i) * e.number
    end
    if engines.space.small ~= nil then
        e = engines.space.small
        local t = e.engine.getMaxThrust()
        local ffr = getFuelFlowRate(e.engine.getFuelConsumption(), 6)
        local i = getIsp(t, ffr)
        thrust = thrust + t * e.number
        isp = isp + i * e.number
        deltaV = deltaV + getDeltaV(shipMass, dryMass, i) * e.number
    end
    if engines.space.medium ~= nil then
        e = engines.space.medium
        local t = e.engine.getMaxThrust()
        local ffr = getFuelFlowRate(e.engine.getFuelConsumption(), 6)
        local i = getIsp(t, ffr)
        thrust = thrust + t * e.number
        isp = isp + i * e.number
        deltaV = deltaV + getDeltaV(shipMass, dryMass, i) * e.number
    end
    if engines.space.large ~= nil then
        e = engines.space.large
        local t = e.engine.getMaxThrust()
        local ffr = getFuelFlowRate(e.engine.getFuelConsumption(), 6)
        local i = getIsp(t, ffr)
        thrust = thrust + t * e.number
        isp = isp + i * e.number
        deltaV = deltaV + getDeltaV(shipMass, dryMass, i) * e.number
    end
    if engines.space.extralarge ~= nil then
        e = engines.space.extralarge
        local t = e.engine.getMaxThrust()
        local ffr = getFuelFlowRate(e.engine.getFuelConsumption(), 6)
        local i = getIsp(t, ffr)
        thrust = thrust + t * e.number
        isp = isp + i * e.number
        deltaV = deltaV + getDeltaV(shipMass, dryMass, i) * e.number
    end

    return thrust, isp, deltaV
end

function getFuelFlowRate(fuelConsumption, fuelWeight)
    return fuelConsumption * fuelWeight
end

function getIsp(thrust, fuelFlowRate)
    return thrust / (fuelFlowRate * constants.g) * 3600
end

function getExhaustVelocity(Isp)
    return Isp * constants.g
end

function getDeltaV(shipMass, shipDryMass, Isp)
    return Isp * constants.g * math.log(shipMass / shipDryMass)
end

engines = {}
--engines.space = {}
--engines.space.extrasmall = {}
--engines.space.extrasmall.number = 0
--engines.space.small = {}
--engines.space.small.number = 0
--engines.space.medium = {}
--engines.space.medium.number = 0
--engines.space.large = {}
--engines.space.large.number = 0
--engines.space.extralarge = {}
--engines.space.extralarge.number = 0

function collectEngines()
    local elementIdList = core.getElementIdList()
    for i, id in ipairs(elementIdList) do
        local class = core.getElementClassById(id):lower()
        local spacePattern = 'spaceengine([a-z]+)group'
        if (class:find("spaceengine")) then
            local m = string.match(class, spacePattern)
            if (engines.space == nil) then
                engines.space = {}
            end
            if (engines.space[m] == nil) then
                engines.space[m] = {}
            end
            if (engines.space[m].number == nil) then
                engines.space[m].number = 0
            end
            engines.space[m].number = engines.space[m].number + 1
            if engines.space[m].engine == nil then
                engines.space[m].engine = unit["se_" .. m]
            end
        end
    end
end

function wp2world(waypoint)
    local wp = {}
    if next(waypoint) ~= nil then
        if waypoint.bodyId == 0 then
            return vec3(waypoint.latitude, waypoint.longitude, waypoint.altitude)
        end
        local body = atlas[waypoint.systemId][waypoint.bodyId]
        local latitude = constants.deg2rad * clamp(waypoint.latitude, -90, 90)
        local longitude = constants.deg2rad * (waypoint.longitude % 360)
        local xproj = math.cos(latitude)
        wp = vec3(body.center) + (body.radius + waypoint.altitude) * vec3(xproj * math.cos(longitude), xproj * math.sin(longitude), math.sin(latitude))
    end
    return { wp:unpack() }
end

function getDistanceByWP(waypoint)
    local wpPos = vec3(wp2world(waypoint))
    local pos = vec3(construct.getWorldPosition())
    local path = vec3(wpPos - pos)

    return path:len()
end

function getBodyNameFromWP(waypoint)
    if atlas[waypoint.systemId][waypoint.bodyId] ~= nil then
        return atlas[waypoint.systemId][waypoint.bodyId].name[1]
    end

    return "X"
end

function getSpaceFlightTime(waypoint)
    -- get current speed
    local speed = vec3(construct.getAbsoluteVelocity()):len()
    if speed == 0 then
        return 0
    end
    -- get distance
    local distance = getDistanceByWP(waypoint)
    return distance / speed
end

function getShipTotalMass()
    return construct.getMass() + player.getMass()
end

function getSpaceDryMass()
    -- calculate fuel
    local fuel = 0
    for i = 1, spacefueltank_size do
        fuel = fuel + spacefueltank[i].getItemsVolume()
    end
    local fuelMass = fuel * 6 -- kergon weighs 6 kilo
    -- substract from total mass
    return getShipTotalMass() - fuelMass
end

-- time to retro burn and time to burn left
-- dT = (Ml*Ev)/F * (1 - exp(-dV/Ev))
function getTTRB(eft)
    local Ev = vec3(construct.getAbsoluteVelocity()):len()
    local Ml = getShipTotalMass()
    local F, Isp, dV = getShipSpaceVars()
    local safeDistance = 100000 -- 100km
    local safeTime = safeDistance / Ev

    local ttrb = math.ceil((Ml * Ev) / F * (1 - math.exp(-dV / Ev)))
    local ttbl = eft - ttrb - safeTime

    return ttrb, ttbl
end

function getSustentationSpeed()

end

function formatTime(sec)
    if sec > 3600 * 24 or sec < 1 then
        -- we don't need such big or small values
        return 0
    end
    if (sec >= 3600) then
        -- hours :(
        local h = math.floor(sec / 3600)
        local m = 0
        local s = sec % 3600
        if (s >= 60) then
            m = math.floor(s / 60)
            s = math.ceil(s % 60)
        end
        sec = string.format("%02d:%02d:%02d", h, m, s)
    elseif (sec >= 60) then
        -- minutes
        local m = math.floor(sec / 60)
        sec = math.ceil(sec % 60)
        sec = string.format("%02d:%02d", m, sec)
    end

    return sec
end

-- PID ----------------
Pid = {}
Pid.__index = Pid

function Pid.new(system, kp, ki, kd, sMin, sMax)
    local self = setmetatable({}, Pid)
    self.system = system
    self.p = 0
    self.i = 0
    self.d = 0
    self.kp = kp
    self.ki = ki
    self.kd = kd
    self.sMin = sMin
    self.sMax = sMax
    self.prevP = 0
    self.signal = 0
    self.setpoint = 0
    self.lastTime = self.system.getUtcTime()
    return self
end

function Pid.update(f, setPoint, value)
    local time = f.system.getUtcTime()
    local timeDelta = time - f.lastTime
    f.lastTime = time
    f.setpoint = setPoint
    f.p = setPoint - value
    if (f.kd ~= 0) then
        f.d = (f.p - f.prevP) / timeDelta
    else
        f.d = 0
    end
    if (f.ki ~= 0) then
        f.i = f.i + f.p * timeDelta
    else
        f.i = 0
    end
    f.prevP = f.p
    f.signal = f.p * f.kp + f.i * f.ki + f.d * f.kd
    f.signal = clamp(f.signal, f.sMin, f.sMax)
end

function Pid.reset(f)
    f.p = 0
    f.i = 0
    f.d = 0
    f.signal = 0
    f.prevValue = 0
end

function getTrimmedAltitude()
    local planetId = core.getCurrentPlanetId()
    return core.getAltitude() - atlas[0][planetId].surfaceAverageAltitude
end

function stabUpdate(stabToggle, pitch, roll, pitchInput, rollInput, pitchPid, rollPid)
    if stabToggle > 0 then
        if pitchInput ~= 0 then
            pitchPid:reset()
        else
            pitchPid:update(0, pitch)
        end

        if rollInput ~= 0 then
            rollPid:reset()
        else
            rollPid:update(0, -roll)
        end
    else
        pitchPid:reset()
        rollPid:reset()
    end
end