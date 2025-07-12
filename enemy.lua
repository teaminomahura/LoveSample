local utils = require("utils")

local enemy = {}
local enemies_data = require("config.enemies")

enemy.enemies = {}
local enemy_spawn_interval = 0.5 -- 0.5秒ごとに敵を生成
local enemy_spawn_timer = 0
local max_enemies = 50 -- 画面内に存在できる敵の最大数

function enemy.update(dt, player)
    -- 敵の生成
    enemy_spawn_timer = enemy_spawn_timer + dt
    if enemy_spawn_timer >= enemy_spawn_interval and #enemy.enemies < max_enemies then
        local spawn_x, spawn_y
        local off_screen_buffer = 50 -- 画面外からの生成バッファ
        local screen_width = love.graphics.getWidth()
        local screen_height = love.graphics.getHeight()

        local side = math.random(1, 4) -- 1:上, 2:右, 3:下, 4:左
        if side == 1 then -- 上
            spawn_x = player.x + math.random(-screen_width / 2, screen_width / 2)
            spawn_y = player.y - screen_height / 2 - off_screen_buffer
        elseif side == 2 then -- 右
            spawn_x = player.x + screen_width / 2 + off_screen_buffer
            spawn_y = player.y + math.random(-screen_height / 2, screen_height / 2)
        elseif side == 3 then -- 下
            spawn_x = player.x + math.random(-screen_width / 2, screen_width / 2)
            spawn_y = player.y + screen_height / 2 + off_screen_buffer
        else -- 左
            spawn_x = player.x - screen_width / 2 - off_screen_buffer
            spawn_y = player.y + math.random(-screen_height / 2, screen_height / 2)
        end

        -- 敵の種類を重み付きでランダムに決定
        local rand = math.random()
        local enemy_type_key
        if rand < 0.5 then -- 50% の確率
            enemy_type_key = "minus_enemy"
        elseif rand < 0.8 then -- 30% の確率
            enemy_type_key = "plus_enemy"
        elseif rand < 0.9 then -- 10% の確率
            enemy_type_key = "multiply_enemy"
        else -- 10% の確率
            enemy_type_key = "divide_enemy"
        end
        
        local new_enemy_data = enemies_data[enemy_type_key]
        table.insert(enemy.enemies, { x = spawn_x, y = spawn_y, hp = new_enemy_data.hp, type = enemy_type_key, speed = new_enemy_data.speed, cooldown = 0 }) -- 敵を生成 (クールダウンを追加)
        enemy_spawn_timer = 0
    end

    -- 敵のクールダウン更新
    for i = #enemy.enemies, 1, -1 do
        local current_enemy = enemy.enemies[i]
        if current_enemy.cooldown > 0 then
            current_enemy.cooldown = current_enemy.cooldown - dt
        end
    end

    -- 敵の移動 (プレイヤー追跡) とプレイヤーへのダメージ/回復
    for i = #enemy.enemies, 1, -1 do
        local current_enemy = enemy.enemies[i]
        local target_x, target_y

        if current_enemy.type == "minus_enemy" then
            target_x, target_y = player.x, player.y -- マイナス敵はプレイヤーを追跡
        else -- それ以外の敵は、現時点では最も近いマイナス敵を追う（仮）
            -- TODO: 本来の追跡ロジックを実装する
            local closest_minus_enemy = nil
            local min_dist_sq = math.huge
            for k, other_enemy in ipairs(enemy.enemies) do
                if other_enemy.type == "minus_enemy" then
                    local dist_sq = (current_enemy.x - other_enemy.x)^2 + (current_enemy.y - other_enemy.y)^2
                    if dist_sq < min_dist_sq then
                        min_dist_sq = dist_sq
                        closest_minus_enemy = other_enemy
                    end
                end
            end
            if closest_minus_enemy then
                target_x, target_y = closest_minus_enemy.x, closest_minus_enemy.y
            else
                target_x, target_y = player.x, player.y -- マイナス敵がいなければプレイヤーを追跡
            end
        end

        local angle = math.atan2(target_y - current_enemy.y, target_x - current_enemy.x)
        current_enemy.x = current_enemy.x + math.cos(angle) * current_enemy.speed * dt
        current_enemy.y = current_enemy.y + math.sin(angle) * current_enemy.speed * dt

        -- 敵とプレイヤーの衝突判定
        if player.invincible_timer <= 0 and utils.checkCollision(player.x - 10, player.y - 10, 20, 20, current_enemy.x - 10, current_enemy.y - 10, 20, 20) then
            if current_enemy.type == "minus_enemy" then
                player.hp = player.hp - 1
            elseif current_enemy.type == "plus_enemy" then
                player.hp = player.hp + 1
            elseif current_enemy.type == "multiply_enemy" then
                player.hp = player.hp * 2
            elseif current_enemy.type == "divide_enemy" then
                player.hp = math.floor(player.hp / 2)
            end
            player.invincible_timer = 0.1 -- 0.1秒間無敵
            table.remove(enemy.enemies, i) -- 敵を削除
        end
    end

    -- プレイヤーから一定以上離れた敵を削除 (デスポーン)
    for i = #enemy.enemies, 1, -1 do
        local current_enemy = enemy.enemies[i]
        local dist_sq = (current_enemy.x - player.x)^2 + (current_enemy.y - player.y)^2
        local despawn_distance_sq = (love.graphics.getWidth() * 1.5)^2 -- 画面の1.5倍の距離でデスポーン

        if dist_sq > despawn_distance_sq then
            table.remove(enemy.enemies, i)
        end
    end

    -- 同じ色の敵同士の重なりを防止
    for i = 1, #enemy.enemies do
        local enemy1 = enemy.enemies[i]
        for j = i + 1, #enemy.enemies do
            local enemy2 = enemy.enemies[j]

            if enemy1.type == enemy2.type then -- 同じ色の敵同士の場合
                local dx = enemy1.x - enemy2.x
                local dy = enemy1.y - enemy2.y
                local dist_sq = dx*dx + dy*dy
                local min_dist_sq = 15*15 -- 中心間の最小距離の二乗 (15ピクセル)

                if dist_sq < min_dist_sq and dist_sq > 0 then
                    local dist = math.sqrt(dist_sq)
                    local overlap = 15 - dist
                    local push_x = dx / dist * overlap * 0.5 -- 押し返す力
                    local push_y = dy / dist * overlap * 0.5

                    enemy1.x = enemy1.x + push_x
                    enemy1.y = enemy1.y + push_y
                    enemy2.x = enemy2.x - push_x
                    enemy2.y = enemy2.y - push_y
                end
            end
        end
    end

    -- 敵同士の衝突判定 (異なる種類の敵が当たると両方消滅 - 仮仕様)
    local enemies_to_remove = {}
    for i = 1, #enemy.enemies do
        local enemy1 = enemy.enemies[i]
        for j = i + 1, #enemy.enemies do
            local enemy2 = enemy.enemies[j]
            if enemy1.type ~= enemy2.type and utils.checkCollision(enemy1.x - 10, enemy1.y - 10, 20, 20, enemy2.x - 10, enemy2.y - 10, 20, 20) then
                enemies_to_remove[i] = true
                enemies_to_remove[j] = true
            end
        end
    end

    for i = #enemy.enemies, 1, -1 do
        if enemies_to_remove[i] then
            table.remove(enemy.enemies, i)
        end
    end
end

function enemy.draw()
    -- 敵の描画 (データ駆動型)
    for i, current_enemy in ipairs(enemy.enemies) do
        local enemy_data = enemies_data[current_enemy.type]
        if enemy_data and enemy_data.color then
            love.graphics.setColor(enemy_data.color)
        else
            love.graphics.setColor(1, 1, 1, 1) -- データがない場合は白
        end
        love.graphics.rectangle("fill", current_enemy.x - 10, current_enemy.y - 10, 20, 20) -- 敵を四角で描画
    end
end

function enemy.reset()
    enemy.enemies = {}
    enemy_spawn_timer = 0
end

return enemy
