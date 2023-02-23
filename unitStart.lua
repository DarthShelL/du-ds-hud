
-- DS ===============================================================================================================
local pitch_kP = 0.2 --export: Pitch PID koef
local pitch_kI = 0.0001 --export: Pitch PID koef
local pitch_kD = 0.3 --export: Pitch PID koef
local roll_kP = 0.2 --export: Roll PID koef
local roll_kI = 0.0001 --export: Roll PID koef
local roll_kD = 0.3 --export: Roll PID koef

-- collecting engines
collectEngines()

-- VARS
waypoint = {} -- waypoint which you get from lua input

-- PID
pitchPid = Pid.new(system, pitch_kP, pitch_kI, pitch_kD, -1, 1)
rollPid = Pid.new(system, roll_kP, roll_kI, roll_kD, -1, 1)

-- Input reset
pitchInput = 0
rollInput = 0
yawInput = 0
brakeInput = 0

Nav = Navigator.new(system, core, unit)
Nav.axisCommandManager:setupCustomTargetSpeedRanges(axisCommandId.longitudinal, { 2000, 5000, 10000, 20000, 30000 })
Nav.axisCommandManager:setTargetGroundAltitude(4)

screen.setRenderScript([[local json = require('dkjson')
local vec3 = require('cpml/vec3')
local constants = require('cpml/constants')

-- helper functions ---
function getData()
    return json.decode(getInput()) or {}
end

function sendData(data)
    setOutput(json.encode(data))
end

-- Sensor button ------
button = {}
button.__index = button;

function button.new(layer, x, y, width, height)
    local self = setmetatable({}, button)
    self.layer = layer
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.dColor = { 0, 0.9, 0.8, 1 }
    self.pColor = { 1, 0.3, 0.4, 1 }
    self.state = false

    return self
end

function button.inBounds(self, x, y)
    if x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height then
        return true
    end
    return false
end

function button.setState(self, state)
    self.state = state
end

function button.getState(self)
    return self.state
end

function button.toggle(self)
    self.state = not self.state
end

function button.draw(self)
    local color = self.dColor
    if self.state then
        color = self.pColor
    end
    setNextFillColor(self.layer, color[1], color[2], color[3], color[4])
    addBox(self.layer, self.x, self.y, self.width, self.height)
end

-- HUD ----------------
HUD = {}
HUD.__index = HUD;

function HUD.new(layer, layer2, layer3, f_xs, f_s, f_m, b_t, sw, sh)
    local f = setmetatable({}, HUD)
    f.layer = layer
    f.layer2 = layer2
    f.layer3 = layer3
    f.f_xs = f_xs
    f.f_s = f_s
    f.f_m = f_m
    f.b_t = b_t
    f.sw, f.sh = sw, sh
    f.stabBtn = button.new(f.layer3, sw - 100, sh - 100, 50, 50)
    return f
end

function HUD.waypoint(f, wp, lookDeltaY, atmodens)
    if next(wp) ~= nil then
        -- draw waypoint info
        local tx, ty = 10, 10
        local fontHeight = math.floor(f.sh / 40) + 6
        setDefaultFillColor(f.layer3, Shape_Text, 0, 1, 0.7, 1)
        if atmodens < 0.01 then
            setDefaultTextAlign(f.layer3, AlignH_Left, AlignV_Top)
            addText(f.layer3, f.f_s, "--------------- WP DATA ---------------", tx, ty + 1 * fontHeight)
            addText(f.layer3, f.f_xs, "DEST PLANET:", tx, ty + 2 * fontHeight)
            addText(f.layer3, f.f_xs, "DISTANCE:", tx, ty + 3 * fontHeight)
            addText(f.layer3, f.f_s, "------ SPACE FLIGHT DATA ------", tx, ty + 4 * fontHeight)
            addText(f.layer3, f.f_xs, "EST FLIGHT TIME:", tx, ty + 5 * fontHeight)
            addText(f.layer3, f.f_xs, "TIME TO RETRO BURN:", tx, ty + 6 * fontHeight)
            addText(f.layer3, f.f_xs, "TIME TO BURN LEFT:", tx, ty + 7 * fontHeight)

            tx = 235
            setDefaultTextAlign(f.layer3, AlignH_Right, AlignV_Top)
            addText(f.layer3, f.f_xs, wp.planet:upper(), tx, ty + 2 * fontHeight)
            addText(f.layer3, f.f_xs, string.format("%s",wp.dist), tx, ty + 3 * fontHeight)
            addText(f.layer3, f.f_xs, string.format("%s",wp.eft), tx, ty + 5 * fontHeight)
            addText(f.layer3, f.f_xs, string.format("%s",wp.ttrb), tx, ty + 6 * fontHeight)
            addText(f.layer3, f.f_xs, string.format("%s",wp.ttbl), tx, ty + 7 * fontHeight)
        else
            setDefaultTextAlign(f.layer3, AlignH_Left, AlignV_Top)
            addText(f.layer3, f.f_s, "--------------- WP DATA ---------------", tx, ty + 1 * fontHeight)
            addText(f.layer3, f.f_xs, "DEST PLANET:", tx, ty + 2 * fontHeight)
            addText(f.layer3, f.f_xs, "DISTANCE:", tx, ty + 3 * fontHeight)
            addText(f.layer3, f.f_s, "------- ATMO FLIGHT DATA ------", tx, ty + 4 * fontHeight)
            addText(f.layer3, f.f_xs, "SUSTENTATION SPD:", tx, ty + 5 * fontHeight)

            tx = 235
            setDefaultTextAlign(f.layer3, AlignH_Right, AlignV_Top)
            addText(f.layer3, f.f_xs, wp.planet:upper(), tx, ty + 2 * fontHeight)
            addText(f.layer3, f.f_xs, string.format("%s",wp.dist), tx, ty + 3 * fontHeight)
            addText(f.layer3, f.f_xs, string.format("%s",wp.ss), tx, ty + 5 * fontHeight)
        end

        -- draw vector
        wp.v = vec3(wp.v) * 100
        setDefaultStrokeColor(f.layer3, Shape_Line, 0, 1, 0, 1)
        setDefaultStrokeWidth(f.layer3, Shape_Line, 1)
        setDefaultFillColor(f.layer3, Shape_Circle, 0, 1, 0, 1)
        if (wp.v.z < 0) then
            setDefaultStrokeColor(f.layer3, Shape_Line, 1, 0, 0, 1)
            setDefaultFillColor(f.layer3, Shape_Circle, 1, 0, 0, 1)
        end
        addLine(f.layer3, f.sw / 2, f.sh / 2 + lookDeltaY, f.sw / 2 + wp.v.x, f.sh / 2 + lookDeltaY - wp.v.y)
        addCircle(f.layer3, f.sw / 2 + wp.v.x, f.sh / 2 + lookDeltaY - wp.v.y, 4)
    end
end

function HUD.compass(f, heading, atmoDensity)
    if atmoDensity <= 0.001 then
        return
    end
    local sectors = 50
    local deg = 70
    local x = f.sw / 2
    local y = -f.sh
    local r = math.floor(f.sh + f.sh / 10.2)
    local arc = 180 - deg * 2
    local s = arc / sectors
    local rad, x1, x2, y1, y2 = 0, 0, 0, 0

    for i = 1, sectors do
        local dd = deg + (i - 1) * s
        if dd > 360 then
            dd = dd - 360
        end
        rad = dd * constants.deg2rad
        x1 = x + r * math.cos(rad)
        y1 = y + r * math.sin(rad)
        dd = deg + i * s
        if dd > 360 then
            dd = dd - 360
        end
        rad = dd * constants.deg2rad
        x2 = x + r * math.cos(rad)
        y2 = y + r * math.sin(rad)
        setNextStrokeWidth(f.layer2, f.b_t)
        setNextStrokeColor(f.layer2, 0, 0.9, 0.8, 1)
        addLine(f.layer2, x1, y1, x2, y2)
    end

    local dec = math.floor(math.floor(heading) / 10) * 10 --десятки
    local dif = heading - dec
    local start = deg - arc / 2
    for i = 1, 5 do
        local val = start + dec - i * 10 - 10
        if val < 0 then
            val = 360 + val
        end
        if val > 360 then
            val = val - 360
        end
        local d = start + dif + i * 10
        rad = d * constants.deg2rad
        x1 = x + (r - 30) * math.cos(rad)
        y1 = y + (r - 30) * math.sin(rad)
        x2 = x + (r - 10) * math.cos(rad)
        y2 = y + (r - 10) * math.sin(rad)
        x3 = x + (r) * math.cos(rad)
        y3 = y + (r) * math.sin(rad)
        if d > deg + 4 and d < deg + arc - 4 then
            setNextStrokeColor(f.layer2, 0, 0.9, 0.8, 1)
            setNextStrokeWidth(f.layer2, f.b_t)
            addLine(f.layer2, x2, y2, x3, y3)
            setNextFillColor(f.layer2, 0, 0.9, 0.8, 1)
            if val == 360 or val == 0 then
                addText(f.layer2, f.f_m, "N", x1, y1)
            elseif val == 90 then
                addText(f.layer2, f.f_m, "E", x1, y1)
            elseif val == 180 then
                addText(f.layer2, f.f_m, "S", x1, y1)
            elseif val == 270 then
                addText(f.layer2, f.f_m, "W", x1, y1)
            else
                setNextTextAlign(f.layer2, AlignH_Center, AlignV_Middle)
                addText(f.layer2, f.f_s, string.format("%.0f", val), x1, y1)
            end
        end
    end

    local x40 = math.floor(f.sw / 25.6)
    local x14 = math.floor(f.sw / 73.1)
    local y50 = math.floor(f.sh / 12.26)
    local y35 = math.floor(f.sh / 17.5)
    local y20 = math.floor(f.sh / 30.65)
    local y17 = math.floor(f.sh / 36)
    local y3 = math.floor(f.sh / 204.3)
    local btt = math.ceil(f.b_t / 3)
    setNextStrokeColor(f.layer2, 0, 0.9, 0.8, 1)
    setNextStrokeWidth(f.layer2, btt)
    addLine(f.layer2, x - x40, y + r + y50, x + x40, y + r + y50)
    setNextStrokeColor(f.layer2, 0, 0.9, 0.8, 1)
    setNextStrokeWidth(f.layer2, btt)
    addLine(f.layer2, x - x40, y + r + y20, x + x40, y + r + y20)
    setNextStrokeColor(f.layer2, 0, 0.9, 0.8, 1)
    setNextStrokeWidth(f.layer2, btt)
    addLine(f.layer2, x - x40, y + r + y20, x - x40, y + r + y50)
    setNextStrokeColor(f.layer2, 0, 0.9, 0.8, 1)
    setNextStrokeWidth(f.layer2, btt)
    addLine(f.layer2, x + x40, y + r + y20, x + x40, y + r + y50)
    setNextTextAlign(f.layer2, AlignH_Center, AlignV_Middle)
    addText(f.layer2, f.f_s, string.format("%.2f", heading), x, y + r + y35)
    setNextFillColor(f.layer2, 0, 0.9, 0.8, 1)
    addTriangle(f.layer2, x, y + r + y3, x - x14, y + r + y17, x + x14, y + r + y17)
end

function HUD.artificialHorizon(f, pitch, roll, lookDeltaY, velocityProjX, velocityProjY, atmoDensity)
    setDefaultStrokeColor(f.layer, Shape_Line, 0, 0.9, 0.8, 1)
    setDefaultStrokeWidth(f.layer, Shape_Line, 1)
    local horizonLineLength = 100
    local rollLineLength = 50
    local pitchDistance = 100
    local shipCircleRadius = 10
    local pitchY = pitchDistance * math.sin(pitch * constants.deg2rad)

    setDefaultStrokeColor(f.layer, Shape_Line, 0, 0.9, 0.8, 1)
    -- ship right wing
    addLine(f.layer, f.sw / 2 + shipCircleRadius, f.sh / 2 + lookDeltaY, f.sw / 2 + rollLineLength, f.sh / 2 + lookDeltaY)
    -- ship left wing
    addLine(f.layer, f.sw / 2 - shipCircleRadius, f.sh / 2 + lookDeltaY, f.sw / 2 - rollLineLength, f.sh / 2 + lookDeltaY)

    setNextFillColor(f.layer, 0, 0.9, 0.8, 1)
    addCircle(layer, f.sw / 2, f.sh / 2 + lookDeltaY, shipCircleRadius)
    setNextFillColor(f.layer, 0, 0, 0, 1)
    addCircle(layer, f.sw / 2, f.sh / 2 + lookDeltaY, shipCircleRadius - 2)
    setNextFillColor(f.layer, 0, 0.9, 0.8, 1)
    local vX = f.sw / 2 + velocityProjX
    local vY = f.sh / 2 + lookDeltaY + velocityProjY
    if vX > f.sw - 100 then
        vX = f.sw - 100
    end
    if vX < 100 then
        vX = 100
    end
    if vY > f.sh - 100 then
        vY = f.sh - 100
    end
    if vY < 100 then
        vY = 100
    end
    addCircle(f.layer, vX, vY, 3)

    if atmoDensity < 0.001 then
        return
    end

    -- horizon =============================================================================
    local decimal = math.floor(pitch / 10) * 10
    local pitchDecimalDelta = pitch - decimal
    local ratio = f.sh * 5 / 180
    local step = 10 -- degree
    local pitchStart = pitch
    local degreeMargin = 20

    for i = 0, 18 do
        local count = pitch - step * 9 + i * step
        local r = count * f.sh / 180

        -- calculate starting point with offset
        local sX = f.sw / 2 + r * math.cos((roll + 90) * constants.deg2rad)
        local sY = (f.sh / 2 + lookDeltaY) + r * math.sin((roll + 90) * constants.deg2rad)

        -- calculate right winged pitch lines
        local x = sX + horizonLineLength * math.cos(roll * constants.deg2rad)
        local y = sY + horizonLineLength * math.sin(roll * constants.deg2rad)
        local tx = sX + (horizonLineLength + degreeMargin) * math.cos(roll * constants.deg2rad)
        local ty = sY + (horizonLineLength + degreeMargin) * math.sin(roll * constants.deg2rad)
        -- calculate left winged pitch lines
        local x2 = sX - horizonLineLength * math.cos(roll * constants.deg2rad)
        local y2 = sY - horizonLineLength * math.sin(roll * constants.deg2rad)
        local tx2 = sX - (horizonLineLength + degreeMargin) * math.cos(roll * constants.deg2rad)
        local ty2 = sY - (horizonLineLength + degreeMargin) * math.sin(roll * constants.deg2rad)

        local val = (count - pitch) * -1

        -- draw
        if math.abs(val) < 8 then
            val = 0
            setDefaultStrokeColor(f.layer, Shape_Line, 0, 0.9, 0.8, 1)
            setDefaultFillColor(f.layer, Shape_Text, 0, 0.9, 0.8, 1)
        else
            setDefaultStrokeColor(f.layer, Shape_Line, 0, 0.9, 0.8, 0.6)
            setDefaultFillColor(f.layer, Shape_Text, 0, 0.9, 0.8, 0.6)
        end
        addLine(f.layer, sX, sY, x, y)
        addLine(f.layer, sX, sY, x2, y2)

        -- calculating degree number position
        setDefaultTextAlign(f.layer, AlignH_Center, AlignV_Middle)
        addText(f.layer, f.f_s, string.format("%.0f", val), tx, ty)
        addText(f.layer, f.f_s, string.format("%.0f", val), tx2, ty2)
    end

    -- hide what we don't want to see
    setNextFillColor(f.layer2, 0, 0, 0, 1)
    local hideBoxHeight = math.floor(f.sh / 5.3)
    local hideBoxWidth = math.floor(f.sw / 5)
    addBox(f.layer2, 0, 0, f.sw, hideBoxHeight)
    setNextFillColor(f.layer2, 0, 0, 0, 1)
    addBox(f.layer2, 0, f.sh - hideBoxHeight, hideBoxWidth, f.sh)
    setNextFillColor(f.layer2, 0, 0, 0, 1)
    addBox(f.layer2, f.sw - hideBoxWidth, f.sh - hideBoxHeight, f.sw, f.sh)
    -- =====================================================================================
end

function HUD.loop(f)
    -- update
    local cx, cy = getCursor()
    local data = getData()

    if f.stabBtn:inBounds(cx, cy) then
        if getCursorReleased() then
            f.stabBtn:toggle()
        end
    end

    -- draw
    f.stabBtn:draw()
    setNextFillColor(f.layer3, 0, 0.9, 0.8, 1)
    setNextTextAlign(f.layer3, AlignH_Right, AlignV_Middle)
    addText(f.layer3, f.f_m, string.format("ALT %.2f", data.alt), f.sw - 50, f.sh - 150)

    local color = { 0, 0.9, 0.8, 1 }
    if f.stabBtn:getState() then
        color = { 1, 0.3, 0.4, 1 }
    end

    -- ATMO
    setNextFillColor(f.layer3, 0, 0.9, 0.8, 1)
    setNextTextAlign(f.layer3, AlignH_Right, AlignV_Middle)
    addText(f.layer3, f.f_m, string.format("ATMO F: %.2f%%", data.aP), f.sw - 50, f.sh - 220)

    -- SPACE
    setNextFillColor(f.layer3, 0, 0.9, 0.8, 1)
    setNextTextAlign(f.layer3, AlignH_Right, AlignV_Middle)
    addText(f.layer3, f.f_m, string.format("SPACE F: %.2f%%", data.sP), f.sw - 50, f.sh - 200)

    setNextFillColor(f.layer3, color[1], color[2], color[3], color[4])
    setNextTextAlign(f.layer3, AlignH_Right, AlignV_Middle)
    addText(f.layer3, f.f_m, "STAB", f.sw - 50, f.sh - 120)

    f:compass(data.cmp, data.aD)
    f:artificialHorizon(data.pitch, data.roll, -60, data.vPX, data.vPY, data.aD)
    f:waypoint(data.wp, -60, data.aD)

    -- prepare data for unit
    data = {}
    if f.stabBtn:getState() then
        data.stab = 1
    else
        data.stab = 0
    end
    sendData(data)
end

layer = createLayer()
layer2 = createLayer()
layer3 = createLayer()
sw, sh = getResolution()
baseFontSize = math.floor(sh / 40)
baseThick = math.floor(sh / 204.3)
font_xs = loadFont("RobotoMono-Bold", baseFontSize)
font_s = loadFont("RobotoCondensed", baseFontSize + 4)
font_m = loadFont("RobotoMono-Bold", baseFontSize + 6)

if not init then
    init = true
    hud = HUD.new(layer, layer2, layer3, font_xs, font_s, font_m, baseThick, sw, sh)
end

-- main loop
hud:loop()

requestAnimationFrame(1)]])