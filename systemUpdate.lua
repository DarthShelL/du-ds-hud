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

-- pack data for screen
data = {
    alt = getTrimmedAltitude(),
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