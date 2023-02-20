local pitch = gyro.getPitch()
local roll = gyro.getRoll()
local atmoDensity = unit.getAtmosphereDensity()

local data = getDataFromScreen(screen)
stab = data.stab or 0
screen.clearScriptOutput()

-- Planet info
local planetId = core.getCurrentPlanetId()
--system.print(string.format("Planet ID: %d\n", planetId))
if planetId == 27 then
    altitudeTrim = 200
elseif planetId == 1 then
    altitudeTrim = 0
elseif planetId == 2 then
    -- Alioth
    altitudeTrim = 200
elseif planetId == 3 then
    -- Thades
    altitudeTrim = 13690
end

if stab > 0 then
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

local vel = vec3.new(construct.getVelocity())

local speed = vel:len() * 3.6
--local burnSpeed = construct.getFrictionBurnSpeed() * 3.6
local burnSpeed = 20

Nav:update()

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

local atmoFuelMaxVolume = atmofueltank[1].getMaxVolume()
local atmoFuelCurrentVolume = 0
for i=1, atmofueltank_size do
    atmoFuelCurrentVolume = atmoFuelCurrentVolume + atmofueltank[i].getItemsVolume()
end
local atmoPercentage = atmoFuelCurrentVolume * 100 / atmoFuelMaxVolume
local spaceFuelMaxVolume = spacefueltank[1].getMaxVolume() * 3
local spaceFuelCurrentVolume = 0
for i=1, spacefueltank_size do
    spaceFuelCurrentVolume = spaceFuelCurrentVolume + spacefueltank[i].getItemsVolume()
end
local spacePercentage = spaceFuelCurrentVolume * 100 / spaceFuelMaxVolume

-- pack data for screen
local altitude = core.getAltitude() - altitudeTrim
data = {
    altitude = altitude,
    pitch = pitch,
    roll = roll,
    compass = angle,
    atmoDensity = atmoDensity,
    velocityProjX = vel.x * 1,
    velocityProjY = -vel.z * 1,
    atmoPercentage = atmoPercentage,
    spacePercentage = spacePercentage
}

sendData2Screen(screen, data)