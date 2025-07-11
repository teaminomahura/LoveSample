local utils = require("utils")

local player = { x = 1280 / 2, y = 720 / 2, speed = 200, hp = 5, xp = 0, level = 1, invincible_timer = 0, xp_to_next_level = 3 }

function player.load()
    -- プレイヤーに関する初期化（もしあれば）
end

function player.update(dt)
    -- プレイヤーの無敵時間更新
    if player.invincible_timer > 0 then
        player.invincible_timer = player.invincible_timer - dt
    end

    -- プレイヤーの移動
    if love.keyboard.isDown("w", "up") then
        player.y = player.y - player.speed * dt
    end
    if love.keyboard.isDown("s", "down") then
        player.y = player.y + player.speed * dt
    end
    if love.keyboard.isDown("a", "left") then
        player.x = player.x - player.speed * dt
    end
    if love.keyboard.isDown("d", "right") then
        player.x = player.x + player.speed * dt
    end

    -- 画面外に出ないように制限
    player.x = math.max(0, math.min(player.x, 1280))
    player.y = math.max(0, math.min(player.y, 720))
end

function player.draw()
    love.graphics.setColor(1, 1, 1, 1) -- 白に設定
    love.graphics.rectangle("fill", player.x - 10, player.y - 10, 20, 20) -- プレイヤーを四角で描画
end

function player.reset()
    player.x = 1280 / 2
    player.y = 720 / 2
    player.hp = 5
    player.xp = 0
    player.level = 1
    player.invincible_timer = 0
    player.xp_to_next_level = 3
end

return player
