local player = { x = 1280 / 2, y = 720 / 2, speed = 200, hp = 20, xp = 0, level = 1 }
local knives = {}
local knife_speed = 500
local knife_interval = 0.5 -- 0.5秒ごとにナイフを発射
local knife_timer = 0

local enemies = {}
local enemy_speed = 100
local enemy_spawn_interval = 1 -- 1秒ごとに敵を生成
local enemy_spawn_timer = 0

local xp_to_next_level = 3 -- 次のレベルに必要な経験値

function love.load()
    love.window.setMode(1280, 720, { fullscreen = false, resizable = false, vsync = true })
    love.window.setTitle("Vampire Survivors Clone")
end

-- 衝突判定関数 (AABB)
function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and
           y1 < y2 + h2 and y1 + h1 > y2
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

    -- 敵の生成
    enemy_spawn_timer = enemy_spawn_timer + dt
    if enemy_spawn_timer >= enemy_spawn_interval then
        local spawn_x, spawn_y
        local side = math.random(1, 4) -- 1:上, 2:右, 3:下, 4:左
        if side == 1 then -- 上
            spawn_x = math.random(0, 1280)
            spawn_y = -50
        elseif side == 2 then -- 右
            spawn_x = 1280 + 50
            spawn_y = math.random(0, 720)
        elseif side == 3 then -- 下
            spawn_x = math.random(0, 1280)
            spawn_y = 720 + 50
        else -- 左
            spawn_x = -50
            spawn_y = math.random(0, 720)
        end
        table.insert(enemies, { x = spawn_x, y = spawn_y, hp = 1 }) -- 敵を生成
        enemy_spawn_timer = 0
    end

    -- 敵の移動 (プレイヤー追跡) とプレイヤーへのダメージ
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        local angle = math.atan2(player.y - enemy.y, player.x - enemy.x)
        enemy.x = enemy.x + math.cos(angle) * enemy_speed * dt
        enemy.y = enemy.y + math.sin(angle) * enemy_speed * dt

        -- 敵とプレイヤーの衝突判定
        if checkCollision(player.x - 10, player.y - 10, 20, 20, enemy.x - 10, enemy.y - 10, 20, 20) then
            player.hp = player.hp - 1 -- プレイヤーにダメージ
            table.remove(enemies, i) -- 敵を削除
            if player.hp <= 0 then
                love.event.quit() -- ゲームオーバー
            end
        end
    end

    -- ナイフと敵の衝突判定
    for i = #knives, 1, -1 do
        local knife = knives[i]
        for j = #enemies, 1, -1 do
            local enemy = enemies[j]
            if checkCollision(knife.x - 5, knife.y - 5, 10, 10, enemy.x - 10, enemy.y - 10, 20, 20) then
                table.remove(knives, i) -- ナイフを削除
                table.remove(enemies, j) -- 敵を削除
                player.xp = player.xp + 1 -- 経験値獲得
                if player.xp >= xp_to_next_level then
                    player.level = player.level + 1
                    player.xp = player.xp - xp_to_next_level
                    xp_to_next_level = math.floor(xp_to_next_level * 1.5) -- 次のレベルに必要な経験値を増加
                    knife_speed = knife_speed + 50 -- レベルアップでナイフ速度アップ
                end
                break -- 1つのナイフは1体の敵にしか当たらない
            end
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

    -- 敵の描画
    love.graphics.setColor(0, 0, 1, 1) -- 青に設定
    for i, enemy in ipairs(enemies) do
        love.graphics.rectangle("fill", enemy.x - 10, enemy.y - 10, 20, 20) -- 敵を四角で描画
    end

    -- HPの表示
    love.graphics.setColor(1, 1, 1, 1) -- 白に設定
    love.graphics.print("HP: " .. player.hp, 10, 10)

    -- 経験値とレベルの表示
    love.graphics.print("Level: " .. player.level, 10, 30)
    love.graphics.print("XP: " .. player.xp .. " / " .. xp_to_next_level, 10, 50)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
