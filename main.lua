local player = require("player")
local enemy = require("enemy")
local bullet = require("bullet")
local utils = require("utils")
local game_state = require("game_state")





function love.load()
    love.window.setMode(1280, 720, { fullscreen = false, resizable = false, vsync = true })
    love.window.setTitle("Vampire Survivors Clone")
end



function love.update(dt)
    player.update(dt)
    enemy.update(dt, player)
    bullet.update(dt, player, enemy)
    game_state.update(dt, player)

    
end

function love.draw()
    player.draw()
    enemy.draw()
    bullet.draw()

    

    -- HPの表示
    love.graphics.setColor(1, 1, 1, 1) -- 白に設定
    love.graphics.print("HP: " .. player.hp, 10, 10)

    -- 経験値とレベルの表示
    love.graphics.print("Level: " .. player.level, 10, 30)
    love.graphics.print("XP: " .. player.xp .. " / " .. player.xp_to_next_level, 10, 50)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end