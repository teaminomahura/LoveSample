local player = { x = 1280 / 2, y = 720 / 2, speed = 200 }
local knives = {}
local knife_speed = 500
local knife_interval = 0.5 -- 0.5秒ごとにナイフを発射
local knife_timer = 0

function love.load()
    love.window.setMode(1280, 720, { fullscreen = false, resizable = false, vsync = true })
    love.window.setTitle("Vampire Survivors Clone")
end

function love.update(dt)
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

    -- ナイフの発射
    knife_timer = knife_timer + dt
    if knife_timer >= knife_interval then
        table.insert(knives, { x = player.x, y = player.y, angle = math.random() * math.pi * 2 }) -- 全方向に発射
        knife_timer = 0
    end

    -- ナイフの移動と画面外での消滅
    for i = #knives, 1, -1 do
        local knife = knives[i]
        knife.x = knife.x + math.cos(knife.angle) * knife_speed * dt
        knife.y = knife.y + math.sin(knife.angle) * knife_speed * dt

        -- 画面外に出たら削除
        if knife.x < -20 or knife.x > 1280 + 20 or knife.y < -20 or knife.y > 720 + 20 then
            table.remove(knives, i)
        end
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1, 1) -- 白に設定
    love.graphics.rectangle("fill", player.x - 10, player.y - 10, 20, 20) -- プレイヤーを四角で描画

    -- ナイフの描画
    love.graphics.setColor(1, 0, 0, 1) -- 赤に設定
    for i, knife in ipairs(knives) do
        love.graphics.rectangle("fill", knife.x - 5, knife.y - 5, 10, 10) -- ナイフを小さな四角で描画
    end
end
