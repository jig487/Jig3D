--[[
0,0 -------------------- screen width, 0
|                        |
|                        |
|                        |
|                        |
|                        |
0, screen height ------- Screen width, screen height

3D coordinate plane: Left handed

Y+
|
|
|________ x+
\
 \
  \
   Z+
]]


--Dimensions of your display. Hardcoded for now bc no way to get size of AR goggles
--If the renders aren't centered to your screen it's because these values are wrong.
local screenAR = {
    x = 270 *0.5, --Replace with x *0.5, where x is your displays width
    y = 270 *0.5  --Replace with y *0.5, where y is your displays height
    --y = x because not messing with aspect ratio right now
}

--Connect to monitor, AR controller, and redirect terminal to monitor
local mon = peripheral.find("monitor")
local ar = peripheral.find("arController")
local oldTerm = term.redirect(mon)     
mon.setTextScale(0.5)
mon.setCursorPos(1,1)
mon.clear() 
term.setCursorPos(1,1)
term.clear()
ar.clear()

--Get API's
local dt = require("jig3D")
local draw = require("jigAR")

--Prepare camera and 3d objects to render
local cam = dt.makeCam()

local objList = {
    cube1 = dt.newCube(),
} 

objList.cube1.loc.z = 5
cam.loc.z = 1

--Main render loop

local frames = 0

local sTime = os.time()

for i = 1, 1000 do
    local projected = {}

    --objList.cube1.rot.x = objList.cube1.rot.x + 2
    objList.cube1.rot.y = objList.cube1.rot.y + 2
    --objList.cube1.rot.z = objList.cube1.rot.z + 2

    --Transform everything in objList
    for name,objectData in pairs(objList) do
        projected[name] = dt.screenTransform(objectData,screenAR,cam)
    end
    
    --os.queueEvent("FakeEvent") --Fake event to prevent `too long without yielding` error
	--os.pullEvent("FakeEvent")
    sleep(0.1)

    frames = frames + 1

    ar.clear()
    
    --Render everything in objList with transformed points
    for name,transformedVertices in pairs(projected) do
        --Change these to just grab all the data for [name] instead of just indexList / colorList?
        draw.drawSolidObj(ar,objList[name].indexList,transformedVertices,objList[name].colorList)
        draw.drawWireObj(ar,objList[name].indexList,transformedVertices,objList[name].colorList)
    end
end

local eTime = os.time()
local tTime = (eTime-sTime)/0.02

if eTime < sTime then eTime = eTime + sTime end

local totalP = 0
for name,ind in pairs(objList) do
    totalP = totalP + #objList[name].indexList
end

print("Finished scene with "..(totalP/3).." total polygons")
print("Drew "..frames.." frames in "..tTime.." seconds")
print("Average FPS: "..(frames/tTime))