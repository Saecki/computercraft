---@class Material
---@field seed string
---@field plant string

local COAL = "minecraft:coal"

local WHEAT       = "minecraft:wheat"
local WHEAT_SEEDS = "minecraft:wheat_seeds"

local MATERIALS = {
    { seed = WHEAT_SEEDS, plant = WHEAT, grown = { key = "age", value = 7 } },
}

local SIZE = { x = 20, y = 20 }

local function forward()
    while not turtle.forward() do
        turtle.attack()
    end
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
    if turtle.getFuelLevel() > 200 then
        return
    end

    local fuelSlot = getItemSlot(COAL)
    if fuelSlot then
        turtle.select(fuelSlot)
        turtle.refuel(5)
        print(string.format("Refueled, fuel level %s/%s", turtle.getFuelLevel(), turtle.getFuelLimit()))
    else
        print(string.format("No fuel, fuel level %s/%s", turtle.getFuelLevel(), turtle.getFuelLimit()))
    end
end

---@return boolean, Material|nil
local function inspectPlant()
    local success, block = turtle.inspectDown()
    if not success then
        return false, nil
    end

    for _,m in ipairs(MATERIALS) do
        if m.plant == block.name then
            local isGrown = block.state[m.grown.key] == m.grown.value
            return isGrown, m
        end
    end

    return false, nil
end

---@param material Material|nil
local function plantSeed(material)
    local seedSlot = nil

    if material then
        getItemSlot(material.seed)
    end

    if not seedSlot then
        for _,m in ipairs(MATERIALS) do
            seedSlot = getItemSlot(m.seed)
            if seedSlot then break end
        end
    end

    if seedSlot then
        turtle.select(seedSlot)
        turtle.placeDown()
    end
end

local function harvest()
    turtle.digDown()
end

local function checkPlant()
    local isGrown, m = inspectPlant()

    if not m then
        plantSeed()
    elseif isGrown then
        harvest()
        plantSeed()
    end
end

local function moveToStart()
    if SIZE.x % 2 == 1 then
        turtle.turnLeft()
        turtle.turnLeft()

        for i = 1, SIZE.y - 1, 1 do
            checkRefuel()
            forward()
        end
    end

    turtle.turnRight()
    for i = 1, SIZE.x - 1, 1 do
        checkRefuel()
        forward()
    end
    turtle.turnRight()
end

local function isSeedSlot(i)
    local details = turtle.getItemDetail(i)
    if not details then
        return false
    end

    for _,m in ipairs(MATERIALS) do
        if m.seed == details.name then
            return true
        end
    end

    return false
end

local function isFuelSlot(i)
    local details = turtle.getItemDetail(i)
    if not details then
        return false
    end

    return COAL == details.name
end

local function manageItems()
    turtle.turnLeft()

    local seedSlots = 0
    for i = 1, 16, 1 do
        if isSeedSlot(i) and seedSlots < 10 then
            seedSlots = seedSlots + 1
        elseif not isFuelSlot(i) then
            turtle.select(i)
            turtle.drop()
        end
    end
    
    turtle.turnLeft()

    local fuelSlot = getItemSlot(COAL) or getEmptySlot()
    local num = 64 - turtle.getItemCount(fuelSlot)
    turtle.select(fuelSlot)
    turtle.suck(num)

    turtle.turnRight()
    turtle.turnRight()
end

local function run()
    checkRefuel()

    while true do
        manageItems()

        for x = 1, SIZE.x, 1 do
            for y = 1, SIZE.y - 1, 1 do
                checkRefuel()
                checkPlant()
                forward()
            end
            checkPlant()

            if x < SIZE.x then
                if x % 2 == 1 then
                    turtle.turnRight()
                    forward()
                    turtle.turnRight()
                else
                    turtle.turnLeft()
                    forward()
                    turtle.turnLeft()
                end
            end
        end

        moveToStart()
    end
end

run()
