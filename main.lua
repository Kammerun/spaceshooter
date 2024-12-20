local helper = require("helper_functions")

local pointCount = 0

local function setupPly()
    ply = {
        pos_x = ScrW * 0.5,
        pos_y = ScrH * 0.85,
        ammo = 10,
        health = 1
    }
end

local function movePly(value)
    if not (ply.pos_x + value < 20 or ply.pos_x + value > ScrW - 20) then
        ply.pos_x = ply.pos_x + value
    end
end

local bullet_list = {}
local bullet_index = 0

local function plyShoot()
    local bullet = {
        index = bullet_index,
        speed = -10, -- Goes up
        pos_x = ply.pos_x,
        pos_y = ply.pos_y,
        damage = 1,
        size = 5
    }

    bullet_index = bullet_index + 1
    ply.ammo = ply.ammo - 1
    table.insert(bullet_list, bullet)
end

local function bulletMove()
    for key, bullet in pairs(bullet_list) do
        if bullet.pos_y < -10 then
            table.remove(bullet_list, key)
        end

        bullet.pos_y = bullet.pos_y + bullet.speed
    end
end

local enemy_list = {}
local enemy_index = 0

local function enemyCreate(e_speed, e_size, e_health)
    local enemy = {
        index = enemy_index,
        speed = e_speed, -- goes down
        pos_x = math.random(e_size, ScrW - e_size),
        pos_y = -10,
        size = e_size,
        health = e_health,
        rewardPoints = 1
    }

    enemy_index = enemy_index + 1
    table.insert(enemy_list, enemy)
end

local function enemyMove()
    for key, enemy in pairs(enemy_list) do
        if enemy.pos_y > (ScrH - enemy.size) then
            ply.health = ply.health - 1
            if ply.health < 1 then
                --[[ END OF GAME ]]
                helper.cleanup()
                game_active = false
            end
            table.remove(enemy_list, key)
        end

        enemy.pos_y = enemy.pos_y + enemy.speed
    end
end

local function calculateHit()
    for _, bullet in pairs(bullet_list) do
        for id, enemy in pairs(enemy_list) do
            -- https://studyflix.de/mathematik/abstand-zweier-punkte-2005
            if (math.sqrt((enemy.pos_x - bullet.pos_x) ^ 2 + (enemy.pos_y - bullet.pos_y) ^ 2) < enemy.size + bullet.size) then
                --[[ print("HIT!")
                print(math.sqrt((enemy.pos_x - bullet.pos_x) ^ 2 + (enemy.pos_y - bullet.pos_y) ^ 2)) ]]
                enemy.health = enemy.health - bullet.damage
                if enemy.health <= 0 then
                    table.remove(enemy_list, id)
                    ply.ammo = ply.ammo + 50
                    pointCount = pointCount + enemy.rewardPoints
                end
            end

        end
    end
end

-- https://www.youtube.com/watch?v=DOyJemh_7HE (Am Ende)

-- TODO: Enemys die zu nah am ply sind rot werden lassen / Enemys die weiter nach unten gehen Rot
local shaderCode_gradient = [[
extern vec2 screen;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {

    vec2 sc = vec2(screen_coords.x / screen.x, screen_coords.y / screen.y);

    return vec4(sc.xy, 0.0, 1.0);
}
]]

local shaderCode_background = [[
extern vec2 screen;
vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {

    vec2 sc = vec2(screen_coords.x / screen.x, screen_coords.y / screen.y);

    return vec4(sc.xy, 1.0, 0.1);
}
]]

function love.load()
    love.window.setTitle("Spaceshooter")
    ScrW, ScrH = love.window.getMode()
    newFont = love.graphics.newFont(60)
    shader_gradient = love.graphics.newShader(shaderCode_gradient)
    shader_background = love.graphics.newShader(shaderCode_background)

    math.randomseed(os.time())
    game_active = true

    setupPly()
end

local on_shoot_delay = 0
local enemy_delay = 20
local game_paused = false

function love.update(dt)
    if not game_active then
        goto GAMEEND
    end

    if love.keyboard.isDown("s") then
        game_paused = not game_paused
        return
    end

    if game_paused then
        return
    end

    -- helper.PrintTable(bullet_list)
    if (love.keyboard.isDown("d") or love.keyboard.isDown("right")) and not (love.keyboard.isDown("a") or love.keyboard.isDown("left")) then
        movePly(10)
    elseif (love.keyboard.isDown("a") or love.keyboard.isDown("left")) and not (love.keyboard.isDown("d") or love.keyboard.isDown("right")) then
        movePly(-10)
    end

    if (love.keyboard.isDown("space")) and (on_shoot_delay < 0) and (ply.ammo > 0) then

        plyShoot()
        on_shoot_delay = 6
    end

    if on_shoot_delay > -1 then
        on_shoot_delay = on_shoot_delay - 1
    end

    if enemy_delay < 0 then
        enemyCreate(1, 25, 20)
        enemy_delay = math.random(100, 150)
    else
        enemy_delay = enemy_delay - 1
    end

    bulletMove()
    enemyMove()

    calculateHit()

    ::GAMEEND::
end

function drawCenteredText(rectX, rectY, text)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, rectX, rectY, 0, 1, 1, textWidth / 2, textHeight / 2)
end



function love.draw()
    love.graphics.setShader(shader_background)
    shader_background:send("screen", {ScrW, ScrH})
    love.graphics.rectangle("fill", 0, 0, ScrW, ScrH)
    love.graphics.setShader(shader_gradient)
    shader_gradient:send("screen", {ScrW, ScrH})
    love.graphics.circle("fill", ply.pos_x, ply.pos_y, 20)

    for key, bullet in pairs(bullet_list) do
        love.graphics.circle("fill", bullet.pos_x, bullet.pos_y, bullet.size)
    end

    for key, enemy in pairs(enemy_list) do
        love.graphics.setShader(shader_gradient)
        love.graphics.circle("fill", enemy.pos_x, enemy.pos_y, enemy.size - 20 / enemy.health)
        local health = enemy.health
        love.graphics.setShader()
        love.graphics.setColor(health > 5 and {1, 1, 1} or {1, 0, 0})
        love.graphics.rectangle("fill", enemy.pos_x - 50, enemy.pos_y - 50, health * 5, 10)
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.setFont(newFont)
    love.graphics.setShader()

    if not game_active then
        drawCenteredText(ScrW / 2, ScrH / 2, "DU HAST VERLOREN")
    else
        love.graphics.print(pointCount or "0", math.floor(ScrW * 0.05), math.floor(ScrH * 0.1))
        love.graphics.print(ply.ammo or "0", math.floor(ScrW * 0.05), math.floor(ScrH * 0.85))
        love.graphics.print(ply.health or "0", math.floor(ScrW * 0.05), math.floor(ScrH * 0.7))
    end
end

function love.keypressed(k)
    if k == "r" then
        love.event.quit "restart"
    end
end