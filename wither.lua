local COAL = "minecraft:coal"

local SOUL_SAND = "minecraft:soul_sand"
local SKULL = "minecraft:skull"

local DISTANCE = 5

local function getItemSlot(name)
    for i = 1, 16, 1 do
        local detail = turtle.getItemDetail(i)
        if detail and detail.name == name then
            return i
        end
    end

    return nil
end

local function getItemCount(name)
    local count = 0
    for i = 1, 16, 1 do
        local detail = turtle.getItemDetail(i)
        if detail then
            if detail.name == name then
                count = count + detail.count
            end
        end
    end
    return count
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

local function selectItemSlot(name)
    local slot = getItemSlot(name)
    if slot then
        turtle.select(slot)
    end
end

local function placeWither()
    for i = 1, DISTANCE, 1 do
        turtle.forward()
    end

    turtle.forward()
    turtle.forward()
    turtle.down()

    selectItemSlot(SOUL_SAND)
    turtle.placeDown()
    turtle.place()
    turtle.up()
    turtle.placeDown()
    turtle.back()
    turtle.placeDown()
    turtle.forward()

    selectItemSlot(SKULL)
    turtle.place()
    turtle.back()
    turtle.place()
    turtle.back()
    turtle.place()

    for i = 1, DISTANCE, 1 do
        turtle.back()
    end
end

local function getItems()
    turtle.turnLeft()
    for i = 1, 4, 1 do
        if getItemCount(SKULL) >= 4 then break end
        turtle.suck()
    end
    turtle.turnLeft()
    for i = 1, 4, 1 do
        if getItemCount(COAL) >= 16 then break end
        turtle.suck()
    end
    turtle.turnLeft()
    for i = 1, 4, 1 do
        if getItemCount(SOUL_SAND) >= 4 then break end
        turtle.suck()
    end
    turtle.turnLeft()
end

local function checkItems()
    return getItemCount(SOUL_SAND) >= 4 and getItemCount(SKULL) >= 3
end

local function run()
    while true do
        checkRefuel()
        getItems()
        if checkItems() then
            placeWither()
        end
        os.sleep(30)
    end
end

run()
