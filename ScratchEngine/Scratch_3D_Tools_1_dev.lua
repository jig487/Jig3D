-- 3D tools API

--Math functions

--Multiply a given matrix by every vertice in given verts table
local function multiplyVerts(mat, vert) --m == matrix, v == vertice list
    if #mat ~= 16 then
        error("Matrix must have length of 16 (4x4 matrix)")
    end
    local result = {}
    for i = 1, #vert, 4 do --Iterate through each vertice
        for k = 1, 4 do --Multiply said vertice by the given matrix. result[1 -> 4] are equal to a 4x1 matrix.
            result[i+k-1] = ( mat[k*4-3] * vert[i] ) + ( mat[k*4-2] * vert[i+1] ) + ( mat[k*4-1] * vert[i+2] ) + ( mat[k*4] * vert[i+3] )
        end 
    end
    return result
end
--Special matrix generators

--BUG FIX: add special matrix multiplication function for the makeView function so that it doesn't break
local function makeView(position, rotationEulers)
    return multiply(makeRotation(rotationEulers), makeTranslation(position))
end

local function makeIdentity()
    return 
    {
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1, }
end

local function makePerspective(width, height, n, f, fov) --n = near, f = far
    local aspectRatio = height / width
    fov = math.rad(fov)
    local tFov = math.tan(fov*0.5)
    return
    {
        1/(aspectRatio*tFov), 0, 0, 0,
        0, 1/tFov, 0, 0,
        0, 0, -(f+n) / (f-n), -(2*f*n) / (f-n),
        0, 0, -1, 0 }
end

local function makeRotation(eulers)
    local x = math.rad(eulers.x)
    local y = math.rad(eulers.y)
    local z = math.rad(eulers.z)
 
    local sx = math.sin(x)
    local sy = math.sin(y)
    local sz = math.sin(z)
    
    local cx = math.cos(x)
    local cy = math.cos(y)
    local cz = math.cos(z)
          
    return
    {
        cy * cz, -cy * sz, sy, 0,
        (sx * sy * cz) + (cx * sz), (-sx * sy * sz) + (cx * cz), -sx * cy, 0,
        (-cx * sy * cz) + (sx * sz), (cx * sy * sz) + (sx * cz), cx * cy, 0,
        0, 0, 0, 1, }
end

local function makeTranslation(translation)
    return
    {
        1, 0, 0, translation.x,
        0, 1, 0, translation.y,
        0, 0, 1, translation.z,
        0, 0, 0, 1, }
end

local function makeScale(scale)
    return
    {
        scale.x, 0, 0, 0,
        0, scale.y, 0, 0,
        0, 0, scale.z, 0,
        0, 0, 0, 1 }        
end

local function makeCheapZ(display)
    return {
        1/display.x, 0, 0, 0,
        0, -1/display.y, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1, }
end

--Returns data of default cube
local function newCube()
    local objData = {
        --Matrix values
        scale = vector.new(1,1,1), --Scale of model
        loc = vector.new(0,0,0),   --Location of model
        rot = vector.new(0,0,0),   --Rotation of model
        --define the colors of each triangle in hexidecimal
        colorList = {
            0xBA1F33, 0xCD5D67,
            0xF2A65A, 0xEEC170,

            0x46B1C9, 0x84C0C6,
            0xBFACB5, 0xE5D0CC,

            0xF564A9, 0xFAA4BD,
            0x8CD790, 0xAAFCB8,
        },
        --points to three vertices in vertices list to describe a triangle
        indexList = {
            --1 face, composed of 2 triangles, each defined by 3 points. 
            --These are multiplied by 4 then offset by -3 because it's a 1D table and it's way easier to read if they are kept like this
            1,3,2, 3,4,2, 
            2,4,6, 4,8,6,

            3,7,4, 4,7,8,
            5,6,8, 5,8,7,

            1,5,3, 3,5,7,
            1,2,5, 2,6,5, },
        --Each possible vertice for the indexList to point to
        vertices = { --4x1 matrix structure for each vertex.
            -0.5, -0.5, -0.5, 1,
             0.5, -0.5, -0.5, 1, 
            -0.5,  0.5, -0.5, 1, 
             0.5,  0.5, -0.5, 1, 

            -0.5, -0.5, 0.5, 1,
             0.5, -0.5, 0.5, 1, 
            -0.5,  0.5, 0.5, 1,  
             0.5,  0.5, 0.5, 1, }
        }
    for i,val in ipairs(objData.indexList) do
        objData.indexList[i] = val*4-3
    end
    return objData
end
--Returns data of default square
local function newSqr() --Refer to newCube() for comments
    local objData = { 
        scale = vector.new(1,1,1),
        loc = vector.new(0,0,0),
        rot = vector.new(0,0,0),
        colorList = { 0xE56399, 0x7F96FF, },
        indexList = { 1,3,2, 3,4,2, },
        vertices = {
            -0.5, -0.5, -0.5, 1,
             0.5, -0.5, -0.5, 1, 
            -0.5,  0.5, -0.5, 1, 
             0.5,  0.5, -0.5, 1, } }
    for i,val in ipairs(objData.indexList) do
        objData.indexList[i] = val*4-3
    end
    return objData
end

--Takes in an entire object and returns transformed vertices and a cullFlag list
local function screenTransform(objectData,display)
    local iL = objectData.indexList
    local scale =    makeScale(objectData.scale)
    local rotMat =   makeRotation(objectData.rot)
    local transMat = makeTranslation(objectData.loc)
    --Transforms the entire object
    local result = multiplyVerts(transMat, multiplyVerts(rotMat, multiplyVerts(scale, objectData.vertices)))
    --Getting the cross product of each face to later be used for backface culling
    result.cullFlags = {}
    for i = 1, #iL, 3 do 
        local i1,i2 = i+1, i+2
        local vec1 = vector.new(result[iL[i]], result[iL[i]+1], result[iL[i]+2])
        local vec2 = vector.new(result[iL[i1]], result[iL[i1]+1], result[iL[i1]+2])
        local vec3 = vector.new(result[iL[i2]], result[iL[i2]+1], result[iL[i2]+2])
        --result.cullFlags[i] = ((vec2:sub(vec1)):cross(vec3:sub(vec1)):dot(vec1))
        result.cullFlags[i] = (vec3:cross(vec2)):dot(vec1) --idk one of these. BUG FIX: I've got inverse culling happening. Seeing inside of triangle instead of front.
    end
    --Perspective divide
    for i = 1,#result, 4 do --Divide each vertice by its Z val
        local zInv = 1/result[i+2]
        result[i]   = (result[i]   *zInv +1) * display.x --Transform to screen space
        result[i+1] = (-result[i+1]*zInv +1) * display.y --Transform to screen space
    end
    return result
end


-- expose library functions
return 
{
    screenTransform = screenTransform, 
    newCube = newCube,
    newSqr = newSqr,
    newTri = newTri,
}
