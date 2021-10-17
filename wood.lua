---@class Material
---@field dirt string
---@field log string
---@field sapling string
---@field leaves string

---@class V3
---@field x integer
---@field y integer
---@field z integer

local COAL = "minecraft:coal"

local DIRT    = "minecraft:dirt"
local LOG     = "minecraft:log"
local SAPLING = "minecraft:sapling"
local LEAVES  = "minecraft:leaves"

local SLIME_SAPLING   = "tconstruct:slime_sapling"
local SLIME_CONGEALED = "tconstruct:slime_congealed"
local SLIME_DIRT      = "tconstruct:slime_dirt"
local SLIME_LEAVES    = "tconstruct:slime_leaves"

local MATERIALS = {
    { dirt = DIRT,       log = LOG,             sapling = SAPLING      , leaves = LEAVES       },
    { dirt = SLIME_DIRT, log = SLIME_CONGEALED, sapling = SLIME_SAPLING, leaves = SLIME_LEAVES },
}

local DIRECTION = {
    DOWN    = 0,
    FORWARD = 1,
    UP      = 2,
}

local TREE_DISTANCE = { x = 2, y = 2 }
local MATRIX = { x = 8, y = 14 }

local OUTPUT_CHEST  = { x = 2,  y = -2, z = -1 }
local SAPLING_CHEST = { x = 0,  y = -2, z = -1 }
local FUEL_CHEST    = { x = -2, y = -2, z = -1 }

local running = true
local pos = { x = 1, y = 1 }

---@param dist integer
local function moveZ(dist)
    if dist < 0 then
        for i = 1, math.abs(dist), 1 do
            turtle.down()
        end
    elseif dist > 0 then
        for i = 1, math.abs(dist), 1 do
            turtle.up()
        end
    end
end

---@param dist integer
local function moveY(dist)
    if dist < 0 then
        for i = 1, math.abs(dist), 1 do
            turtle.back()
        end
    elseif dist > 0 then
        for i = 1, math.abs(dist), 1 do
            turtle.forward()
        end
    end
end

---@param dist integer
local function moveX(dist)
    turtle.turnRight()
    if dist < 0 then
        for i = 1, math.abs(dist), 1 do
            turtle.back()
        end
    elseif dist > 0 then
        for i = 1, math.abs(dist), 1 do
            turtle.forward()
        end
    end
    turtle.turnLeft()
end

---@param vec V3
local function moveVec(vec)
    moveX(vec.x)
    moveY(vec.y)
    moveZ(vec.z)
end

---@param a V3
---@param b V3
---@return V3
local function vecSub(a, b)
    return {
        x = a.x - b.x,
        y = a.y - b.y,
        z = a.z - b.z,
    }
end

---@param vec V3
---@return V3
local function vecInv(vec)
    return vecSub({x=0,y=0,z=0}, vec)
end

local function getItemSlot(name)
    for i = 1, 16, 1 do
        local details = turtle.getItemDetail(i)
        if details and details.name == name then
            return i
        end
    end

    return nil
end

local function getEmptySlot()
    for i = 1, 16, 1 do
        if not turtle.getItemDetail(i) then
            return i
        end
    end

    return nil
end

local function checkRefuel()
    if turtle.getFuelLevel() >= 200 then
        return
    end

    local coalSlot = getItemSlot(COAL)
    local logSlot = getItemSlot(LOG)

    local fuelSlot = coalSlot or logSlot
    if fuelSlot then
        turtle.select(fuelSlot)
        turtle.refuel(5)
        print(string.format("Refueled, fuel level %s/%s", turtle.getFuelLevel(), turtle.getFuelLimit()))
    else
        print(string.format("No fuel, fuel level %s/%s", turtle.getFuelLevel(), turtle.getFuelLimit()))
    end
end

---@param material Material
local function chopTree(material)
    turtle.dig()
    turtle.forward()

    local distance_moved = 0

    while true do
        local success, block = turtle.inspectUp()
        local isLeaves = false
        if success then
            for _,m in ipairs(MATERIALS) do
                if block.name == m.leaves then
                    isLeaves = true
                    break
                end
            end
        end

        if success and (block.name == material.log or isLeaves) then
            turtle.digUp()
            turtle.up()
            distance_moved = distance_moved + 1
        else
            break
        end
    end

    for i = 1, distance_moved, 1 do
        while not turtle.down() do
            turtle.digDown()
        end
    end

    turtle.back()
end

---@param sapling string
local function placeSapling(sapling)
    local saplingSlot = getItemSlot(sapling)
    if saplingSlot then
        turtle.select(saplingSlot)
        turtle.place()
    end
end

---@return boolean, Material|nil
local function checkLog()
    local success, block = turtle.inspect()
    if not success then
        return false, nil
    end

    for _,m in ipairs(MATERIALS) do
        if m.log == block.name then
            return true, m
        elseif m.sapling == block.name then
            return false, m
        end
    end

    return false, nil
end

---@return Material|nil
local function checkDirt()
    local wentForward = turtle.forward()

    local material = nil

    local success, block = turtle.inspectDown()
    if success then
        for _,m in ipairs(MATERIALS) do
            if m.dirt == block.name then
                material = m
                break
            end
        end
    end

    if wentForward then
        turtle.back()
    end

    return material
end

local function checkTree()
    local isLog, material = checkLog()

    if not material then
        material = checkDirt()

        if material then
            placeSapling(material.sapling)
        end
    elseif isLog then
        chopTree(material)
        placeSapling(material.sapling)
    end
end

local function moveAroundTree(right)
    if right then
        turtle.turnRight()
        turtle.forward()
        turtle.turnLeft()
        turtle.forward()
        turtle.forward()
        turtle.turnLeft()
        turtle.forward()
        turtle.turnRight()
    else
        turtle.turnLeft()
        turtle.forward()
        turtle.turnRight()
        turtle.forward()
        turtle.forward()
        turtle.turnRight()
        turtle.forward()
        turtle.turnLeft()
    end
end

local function moveNextRight()
    turtle.turnRight()
    for i = 1, TREE_DISTANCE.x, 1 do
        turtle.forward()
    end
    turtle.turnLeft()

    pos.x = pos.x + 1
end

local function moveNextLeft()
    turtle.turnLeft()
    for i = 1, TREE_DISTANCE.x, 1 do
        turtle.forward()
    end
    turtle.turnRight()

    pos.x = pos.x - 1
end

local function moveNextForward(right)
    moveAroundTree(right)
    for i = 3, TREE_DISTANCE.y, 1 do
        turtle.forward()
    end

    pos.y = pos.y + 1
end

local function moveToStart()
    turtle.turnLeft()
    local distX = (pos.x - 1) * TREE_DISTANCE.x + 1
    for i = 1, distX, 1 do
        turtle.forward()
        checkRefuel()
    end

    turtle.turnLeft()
    local distY = (pos.y - 1) * TREE_DISTANCE.y
    for i = 1, distY, 1 do
        turtle.forward()
        checkRefuel()
    end

    turtle.turnLeft()
    turtle.forward()
    turtle.turnLeft()

    pos.x = 1
    pos.y = 1
end

local function manageItems()
    moveVec(OUTPUT_CHEST)

    for i = 1, 16, 1 do
        local details = turtle.getItemDetail(i)

        if details then
            local isSapling = false
            for _,m in ipairs(MATERIALS) do
                if m.sapling == details.name then
                    isSapling = true
                    break
                end
            end
            
            local isFuel = details.name == COAL

            if not isSapling and not isFuel then
                turtle.select(i)
                turtle.dropDown()
            end
        end
    end

    moveVec(vecSub(SAPLING_CHEST, OUTPUT_CHEST))

    for i = 1, 16, 1 do
        turtle.select(i)
        turtle.suckDown()
    end

    local fuelSlot = getItemSlot(COAL)
    if not fuelSlot then
        fuelSlot = getEmptySlot()
    end
    if not fuelSlot then
        turtle.select(1)
        turtle.dropDown()
        fuelSlot = 1
    end

    moveVec(vecSub(FUEL_CHEST, SAPLING_CHEST))

    local num = 64 - turtle.getItemCount(fuelSlot)
    turtle.select(fuelSlot)
    turtle.suckDown(num)

    moveVec(vecInv(FUEL_CHEST))
end

local function run()
    checkRefuel()
    manageItems()

    while running do
        checkRefuel()
        checkTree()

        if pos.y % 2 == 1 and pos.x < MATRIX.x then
            moveNextRight()
        elseif pos.y % 2 == 0 and pos.x > 1 then
            moveNextLeft()
        elseif pos.y < MATRIX.y then
            moveNextForward(pos.y % 2 == 1)
        else
            moveToStart()
            manageItems()
        end
    end
end

run()
