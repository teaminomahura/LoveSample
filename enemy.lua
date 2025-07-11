local utils = require("utils")

local enemy = {}

enemy.enemies = {}
local enemy_speed = 100
local enemy_spawn_interval = 1 -- 1秒ごとに敵を生成
local enemy_spawn_timer = 0
local green_enemy_spawn_chance = 0.2 -- 緑の敵の生成確率 (20%)

function enemy.update(dt, player)
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
        table.insert(enemy.enemies, { x = spawn_x, y = spawn_y, hp = 1, type = enemy_type }) -- 敵を生成
        enemy_spawn_timer = 0
    end

    -- 敵の移動 (プレイヤー追跡) とプレイヤーへのダメージ/回復
    for i = #enemy.enemies, 1, -1 do
        local current_enemy = enemy.enemies[i]
        local target_x, target_y

        if current_enemy.type == "minus" then
            target_x, target_y = player.x, player.y -- 赤い敵はプレイヤーを追跡
        else -- current_enemy.type == "plus"
            -- 最も近い赤い敵を追跡
            local closest_minus_enemy = nil
            local min_dist_sq = math.huge
            for k, other_enemy in ipairs(enemy.enemies) do
                if other_enemy.type == "minus" then
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
                target_x, target_y = player.x, player.y -- 赤い敵がいなければプレイヤーを追跡
            end
        end

        local angle = math.atan2(target_y - current_enemy.y, target_x - current_enemy.x)
        current_enemy.x = current_enemy.x + math.cos(angle) * enemy_speed * dt
        current_enemy.y = current_enemy.y + math.sin(angle) * enemy_speed * dt

        -- 敵とプレイヤーの衝突判定
        if player.invincible_timer <= 0 and utils.checkCollision(player.x - 10, player.y - 10, 20, 20, current_enemy.x - 10, current_enemy.y - 10, 20, 20) then
            if current_enemy.type == "minus" then
                player.hp = player.hp - 1 -- プレイヤーにダメージ
            else -- current_enemy.type == "plus"
                player.hp = player.hp + 1 -- プレイヤーを回復
            end
            player.invincible_timer = 0.1 -- 0.1秒間無敵
            table.remove(enemy.enemies, i) -- 敵を削除
            
        end
    end

    -- 敵同士の衝突判定 (緑の敵と赤い敵が当たると両方消滅)
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
    -- 敵の描画
    for i, current_enemy in ipairs(enemy.enemies) do
        if current_enemy.type == "minus" then
            love.graphics.setColor(0, 0, 1, 1) -- 青に設定 (赤い敵)
        else -- current_enemy.type == "plus"
            love.graphics.setColor(0, 1, 0, 1) -- 緑に設定 (回復する敵)
        end
        love.graphics.rectangle("fill", current_enemy.x - 10, current_enemy.y - 10, 20, 20) -- 敵を四角で描画
    end
end

function enemy.reset()
    enemy.enemies = {}
end

return enemy
