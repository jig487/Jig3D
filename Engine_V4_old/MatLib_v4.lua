cmdArguments = {...}

local outputMode = "ar"
if cmdArguments[1] == "monitor" then
    outputMode = "monitor"
    print("Running in monitor mode")
end

local matrix = require("matrix_lib")
local loader = require("loader")

local ok, err = xpcall(function()
local mon = peripheral.find("monitor")
local ar = peripheral.find("arController")
local pd = peripheral.find("playerDetector")
local oldTerm = term.redirect(mon)     
mon.setTextScale(0.5)
mon.setCursorPos(1,1)
mon.clear() 
term.setCursorPos(1,1)
term.clear() 

--#### Customize these settings ####

local strokeSize = 1 --Default size of the lines drawn.
local colorDefault = 0xD0E0E3  --Default color in hex.
local width = 530 --Adjust these to the resolution of your AR goggles. Guestimate screen width and height / 3. If the renders aren't centered it's because this is wrong.
local height = 300

if outputMode == "monitor" then
    width, height = mon.getSize()
end

--#### Variables ####

local randomColorList = {0xf8b8f9,0xf1f36d,0x449a68,0x9ccaa6,0xffbb57,0x2180ef,0x26f76d,0xd65175,0xc07873}


-- Camera settings

local n = 0.1  --Focal length
local f = 10 --how far camera sees
local fov = 90

local cDot = 0.5*strokeSize
local frame = 0

--#### Some Functions ####

local cameraPosition = vector.new(0, 0, 5)

local projection = matrix.makePerspective(width, height, n, f, fov)
local view = matrix.makeView(cameraPosition, cameraRotation)

local objectList = {}

local function drawLineAR(x1,y1,x2,y2)
    local dx = x2 - x1
    local dy = y2 - y1
    for i = 1, 45 do
        local nextY = y1 + dy * (i / 100)
        local nextX = x1 + dx * (i / 100)
        if nextY > 0 + strokeSize and nextX > 0 + strokeSize then
            ar.fill(nextX - cDot, nextY - cDot, nextX + cDot, nextY + cDot, colorDefault)
        end
    end
end

local function drawLineMon(x1, y1, x2, y2)
    paintutils.drawLine(x1, y1, x2, y2, colors.green)
end

local drawLine = drawLineAR

if outputMode == "monitor" then
    drawLine = drawLineMon
end

-- #### 3D Base Models ####
local cameraVector = {
    {0}, 
    {0}, 
    {1},
}

local cubeIndexList = {
    { 1,3,2 }, --South 1
    { 1,4,2 }, --South 2
    { 5,7,3 }, --West 1
    { 5,3,1 }, --West 2
    { 6,8,7 }, --North 1
    { 6,7,5 }, --N2
    { 2,4,8 }, --E1
    { 2,8,6 }, --E2
    { 3,7,8 }, --Top1
    { 3,8,4 }, --T2
    { 5,1,2 }, --Bottom 1
    { 5,2,6 }, --B2
}  

local cubePointsList = {
    { {-1}, {-1}, {1}, {1} }, --South face, bottom left
    { {1}, {-1}, {1}, {1} }, --Bottom right
    { {-1}, {1}, {1}, {1} }, --Top left
    { {1}, {1}, {1}, {1} }, --Top right

    { {-1}, {-1}, {-1}, {1} }, --North face, facing the south face, bottom left
    { {1}, {-1}, {-1}, {1} },  --Bottom right
    { {-1}, {1}, {-1}, {1} },  --Top left
    { {1}, {1}, {-1}, {1} }  --Top right
}


-- Returns a mesh given a list of vertices and vertex indices, makes defining meshes less painful
local function genMeshFromIndices(vertices, indexList)
    local mesh = { tris = {} }
    for tri, vertex in ipairs(indexList) do
        mesh.tris[tri] = {}
        for j=1, 3 do
            mesh.tris[tri][j] = cubePointsList[cubeIndexList[tri][j]]
        end
    end
    return mesh
end

-- Returns a mesh loaded from an obj file
local function genMeshFromFile(filename)
    local mesh = { tris = {} }
    obj = loader.load(filename)
    for faceID, faceData in ipairs(obj.f) do
        mesh.tris[faceID] = { {}, {}, {} }
        for j=1, 3 do
            -- vertex of the face to add to engine primitive
            local v = obj.v[faceData[j].v]
            mesh.tris[faceID][j] = { {v.x}, {v.y}, {v.z}, {v.w} }
        end
    end
    return mesh
end

-- #### More Functions ####

local function getCrossProduct(triangle) --specifically for calculating culling right now.
    local line1 = {}
    local line2 = {}
    for i = 1, 3 do
        line1[i] = triangle[2][i][1] - triangle[1][i][1]
        line2[i] = triangle[3][i][1] - triangle[1][i][1]
    end
    return { 
        { (line1[2]*line2[3]) - (line1[3]*line2[2]) },
        { (line1[3]*line2[1]) - (line1[1]*line2[3]) }, 
        { (line1[1]*line2[2]) - (line1[2]*line2[1]) }, }
end 

local function getDotProduct(camera,crossProd)  --specifically for calculating culling right now.
    return (camera[1][1]*crossProd[1][1]) + (camera[2][1]*crossProd[2][1]) + (camera[3][1]*crossProd[3][1])
end

-- Takes in an object and returns it's geometry in screen space coordinates after going through MVP
-- This function is somewhat analogous to a vertex shader, however object processing is serial
local function transformToScreen(object)
    -- final project triangles
    local projected = {}

    -- construct local model matrix
    local scaleMat = matrix.makeScale(object.scale)
    local rotMat = matrix.makeRotation(object.rotation)
    local transMat = matrix.makeTranslation(object.translation)

    local modelMat = matrix.multiply(matrix.multiply(transMat, rotMat), scaleMat)
    -- Transform the triangles
    for i = 1, #object.mesh.tris do
        projected[i] = {}

        -- Do all three vertex MVP multiplies in one loop
        for j = 1, 3 do
            
            -- Apply model matrix to polygon
            projected[i][j] = matrix.multiply(modelMat, object.mesh.tris[i][j])
            
            
            -- Apply view matrix

            projected[i][j] = matrix.multiply(view, projected[i][j])

            -- Perspective projection and division

            -- Projection
            projected[i][j] = matrix.multiply(projection, projected[i][j])
            local w = projected[i][j][4][1]

            -- Perspective Division
            for k = 1, 4 do
                projected[i][j][k][1] = projected[i][j][k][1] / w

                -- clip space culling, polygons that never are on screen can get thrown out
                if projected[i][j][k][1] > 1 or projected[i][j][k][1] < -1 then
                    --projected[i][1] = "cull"
                    --break
                end
            end   

            if projected[i][1] ~= "cull" then
                -- Conversion to screen space coordinates (viewport stuff)
                projected[i][j][1][1] = (projected[i][j][1][1] + 1.0) * 0.5 * width
                projected[i][j][2][1] = (-projected[i][j][2][1] + 1.0) * 0.5 * height
            end
            
        end

        -- Cull back facing polygons
        if projected[i][1] ~= "cull" then
            if getDotProduct(cameraVector, getCrossProduct(projected[i])) >= 0 then --Add a cull flag if dotProduct is > 0
                --projected[i][1] = "cull"
                --break -- exit the for loop and don't process the other points, this polygon got culled
            end
        end   

    end
    return projected
end


-- Draws a wireframe of a given mesh
local function drawWireModel(mesh)
    for i, tri in ipairs(mesh) do
        if i == 1000 then
            sleep(0.05)
        elseif tri[1] ~= "cull" then
            drawLine(tri[1][1][1], tri[1][2][1], tri[2][1][1], tri[2][2][1])
            drawLine(tri[2][1][1], tri[2][2][1], tri[3][1][1], tri[3][2][1])
            drawLine(tri[3][1][1], tri[3][2][1], tri[1][1][1], tri[1][2][1])
        end
    end
end

--#### API Stuff ####

local function makeCube(id) --Make a new cube with an id
    objectList[id] = {
        name = "cube",
        mesh = genMeshFromIndices(cubePointsList, cubeIndexList),
        scale = vector.new(1, 1, 1),--Scale
        rotation = vector.new(0, 0, 0),--Rotation
        translation = vector.new(0, 0, 0),--Translation
        color = colorDefault--Color
    }
end


local function drawFlatTopTriangle(vec1,vec2,vec3)

    print(vec1[1][1]..",1, "..vec1[2][1]..", "..vec1[3][1])
    print(vec2[1][1]..",2, "..vec2[2][1]..", "..vec2[3][1])
    print(vec3[1][1]..",3, "..vec3[2][1]..", "..vec3[3][1])
    local m1 = (vec3[1][1] - vec1[1][1]) / (vec3[2][1] - vec1[2][1])
    local m2 = (vec3[1][1] - vec2[1][1]) / (vec3[2][1] - vec2[2][1])

    local yStart = math.ceil(vec1[2][1] - 0.5 )
    local yEnd = math.ceil(vec3[2][1] - 0.5 )

    local color = randomColorList[math.random(1,#randomColorList)]
    for y = yStart, yEnd do
        local px1 = m1 * (y + 0.5 - vec1[2][1]) + vec1[1][1]
        local px2 = m2 * (y + 0.5 - vec2[2][1]) + vec2[1][1]

        local xStart = math.ceil(px1-0.5)
        local xEnd = math.ceil(px2-0.5)
        for x = xStart, xEnd-1 do
            ar.fill(x - 0.5, y - 0.5, x + 0.5, y + 0.5, color)
        end
    end
end

local function drawFlatBottomTriangle(vec1,vec2,vec3)
    print(vec1[1][1]..",1, "..vec1[2][1]..", "..vec1[3][1])
    print(vec2[1][1]..",2, "..vec2[2][1]..", "..vec2[3][1])
    print(vec3[1][1]..",3, "..vec3[2][1]..", "..vec3[3][1])
    local m1 = (vec2[1][1] - vec1[1][1]) / (vec2[2][1] - vec1[2][1]) --Grab run over rise to prevent inf
    local m2 = (vec3[1][1] - vec1[1][1]) / (vec3[2][1] - vec1[2][1])
    local yStart = math.ceil(vec1[2][1] - 0.5 )
    local yEnd = math.ceil(vec2[2][1] - 0.5 )

    local color = randomColorList[math.random(1,#randomColorList)]
    for y = yStart, yEnd do
        local px1 = m1 * (y + 0.5 - vec1[2][1]) + vec1[1][1]
        local px2 = m2 * (y + 0.5 - vec1[2][1]) + vec1[1][1]

        local xStart = math.ceil(px1-0.5)
        local xEnd = math.ceil(px2-0.5)
        for x = xStart, xEnd-1 do
            ar.fill(x - 0.5, y - 0.5, x + 0.5, y + 0.5, color)
        end
    end
end

local function drawSolidTriangle(triangle)
    local pv1 = triangle[1]
    local pv2 = triangle[2]
    local pv3 = triangle[3]
    
    if pv2[2][1] < pv1[2][1] then pv1,pv2 = pv2,pv1 end
    if pv3[2][1] < pv2[2][1] then pv2,pv3 = pv3,pv2 end
    if pv2[2][1] < pv1[2][1] then pv1,pv2 = pv2,pv1 end

    if pv1[2][1] == pv2[2][1] then --Natural flat top
        if pv2[1][1] < pv1[1][1] then pv2,pv1 = pv1,pv2 end
        drawFlatTopTriangle(pv1,pv2,pv3)

    elseif pv2[2][1] == pv3[2][1] then --Natural flat bottom
        if pv3[1][1] < pv2[1][1] then pv2,pv3 = pv3,pv2 end
        drawFlatBottomTriangle(pv1,pv2,pv3)

    else --General Triangle

        local alphaSplit = ( pv2[2][1] - pv1[2][1] ) / ( pv3[3][1] - pv1[1][1] )

        local splitVertex = {}
        for i = 1, 3 do
            splitVertex[i] = {}
            splitVertex[i][1] = pv1[i][1] + ( pv3[i][1] - pv1[i][1] ) * alphaSplit
        end

        if pv2[1][1] < splitVertex[1][1] then --Major right
            drawFlatBottomTriangle(pv1,pv2,splitVertex)
            drawFlatTopTriangle(pv2,splitVertex,pv3)
        else --Major left
            drawFlatBottomTriangle(pv1,splitVertex,pv2)
            drawFlatTopTriangle(splitVertex,pv2,pv3)
        end
    end
end

local function drawSolidModel(id)
    for i = 1, #projected[id] do
        if projected[id][i][1] ~= "cull" then
            drawSolidTriangle( projected[id][i] )
        end
    end
end

local function getPlayerData()
    -- regex to search with
    local re = "%d+%.%d+"
    local raw
    _, raw = commands.data("get entity @r Pos")
    raw = textutils.serialize(raw)

    local pos = {}
    local i = 1

    for w in string.gmatch(raw, re) do
        pos[i] = tonumber(w)
        i = i + 1
    end

    _, raw = commands.data("get entity @r Rotation")
    raw = textutils.serialize(raw)

    local rot = {}
    local i = 1

    for w in string.gmatch(raw, re) do
        rot[i] = tonumber(w)
        i = i + 1
    end

    return pos, rot
end

--== Define objects to draw ==

makeCube("default")
makeCube("bigger")
makeCube("shrek")
local cube1 = objectList["default"]
cube1.translation = { x = 3, y = 1, z = -9}
objectList["bigger"].translation.z = cube1.translation.z
objectList["bigger"].scale.y = 3
local shrek = objectList["shrek"]
shrek.translation = {x=0, y=0, z=-4}
--shrek.mesh = genMeshFromFile("model.obj")
--== Draw loop ==

while true do
    frame = frame + 1
    mon.setCursorPos(1,1)
    print("Frame: "..frame)
    --getData("jig487")

    cube1.rotation.z = cube1.rotation.z + 5
    shrek.rotation.y = shrek.rotation.y + 20

    local playerPos
    local playerRot
    local forward = vector.new(0, 0, -1)

    playerPos, playerRot = getPlayerData()    

    cameraPosition.x = playerPos[1]
    cameraPosition.y = playerPos[2]
    cameraPosition.z = playerPos[3]

    playerRot

    view = matrix.makeView(cameraPosition, forward)

    local results = {}
    for name, object in pairs(objectList) do
        results[name] = transformToScreen(object)
    end

    os.sleep(0.1)
    mon.setBackgroundColor(colors.black)
    mon.clear()
    ar.clear()

    for _,object in pairs(results) do
        drawWireModel(object)
    end
end

end, debug.traceback) if not ok then printError(err) end