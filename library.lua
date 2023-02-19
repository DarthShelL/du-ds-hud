local json = require('dkjson')
local constants = require('cpml/constants')

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