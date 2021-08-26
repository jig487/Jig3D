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
   Z-
]]


--Dimensions of your display. Hardcoded for now bc no way to get size of AR goggles
--If the renders aren't centered to your screen it's because these values are wrong.
local screenAR = {
    x = 270 *0.5, --Replace with x *0.5, where x is your displays width
    y = 270 *0.5  --Replace with y *0.5, where y is your displays height
    --y = x because not messing with aspect ratio right now
}

--Setup monitor and AR controller
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

local objList = {
    c1 = dt.newCube(),
    c2 = dt.newCube(),
    c3 = dt.newCube(),
} 

--Set initial values for location / rotation / scale
objList.c1.loc.z = 3

objList.c2.loc = vector.new(1,-2,3)
objList.c2.scale = vector.new(0.5,0.5,0.5)

objList.c3.loc = vector.new(-1,-1,3)
objList.c3.scale = vector.new(0.5,2,0.5)
objList.c3.rot.z = 45

local rotVec = vector.new(1,1,1) --Will later be added each frame to c1's rotation vector to make it rotate

--Main render loop
local frames = 0
local sTime = os.time()

--You know that cool bug in windows where something breaks and you can draw on the screen with a window by moving it around? https://i.stack.imgur.com/HfZbV.png
--Using that "feature" to make flickering less noticeable when drawing frames at high fps
--local windowsError = 0

for i = 1, 1000 do
    frames = frames + 1
    local projected = {}

    objList.c1.rot = objList.c1.rot:add(rotVec) --Animating the cube by rotating it with rotVec
    objList.c1.loc.y = (math.sin(os.time()/0.02))*0.5
    objList.c1.loc.x = (math.cos(os.time()/0.02))*0.5

    objList.c2.loc.y = (math.cos(os.time()/0.02))*0.5 -1
    objList.c2.loc.x = (math.sin(os.time()/0.02))*0.5 
    objList.c2.rot.z = objList.c2.rot.z + 2

    objList.c3.rot.x = (math.cos(os.time()/0.02))*15

    --Transform everything in objList
    for name,objectData in pairs(objList) do
        projected[name] = dt.screenTransform(objectData,screenAR)
    end
    
    --os.queueEvent("FakeEvent") --Fake event to prevent `too long without yielding` error
	--os.pullEvent("FakeEvent")
    sleep(0.08)

    --windowsError = windowsError + 1
    --if windowsError >= 5 then
        ar.clear()
    --  windowsError = 0
    --end
    
    --Render everything in objList with transformed points
    for name,transformedVertices in pairs(projected) do
        --Change these to just grab all the data for [name] instead of just indexList / colorList?
        draw.drawSolidObj(ar,objList[name].indexList,transformedVertices,objList[name].colorList)
        --draw.drawWireObj(ar,objList[name].indexList,transformedVertices,objList[name].colorList)
    end
end
local eTime = os.time()

--Prevent freezing when time goes from 23:99 or whatever tick to 00:00
if eTime < sTime then eTime = eTime + sTime end 

--Display fps info
local tTime = (eTime-sTime)/0.02
local totalP = 0
for name,ind in pairs(objList) do
    totalP = totalP + #objList[name].indexList
end

print("Finished scene with "..(totalP/3).." total polygons")
print("Drew "..frames.." frames in "..tTime.." seconds")
print("Average FPS: "..(frames/tTime))
