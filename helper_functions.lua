local helper = {}

local function PrintTable(o)
    if type(o) == "table" then
        local s = "{ "
        for k,v in pairs(o) do
            if type(k) ~= "number" then k = "'" .. k .. "'" end
            s = s .. "[" .. k .. "] = " .. PrintTable(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

function helper.PrintTable(o)
    print(PrintTable(o))
end

function helper.printHello()
    print("Hello from helper")
end

function helper.cleanup()
    enemy_list = {}
    bullet_list = {}
    ply = {
        pos_x = ScrW / 2,
        pos_y = ScrH - 50,
        health = 10,
        ammo = 10
    }
end

return helper