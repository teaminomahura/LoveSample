local utils = require("utils")
local game_state = require("game_state")

local enemy = {}
local enemies_data = require("config.enemies")

enemy.enemies = {}
local enemy_spawn_timer = 0

-- 画面外のランダムな位置を取得するヘルパー関数
local function get_spawn_position(player)
    local spawn_x, spawn_y
    local off_screen_buffer = 50
    local screen_width = love.graphics.getWidth()
    local screen_height = love.graphics.getHeight()

    local side = math.random(1, 4)
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
    return spawn_x, spawn_y
end

-- 新しい敵を生成する内部関数
local function spawnEnemy(player)
    -- test_editorが有効な場合、その設定に従う
    if game_state.parameters.test_editor and game_state.parameters.test_editor.enabled then
        local editor_settings = game_state.parameters.test_editor
        local enemy_type_key = nil

        -- enemy_spawn_listが指定されている場合、その中からランダムに選択
        if #editor_settings.enemy_spawn_list > 0 then
            enemy_type_key = editor_settings.enemy_spawn_list[math.random(1, #editor_settings.enemy_spawn_list)]
        else
            -- 指定がない場合は通常の出現率に従う
            local rand = math.random()
            local cumulative_rate = 0
            for type, rate in pairs(game_state.parameters.spawn_rates) do
                cumulative_rate = cumulative_rate + rate
                if rand <= cumulative_rate then
                    enemy_type_key = type
                    break
                end
            end
        end

        if not enemy_type_key then return end -- Failsafe

        local spawn_x, spawn_y = get_spawn_position(player)
        local new_enemy_data = enemies_data[enemy_type_key]
        local new_enemy = { x = spawn_x, y = spawn_y, hp = new_enemy_data.hp, type = enemy_type_key, speed = new_enemy_data.speed, cooldown = 0, level = 0 }

        -- forced_enemy_levelsが指定されている場合、レベルを強制する
        if editor_settings.forced_enemy_levels and editor_settings.forced_enemy_levels[enemy_type_key] ~= nil then
            new_enemy.level = editor_settings.forced_enemy_levels[enemy_type_key]
        elseif enemy_type_key == "minus_enemy" then
            new_enemy.level = 1 -- デフォルトのマイナス敵レベル
        end
        table.insert(enemy.enemies, new_enemy)
        return
    end

    -- 通常の敵生成ロジック (test_editorが無効な場合)
    local rand = math.random()
    local cumulative_rate = 0
    local enemy_type_key = nil

    for type, rate in pairs(game_state.parameters.spawn_rates) do
        cumulative_rate = cumulative_rate + rate
        if rand <= cumulative_rate then
            enemy_type_key = type
            break
        end
    end

    if not enemy_type_key then return end -- Failsafe

    local spawn_x, spawn_y = get_spawn_position(player)
    local new_enemy_data = enemies_data[enemy_type_key]
    local new_enemy = { x = spawn_x, y = spawn_y, hp = new_enemy_data.hp, type = enemy_type_key, speed = new_enemy_data.speed, cooldown = 0, level = 0 }
    if enemy_type_key == "minus_enemy" then
        new_enemy.level = 1
    end
    table.insert(enemy.enemies, new_enemy)
end

function enemy.update(dt, player)
    -- 敵の生成
    enemy_spawn_timer = enemy_spawn_timer + dt
    if enemy_spawn_timer >= game_state.parameters.enemy_spawn_interval and #enemy.enemies < game_state.parameters.max_enemies then
        spawnEnemy(player)
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
            target_x, target_y = player.x, player.y
        else
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
                target_x, target_y = player.x, player.y
            end
        end

        local angle = math.atan2(target_y - current_enemy.y, target_x - current_enemy.x)
        current_enemy.x = current_enemy.x + math.cos(angle) * current_enemy.speed * dt
        current_enemy.y = current_enemy.y + math.sin(angle) * current_enemy.speed * dt

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
            player.invincible_timer = 0.1
            table.remove(enemy.enemies, i)
        end
    end

    -- プレイヤーから一定以上離れた敵を削除 (デスポーン)
    for i = #enemy.enemies, 1, -1 do
        local current_enemy = enemy.enemies[i]
        local dist_sq = (current_enemy.x - player.x)^2 + (current_enemy.y - player.y)^2
        local despawn_distance_sq = (love.graphics.getWidth() * 1.5)^2

        if dist_sq > despawn_distance_sq then
            table.remove(enemy.enemies, i)
        end
    end

    -- 同じ色の敵同士の重なりを防止
    for i = 1, #enemy.enemies do
        local enemy1 = enemy.enemies[i]
        for j = i + 1, #enemy.enemies do
            local enemy2 = enemy.enemies[j]
            if enemy1.type == enemy2.type then
                local dx = enemy1.x - enemy2.x
                local dy = enemy1.y - enemy2.y
                local dist_sq = dx*dx + dy*dy
                local min_dist_sq = 15*15
                if dist_sq < min_dist_sq and dist_sq > 0 then
                    local dist = math.sqrt(dist_sq)
                    local overlap = 15 - dist
                    local push_x = dx / dist * overlap * 0.5
                    local push_y = dy / dist * overlap * 0.5
                    enemy1.x = enemy1.x + push_x
                    enemy1.y = enemy1.y + push_y
                    enemy2.x = enemy2.x - push_x
                    enemy2.y = enemy2.y - push_y
                end
            end
        end
    end

    -- 敵同士の衝突判定
    local enemies_to_remove = {}
    for i = 1, #enemy.enemies do
        local enemy1 = enemy.enemies[i]
        for j = i + 1, #enemy.enemies do
            local enemy2 = enemy.enemies[j]
            if utils.checkCollision(enemy1.x - 10, enemy1.y - 10, 20, 20, enemy2.x - 10, enemy2.y - 10, 20, 20) then
                if (enemy1.type == "multiply_enemy" and enemy2.type == "minus_enemy") then
                    enemies_to_remove[i] = true
                    enemy2.level = math.min(enemy2.level + 1, 5)
                elseif (enemy2.type == "multiply_enemy" and enemy1.type == "minus_enemy") then
                    enemies_to_remove[j] = true
                    enemy1.level = math.min(enemy1.level + 1, 5)
                elseif (enemy1.type == "multiply_enemy" and enemy2.type == "plus_enemy" and enemy2.cooldown <= 0) then
                    enemies_to_remove[i] = true
                    enemy2.cooldown = game_state.parameters.enemy_cooldown_time
                    local plus_enemy_data = enemies_data.plus_enemy
                    table.insert(enemy.enemies, { x = enemy2.x, y = enemy2.y, hp = plus_enemy_data.hp, type = "plus_enemy", speed = plus_enemy_data.speed, cooldown = 0, level = 0 })
                elseif (enemy2.type == "multiply_enemy" and enemy1.type == "plus_enemy" and enemy1.cooldown <= 0) then
                    enemies_to_remove[j] = true
                    enemy1.cooldown = game_state.parameters.enemy_cooldown_time
                    local plus_enemy_data = enemies_data.plus_enemy
                    table.insert(enemy.enemies, { x = enemy1.x, y = enemy1.y, hp = plus_enemy_data.hp, type = "plus_enemy", speed = plus_enemy_data.speed, cooldown = 0, level = 0 })
                elseif (enemy1.type == "multiply_enemy" and enemy2.type == "divide_enemy") or (enemy2.type == "multiply_enemy" and enemy1.type == "divide_enemy") then
                    enemies_to_remove[i] = true
                    enemies_to_remove[j] = true
                elseif (enemy1.type == "minus_enemy" and enemy2.type == "plus_enemy") or (enemy2.type == "minus_enemy" and enemy1.type == "plus_enemy") then
                    enemies_to_remove[i] = true
                    enemies_to_remove[j] = true
                elseif (enemy1.type == "divide_enemy" and enemy2.type == "minus_enemy") then
                    enemies_to_remove[i] = true
                    enemy2.level = math.max(enemy2.level - 1, 0)
                    if enemy2.level == 0 then
                        enemies_to_remove[j] = true
                    end
                elseif (enemy2.type == "divide_enemy" and enemy1.type == "minus_enemy") then
                    enemies_to_remove[j] = true
                    enemy1.level = math.max(enemy1.level - 1, 0)
                    if enemy1.level == 0 then
                        enemies_to_remove[i] = true
                    end
                elseif (enemy1.type == "divide_enemy" and enemy2.type == "plus_enemy") then
                    enemies_to_remove[i] = true
                    local enemy_types = {"minus_enemy", "plus_enemy", "multiply_enemy", "divide_enemy"}
                    local random_enemy_type = enemy_types[math.random(#enemy_types)]
                    local new_enemy_data = enemies_data[random_enemy_type]
                    local offset_dist = 20
                    table.insert(enemy.enemies, { x = enemy2.x, y = enemy2.y - offset_dist, hp = new_enemy_data.hp, type = random_enemy_type, speed = new_enemy_data.speed, cooldown = 0, level = (random_enemy_type == "minus_enemy" and 1) or 0 })
                    table.insert(enemy.enemies, { x = enemy2.x, y = enemy2.y + offset_dist, hp = new_enemy_data.hp, type = random_enemy_type, speed = new_enemy_data.speed, cooldown = 0, level = (random_enemy_type == "minus_enemy" and 1) or 0 })
                elseif (enemy2.type == "divide_enemy" and enemy1.type == "plus_enemy") then
                    enemies_to_remove[j] = true
                    local enemy_types = {"minus_enemy", "plus_enemy", "multiply_enemy", "divide_enemy"}
                    local random_enemy_type = enemy_types[math.random(#enemy_types)]
                    local new_enemy_data = enemies_data[random_enemy_type]
                    local offset_dist = 20
                    table.insert(enemy.enemies, { x = enemy1.x, y = enemy1.y - offset_dist, hp = new_enemy_data.hp, type = random_enemy_type, speed = new_enemy_data.speed, cooldown = 0, level = (random_enemy_type == "minus_enemy" and 1) or 0 })
                    table.insert(enemy.enemies, { x = enemy1.x, y = enemy1.y + offset_dist, hp = new_enemy_data.hp, type = random_enemy_type, speed = new_enemy_data.speed, cooldown = 0, level = (random_enemy_type == "minus_enemy" and 1) or 0 })
                end
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
    for i, current_enemy in ipairs(enemy.enemies) do
        local enemy_data = enemies_data[current_enemy.type]
        if enemy_data and enemy_data.color then
            love.graphics.setColor(enemy_data.color)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.rectangle("fill", current_enemy.x - 10, current_enemy.y - 10, 20, 20)

        if current_enemy.type == "minus_enemy" and current_enemy.level then
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.printf(tostring(current_enemy.level), current_enemy.x - 10, current_enemy.y - 12, 20, "center")
        end
    end
end

function enemy.reset()
    enemy.enemies = {}
    enemy_spawn_timer = 0
end

return enemy