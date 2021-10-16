---@param prompt string
local function readNumber(prompt)
    print(prompt)
    return tonumber(read())
end

local X = readNumber("x (right): ")
local Y = readNumber("y (forward): ")
local Z = readNumber("z (down): ")

print(string.format("mining %dx%dx%d", Y, X, Z))

local function dig()
    repeat
        turtle.dig()
    until( turtle.forward() )
end

local function digDown()
    repeat
        turtle.digDown()
    until( turtle.down() )
end

local x = 1
local dir = 1

for z = 1, Z, 1 do
    while true do
        for y = 1, Y - 1, 1 do
            dig()
        end

        if dir == 1 and x == X then
            dir = -1
            break
        end
        if dir == -1 and x == 1 then
            dir = 1
            break
        end

        if x % 2 == 1 then
            turtle.turnRight()
            dig()
            turtle.turnRight()
        else 
            turtle.turnLeft()
            dig()
            turtle.turnLeft()
        end

        x = x + dir
    end

    if z < Z then
        turtle.turnLeft()
        turtle.turnLeft()
        digDown()
    end
end
