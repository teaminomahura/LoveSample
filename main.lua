local player = { x = 1280 / 2, y = 720 / 2, speed = 200, hp = 20, xp = 0, level = 1, invincible_timer = 0 }
local knives = {}
local knife_speed = 500
local knife_interval = 0.5 -- 0.5秒ごとにナイフを発射
local knife_timer = 0

local enemies = {}
local enemy_speed = 100
local enemy_spawn_interval = 1 -- 1秒ごとに敵を生成
local enemy_spawn_timer = 0
local green_enemy_spawn_chance = 0.2 -- 緑の敵の生成確率 (20%)

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

        local enemy_type = "minus" -- デフォルトはマイナス属性
        if math.random() < green_enemy_spawn_chance then
            enemy_type = "plus" -- 緑の敵を生成
        end
        table.insert(enemies, { x = spawn_x, y = spawn_y, hp = 1, type = enemy_type }) -- 敵を生成
        enemy_spawn_timer = 0
    end

    -- 敵の移動 (プレイヤー追跡) とプレイヤーへのダメージ/回復
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        local target_x, target_y

        if enemy.type == "minus" then
            target_x, target_y = player.x, player.y -- 赤い敵はプレイヤーを追跡
        else -- enemy.type == "plus"
            -- 最も近い赤い敵を追跡
            local closest_minus_enemy = nil
            local min_dist_sq = math.huge
            for k, other_enemy in ipairs(enemies) do
                if other_enemy.type == "minus" then
                    local dist_sq = (enemy.x - other_enemy.x)^2 + (enemy.y - other_enemy.y)^2
                    if dist_sq < min_dist_sq then
                        min_dist_sq = dist_sq
                        closest_minus_enemy = other_enemy
                    end
                end
            end
            if closest_minus_enemy then
                target_x, target_y = closest_minus_enemy.x, closest_minus_enemy.y
            else
                target_x, target_y = player.x, player.y -- 赤い敵がいなければプレイヤーを追跡
            end
        end

        local angle = math.atan2(target_y - enemy.y, target_x - enemy.x)
        enemy.x = enemy.x + math.cos(angle) * enemy_speed * dt
        enemy.y = enemy.y + math.sin(angle) * enemy_speed * dt

        -- 敵とプレイヤーの衝突判定
        if player.invincible_timer <= 0 and checkCollision(player.x - 10, player.y - 10, 20, 20, enemy.x - 10, enemy.y - 10, 20, 20) then
            if enemy.type == "minus" then
                player.hp = player.hp - 1 -- プレイヤーにダメージ
            else -- enemy.type == "plus"
                player.hp = player.hp + 1 -- プレイヤーを回復
            end
            player.invincible_timer = 0.5 -- 0.5秒間無敵
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
                -- ナイフはプラス属性なので、マイナス属性の敵を倒し、プラス属性の敵は消滅させる
                if enemy.type == "minus" then
                    table.remove(knives, i) -- ナイフを削除
                    table.remove(enemies, j) -- 敵を削除
                    player.xp = player.xp + 1 -- 経験値獲得
                    if player.xp >= xp_to_next_level then
                        player.level = player.level + 1
                        player.xp = player.xp - xp_to_next_level
                        xp_to_next_level = math.floor(xp_to_next_level * 1.5) -- 次のレベルに必要な経験値を増加
                        knife_interval = math.max(0.1, knife_interval - 0.1) -- レベルアップでナイフ発射間隔を短縮
                    end
                else -- enemy.type == "plus"
                    table.remove(knives, i) -- ナイフを削除
                    -- 緑の敵を分裂させる
                    table.insert(enemies, { x = enemy.x + 15, y = enemy.y, hp = 1, type = "plus" })
                    table.insert(enemies, { x = enemy.x - 15, y = enemy.y, hp = 1, type = "plus" })
                    -- 経験値は入らない
                end
                break -- 1つのナイフは1体の敵にしか当たらない
            end
        end
    end

    -- 敵同士の衝突判定 (緑の敵と赤い敵が当たると両方消滅)
    for i = #enemies, 1, -1 do
        local enemy1 = enemies[i]
        for j = i - 1, 1, -1 do -- 重複を避けるためi-1から
            local enemy2 = enemies[j]
            if enemy1.type ~= enemy2.type and checkCollision(enemy1.x - 10, enemy1.y - 10, 20, 20, enemy2.x - 10, enemy2.y - 10, 20, 20) then
                table.remove(enemies, i)
                table.remove(enemies, j)
                break
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
    for i, enemy in ipairs(enemies) do
        if enemy.type == "minus" then
            love.graphics.setColor(0, 0, 1, 1) -- 青に設定 (赤い敵)
        else -- enemy.type == "plus"
            love.graphics.setColor(0, 1, 0, 1) -- 緑に設定 (回復する敵)
        end
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