local function movePly(value)
    ply.pos_x = ply.pos_x + value
end

local bullet_list = {}
local bullet_index = 0

local function plyShoot()
    local bullet = {
        index = bullet_index,
        speed = -5, -- Goes up
        pos_x = ply.pos_x,
        pos_y = ply.pos_y
    }

    bullet_index = bullet_index + 1
    table.insert(bullet_list, bullet)
end


function love.load()
    love.window.setTitle("Spaceshooter")
    ScrW, ScrH = love.window.getMode()
    newFont = love.graphics.newFont(60)

    math.randomseed(os.time())


    ply = {
        pos_x = ScrW * 0.5,
        pos_y = ScrH * 0.7,
        ammo = 0
    }
end

local on_shoot_delay = false

function love.update(dt)
    print(dt)
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        movePly(5)
    elseif love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        movePly(-5)
    end

    if love.keyboard.isDown("space") and not on_shoot_delay then

        plyShoot()
        on_shoot_delay = true
    end

    for key, bullet in pairs(bullet_list) do
        if bullet.pos_y < -10 then
            table.remove(bullet_list, key)
        end

        bullet.pos_y = bullet.pos_y + bullet.speed
    end
end

function love.draw()
    love.graphics.circle("fill", ply.pos_x, ply.pos_y, 20)

    for key, bullet in pairs(bullet_list) do
        love.graphics.circle("fill", bullet.pos_x, bullet.pos_y, 5)
    end

    love.graphics.setFont(newFont)
    love.graphics.print(ply.ammo or "0", math.floor(ScrW * 0.9), math.floor(ScrH * 0.85))
end