-- AR tools API

--Draws a line from x1,y1 to x2,y2 with given color, using name of wrapped AR controller
local function drawLineAR(arController,x1,y1,x2,y2,color)
    color = 0x000000
    local width = 0.5
    local dx = x2 - x1
    local dy = y2 - y1
    for i = 1, 100 do
        local nextY = y1 + dy * (i / 100)
        local nextX = x1 + dx * (i / 100)
        local border = width*2
        if nextY > border and nextX > border then
            arController.horizontalLine(nextX, nextX, nextY, color)
        end
    end
end
--Basically a line function with cutoffs for anything < 0.
local function drawHLine(arController,x1,x2,y1,color)
    local width = 0.5
    local border = width*2
    if y1 > border and x1 > border then
        arController.horizontalLine(x1, x2, y1, color)
    end
end

--Draws an object with an indexList which points to a list x/y points, using name of wrapped AR controller
local function drawWireObj(arController,iL,vL,cL) --vL == vertice list. cL == color list
    local vList = {}
    for i = 1, #iL, 3 do --Draws a whole triangle per loop
        if not vL.cullFlags[i] then --if not marked for culling then render
            local i1,i2 = i+1, i+2
            local col = cL[(i+2)/3]
            drawLineAR(arController, vL[ iL[i] ],  vL[ iL[i] +1 ],  vL[ iL[i1] ], vL[ iL[i1]+1 ], col) --vert 1 to 2
            drawLineAR(arController, vL[ iL[i1] ], vL[ iL[i1]+1 ],  vL[ iL[i2] ], vL[ iL[i2]+1 ], col) --vert 2 to 3
            drawLineAR(arController, vL[ iL[i2] ], vL[ iL[i2]+1 ],  vL[ iL[i]  ], vL[ iL[i] +1 ], col) --vert 3 to 1
        end
    end
end

local function drawFlatTopTriangle( arController,vec1,vec2,vec3,color )
    --Calculate slopes in screen space
    --Run over rise so we don't get infinite slopes
    local m1 = (vec3.x - vec1.x) / (vec3.y - vec1.y)
    local m2 = (vec3.x - vec2.x) / (vec3.y - vec2.y)

    --Calculate start and end scanlines
    local yStart = math.ceil(vec1.y - 0.5)
    local yEnd =   math.ceil(vec3.y - 0.5) --the scanline AFTER the last line drawn

    for y = yStart, yEnd do
        --calculate start and end x's
        --Add 0.5 because we're calculating based on pixel centers
        local px1 = m1 * (y + 0.5 - vec1.y) + vec1.x
        local px2 = m2 * (y + 0.5 - vec2.y) + vec2.x

        --calculate start and end pixelels
        local xStart = math.ceil(px1 - 0.5)
        local xEnd =   math.ceil(px2 - 0.5) --the pixel after the last pixel drawn
        --if xEnd > 150 then --Prints values and errors when you get the stretched line glitch
        --    print("Flat top error:")
        --    print(textutils.serialize(vec1))
        --    print(textutils.serialize(vec2))
        --    print(textutils.serialize(vec3))
        --    print("m1, m2 = "..m1,m2)
        --    print("px1, px2 = "..px1,px2)
        --    error("xEnd is doing some wack shit, yo. xEnd: "..xEnd)
        --end

        drawHLine( arController,xStart,xEnd,y,color )
    end
end

local function drawFlatBottomTriangle( arController,vec1,vec2,vec3,color )
    --Calculate slopes in screen space
    local m1 = (vec2.x - vec1.x) / (vec2.y - vec1.y)
    local m2 = (vec3.x - vec1.x) / (vec3.y - vec1.y)

    --Calculate start and end scanlines
    local yStart = math.ceil(vec1.y-0.5)
    local yEnd =   math.ceil(vec3.y-0.5) --the scanline AFTER the last line drawn

    for y = yStart, yEnd do

        --calculate start and end points (x coords)
        --Add 0.5 because we're calculating based on pixel centers
        local px1 = m1 * (y + 0.5 - vec1.y) + vec1.x
        local px2 = m2 * (y + 0.5 - vec1.y) + vec1.x

        --calculate start and end pixelsh
        local xStart = math.ceil(px1 - 0.5)
        local xEnd =   math.ceil(px2 - 0.5)
        --if xEnd > 150 then
        --    print("Flat bottom error:")
        --    print(textutils.serialize(vec1))
        --    print(textutils.serialize(vec2))
        --    print(textutils.serialize(vec3))
        --    print("m1, m2 = "..m1,m2)
        --    print("px1, px2 = "..px1,px2)
        --    error("xEnd is doing some wack shit, yo. xEnd: "..xEnd)
        --end
        drawHLine( arController,xStart,xEnd,y,color )
    end
end

--Draws a solid triangle from 3 vectors
local function drawSolidTriangle( arController,vec1,vec2,vec3,color )
    --using pointers so we can swap (for sorting purposes) probably don't need this b/c lua? idk
    local pv1 = vec1
    local pv2 = vec2
    local pv3 = vec3

    --Sort vertices by y
    if pv2.y < pv1.y then pv1,pv2 = pv2,pv1 end
    if pv3.y < pv2.y then pv2,pv3 = pv3,pv2 end
    if pv2.y < pv1.y then pv1,pv2 = pv2,pv1 end

    if pv1.y == pv2.y then --Natural flat top
        --Sort top vertice by x
        if pv2.x < pv1.x then pv1,pv2 = pv2,pv1 end
        drawFlatTopTriangle(arController,pv1,pv2,pv3,color )

    elseif pv2.y == pv3.y then --Natural flat bottom
        --Sort bottom vertice by x
        if pv3.x < pv2.x then pv3,pv2 = pv2,pv3 end
        drawFlatBottomTriangle(arController,pv1,pv2,pv3,color )

    else --General triangle
        local alphaSplit = (pv2.y-pv1.y)/(pv3.y-pv1.y)
        local vi ={ 
            x = pv1.x + ((pv3.x - pv1.x) * alphaSplit),      
            y = pv1.y + ((pv3.y - pv1.y) * alphaSplit), }
        if pv2.x < vi.x then --Major right
            drawFlatBottomTriangle(arController,pv1,pv2,vi,color)
            drawFlatTopTriangle(arController,pv2,vi,pv3,color)
        else --Major left
            drawFlatBottomTriangle(arController,pv1,vi,pv2,color)
            drawFlatTopTriangle(arController,vi,pv2,pv3,color)
        end
    end
end

--Draw an entire object one triangle at a time
--Converts points from the 1D table to vectors b/c I'm lazy
local function drawSolidObj( arController,iL,vL,cL ) --iL == index List. vL == vertex list. cL == color list
    --OPTIMIZATION here?. Probably should convert to 1D at least
    for i = 1, #iL, 3 do --Try to draw a triangle
        if not vL.cullFlags[i] then --If cullFlags[i] is true then render, else cull that polygon
            local i1,i2 = i+1, i+2
            local vec1 = { x= vL[ iL[i]  ], y= vL[ iL[i]+1  ], z= vL[ iL[i]+2  ] } --Target vertex1's x/y and z
            local vec2 = { x= vL[ iL[i1] ], y= vL[ iL[i1]+1 ], z= vL[ iL[i1]+2 ] } --Target vertex2's x/y and z
            local vec3 = { x= vL[ iL[i2] ], y= vL[ iL[i2]+1 ], z= vL[ iL[i2]+2 ] } --Target vertex3's x/y and z
            drawSolidTriangle( arController, vec1, vec2, vec3, cL[(i2)/3] )
        end
    end
end

--Expose functions
return 
{
    drawWireObj = drawWireObj,
    drawSolidObj = drawSolidObj,
}