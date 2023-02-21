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

-- calculates time to burn needed to reach to desiredSpeed
function calculateBurnTime(currentVelocity, desiredVelocity, shipMass, deltaV, thrust)

end

function getFuelPercentage(tanks, number_of_tanks)
    local currentVolume = 0
    local maxVolume = tanks[1].getMaxVolume() * number_of_tanks
    for i=1, number_of_tanks do
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

-- PID ----------------
Pid = {}
Pid.__index = Pid;

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