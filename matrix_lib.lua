-- Matrix math library

-- Matrix utilities

local function to_string(m)
    print(#m.." x "..#m[1])
    print("------------")
    for i = 1, #m do
        for j = 1, #m[1] do
            write(m[i][j].." ")
        end
        print()
    end
    print()
end

-- Matrix arithmetic

local function multiply(m1, m2)
    if #m1[1] ~= #m2 then
        error("Columns m1 must match rows m2, m1:".. #m1[1] .. " m2: ".. #m2, 2)
        return nil
    end
    local result = {}
    for i = 1, #m1 do
        result[i] = {}
        for j = 1, #m2[1] do
            local sum = 0
            for k = 1, #m2 do
                sum = sum + (m1[i][k] * m2[k][j])
            end
            result[i][j] = sum
        end
    end
    return result
end


-- Special matrix generators

local function makeIdentity()
    return 
    {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 1 }
    }
end

local function makePerspective(width, height, n, f, fov)
    local aspectRatio = height / width
    fov = math.rad(fov)
    return
    {
        { aspectRatio / math.tan(fov * 0.5), 0, 0, 0 },
        { 0, 1 / (math.tan(fov * 0.5)), 0, 0 },
        { 0, 0, -f / (f - n), - f * n / (f - n) },
        { 0, 0, -1, 0 }
     }
end

-- Transform matrix generators

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
        { cy * cz, -cy * sz, sy, 0 },
        { (sx * sy * cz) + (cx * sz), (-sx * sy * sz) + (cx * cz), -sx * cy, 0 },
        { (-cx * sy * cz) + (sx * sz), (cx * sy * sz) + (sx * cz), cx * cy, 0 },
        { 0, 0, 0, 1 }
    }
end

local function makeTranslation(translation)
    return
    {
        { 1, 0, 0, translation.x },
        { 0, 1, 0, translation.y },
        { 0, 0, 1, translation.z },
        { 0, 0, 0, 1 }
    }
end

local function makeScale(scale)
    return
    {
        { scale.x, 0, 0, 0 },
        { 0, scale.y, 0, 0 },
        { 0, 0, scale.z, 0 },
        { 0, 0, 0, 1 }
    }        
end

-- expose library functions

return 
{
    multiply = multiply, 
    makeIdentity = makeIdentity,
    makePerspective = makePerspective,
    makeRotation = makeRotation,
    makeTranslation = makeTranslation,
    makeScale = makeScale
}