local utils = require("utils")
local game_state = require("game_state")
local enemies_data = require("config.enemies")

local enemy = {}
enemy.enemies = {}
local enemy_spawn_timer = 0
local enemies_to_add = {} -- フレームの最後に追加する敵を一時的に保持するリスト

--=============================================================================
-- クラス定義 (Class Definitions)
--=============================================================================

-- 全ての敵の基礎となる「親クラス」 (Base class for all enemies)
local Enemy = utils.class()

function Enemy:init(x, y, type)
    self.x = x
    self.y = y
    self.type = type

    local data = enemies_data[type]
    self.hp = data.hp
    self.speed = data.speed
    self.color = utils.deep_copy(data.color) -- 色テーブルをコピーして、元の定義を汚染しないようにする
    self.invincibility_timer = data.spawn_invincibility_duration

    self.cooldown = 0
    self.level = 0
    self.to_remove = false -- 削除フラグ
end

-- 共通の更新ロジック (Common update logic)
function Enemy:update(dt, player, all_enemies)
    -- タイマー更新 (クールダウンと無敵時間)
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - dt
    end
    if self.invincibility_timer and self.invincibility_timer > 0 then
        self.invincibility_timer = self.invincibility_timer - dt
    end

    -- 敵の移動 (プレイヤー追跡) - このロジックは今後、各敵クラスに移植される
    local target_x, target_y
    if self.type == "minus_enemy" then
        target_x, target_y = player.x, player.y
    elseif self.type == "divide_enemy" then
        local closest_multiply_enemy = nil
        local min_dist_sq = math.huge
        for k, other_enemy in ipairs(all_enemies) do
            if other_enemy.type == "multiply_enemy" then
                local dist_sq = (self.x - other_enemy.x)^2 + (self.y - other_enemy.y)^2
                if dist_sq < min_dist_sq then
                    min_dist_sq = dist_sq
                    closest_multiply_enemy = other_enemy
                end
            end
        end
        if closest_multiply_enemy then
            target_x, target_y = closest_multiply_enemy.x, closest_multiply_enemy.y
        else
            local closest_minus_enemy = nil
            local min_dist_sq_minus = math.huge
            for k, other_enemy in ipairs(all_enemies) do
                if other_enemy.type == "minus_enemy" then
                    local dist_sq_minus = (self.x - other_enemy.x)^2 + (self.y - other_enemy.y)^2
                    if dist_sq_minus < min_dist_sq_minus then
                        min_dist_sq_minus = dist_sq_minus
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
    elseif self.type == "multiply_enemy" then
        local closest_minus_enemy = nil
        local min_dist_sq_minus = math.huge
        for k, other_enemy in ipairs(all_enemies) do
            if other_enemy.type == "minus_enemy" then
                local dist_sq = (self.x - other_enemy.x)^2 + (self.y - other_enemy.y)^2
                if dist_sq < min_dist_sq_minus then
                    min_dist_sq_minus = dist_sq
                    closest_minus_enemy = other_enemy
                end
            end
        end
        if closest_minus_enemy then
            local dist_to_player_sq = (self.x - player.x)^2 + (self.y - player.y)^2
            if min_dist_sq_minus < dist_to_player_sq then
                target_x, target_y = closest_minus_enemy.x, closest_minus_enemy.y
            else
                target_x = self.x + (self.x - player.x) * 100
                target_y = self.y + (self.y - player.y) * 100
            end
        else
            target_x = self.x + (self.x - player.x) * 100
            target_y = self.y + (self.y - player.y) * 100
        end
    else -- plus_enemy はプレイヤーを追跡
        target_x, target_y = player.x, player.y
    end

    local angle = math.atan2(target_y - self.y, target_x - self.x)
    self.x = self.x + math.cos(angle) * self.speed * dt
    self.y = self.y + math.sin(angle) * self.speed * dt

    -- プレイヤーとの衝突判定
    local is_invincible = self.invincibility_timer and self.invincibility_timer > 0
    if not is_invincible and player.invincible_timer <= 0 and utils.checkCollision(player.x - 10, player.y - 10, 20, 20, self.x - 10, self.y - 10, 20, 20) then
        if self.type == "minus_enemy" then
            player.hp = player.hp - 1
        elseif self.type == "plus_enemy" then
            player.hp = player.hp + 1
        elseif self.type == "multiply_enemy" then
            player.hp = player.hp * 2
        elseif self.type == "divide_enemy" then
            player.hp = math.floor(player.hp / 2)
        end
        player.invincible_timer = 0.1
        self.to_remove = true
    end

    -- プレイヤーから一定以上離れた敵を削除 (デスポーン)
    local dist_sq = (self.x - player.x)^2 + (self.y - player.y)^2
    local despawn_distance_sq = (love.graphics.getWidth() * 1.5)^2
    if dist_sq > despawn_distance_sq then
        self.to_remove = true
    end
end

-- 描画ロジック (Drawing logic)
function Enemy:draw()
    local r, g, b, a = unpack(self.color)

    -- 無敵時間中は半透明にする
    if self.invincibility_timer and self.invincibility_timer > 0 then
        a = a * 0.5
    end

    love.graphics.setColor(r, g, b, a)
    love.graphics.rectangle("fill", self.x - 10, self.y - 10, 20, 20)

    -- マイナス敵のレベル表示
    if self.type == "minus_enemy" and self.level then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(tostring(self.level), self.x - 10, self.y - 12, 20, "center")
    end
end


--=============================================================================
-- モジュール関数 (Module Functions)
--=============================================================================

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
    local enemy_type_key
    if game_state.parameters.test_editor and game_state.parameters.test_editor.enabled then
        local editor_settings = game_state.parameters.test_editor
        if #editor_settings.enemy_spawn_list > 0 then
            enemy_type_key = editor_settings.enemy_spawn_list[math.random(1, #editor_settings.enemy_spawn_list)]
        end
    end
    if not enemy_type_key then
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
    if not enemy_type_key then return end

    local spawn_x, spawn_y = get_spawn_position(player)
    -- enemy.create を通して敵を生成
    enemy.create(enemy_type_key, spawn_x, spawn_y)
end

-- 他のモジュール（bullet.luaなど）から安全に敵を生成するための公式な「窓口」
function enemy.create(type, x, y, level_override)
    -- Enemyクラスからインスタンスを生成
    local new_enemy = Enemy:new(x, y, type)
    -- 必要であればレベルを上書き
    if level_override then
        new_enemy.level = level_override
    elseif new_enemy.type == "minus_enemy" then
        new_enemy.level = 1
    end
    table.insert(enemies_to_add, new_enemy) -- 一時リストに追加
end

function enemy.update(dt, player)
    -- 敵の生成
    enemy_spawn_timer = enemy_spawn_timer + dt
    if enemy_spawn_timer >= game_state.parameters.enemy_spawn_interval and #enemy.enemies < game_state.parameters.max_enemies then
        spawnEnemy(player)
        enemy_spawn_timer = 0
    end

    -- 各敵インスタンスの共通updateメソッドを呼び出す
    for _, current_enemy in ipairs(enemy.enemies) do
        current_enemy:update(dt, player, enemy.enemies) -- all_enemiesを渡す
    end

    -- ============================================================================\
    -- ↓↓↓ この下のロジックは、今後、各敵クラスに段階的に移植していく ↓↓↓\
    -- ============================================================================\

    -- 敵の移動 (プレイヤー追跡) は各Enemyインスタンスのupdateメソッド内で処理されるため、ここでは不要
    -- プレイヤーとの衝突判定も各Enemyインスタンスのupdateメソッド内で処理されるため、ここでは不要

    -- 同じ色の敵同士の重なりを防止
    for i = 1, #enemy.enemies do
        for j = i + 1, #enemy.enemies do
            local enemy1 = enemy.enemies[i]
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
    for i = 1, #enemy.enemies do
        for j = i + 1, #enemy.enemies do
            local enemy1 = enemy.enemies[i]
            local enemy2 = enemy.enemies[j]

            local is_enemy1_invincible = enemy1.invincibility_timer and enemy1.invincibility_timer > 0
            local is_enemy2_invincible = enemy2.invincibility_timer and enemy2.invincibility_timer > 0

            if not is_enemy1_invincible and not is_enemy2_invincible and utils.checkCollision(enemy1.x - 10, enemy1.y - 10, 20, 20, enemy2.x - 10, enemy2.y - 10, 20, 20) then
                if (enemy1.type == "multiply_enemy" and enemy2.type == "minus_enemy") then
                    enemy1.to_remove = true
                    enemy2.level = math.min(enemy2.level + 1, 5)
                elseif (enemy2.type == "multiply_enemy" and enemy1.type == "minus_enemy") then
                    enemy2.to_remove = true
                    enemy1.level = math.min(enemy1.level + 1, 5)
                elseif (enemy1.type == "multiply_enemy" and enemy2.type == "plus_enemy" and enemy2.cooldown <= 0) then
                    enemy1.to_remove = true
                    enemy2.cooldown = game_state.parameters.enemy_cooldown_time
                    enemy.create("plus_enemy", enemy2.x, enemy2.y) -- enemy.create を使用
                elseif (enemy2.type == "multiply_enemy" and enemy1.type == "plus_enemy" and enemy1.cooldown <= 0) then
                    enemy2.to_remove = true
                    enemy1.cooldown = game_state.parameters.enemy_cooldown_time
                    enemy.create("plus_enemy", enemy1.x, enemy1.y) -- enemy.create を使用
                elseif (enemy1.type == "multiply_enemy" and enemy2.type == "divide_enemy") or (enemy2.type == "multiply_enemy" and enemy1.type == "divide_enemy") then
                    enemy1.to_remove = true
                    enemy2.to_remove = true
                elseif (enemy1.type == "minus_enemy" and enemy2.type == "plus_enemy") or (enemy2.type == "minus_enemy" and enemy1.type == "plus_enemy") then
                    enemy1.to_remove = true
                    enemy2.to_remove = true
                elseif (enemy1.type == "divide_enemy" and enemy2.type == "minus_enemy") then
                    enemy1.to_remove = true
                    enemy2.level = math.max(enemy2.level - 1, 0)
                    if enemy2.level == 0 then
                        enemy2.to_remove = true
                    end
                elseif (enemy2.type == "divide_enemy" and enemy1.type == "minus_enemy") then
                    enemy2.to_remove = true
                    enemy1.level = math.max(enemy1.level - 1, 0)
                    if enemy1.level == 0 then
                        enemy1.to_remove = true
                    end
                elseif (enemy1.type == "divide_enemy" and enemy2.type == "plus_enemy") then
                    enemy2.to_remove = true -- Remove plus_enemy
                    -- Transform divide_enemy
                    local enemy_types = {"minus_enemy", "plus_enemy", "multiply_enemy", "divide_enemy"}
                    local random_enemy_type = enemy_types[math.random(#enemy_types)]
                    enemy1.type = random_enemy_type
                    enemy1.level = (random_enemy_type == "minus_enemy" and 1) or 0
                    enemy1.invincibility_timer = enemies_data[random_enemy_type].spawn_invincibility_duration
                elseif (enemy2.type == "divide_enemy" and enemy1.type == "plus_enemy") then
                    enemy1.to_remove = true -- Remove plus_enemy
                    -- Transform divide_enemy
                    local enemy_types = {"minus_enemy", "plus_enemy", "multiply_enemy", "divide_enemy"}
                    local random_enemy_type = enemy_types[math.random(#enemy_types)]
                    enemy2.type = random_enemy_type
                    enemy2.level = (random_enemy_type == "minus_enemy" and 1) or 0
                    enemy2.invincibility_timer = enemies_data[random_enemy_type].spawn_invincibility_duration
                end
            end
        end
    end

    -- 削除フラグの立った敵を実際に削除する
    local i = #enemy.enemies
    while i >= 1 do
        if enemy.enemies[i].to_remove then
            table.remove(enemy.enemies, i)
        end
        i = i - 1
    end

    -- 追加フラグの立った敵を実際にリストへ追加する
    if #enemies_to_add > 0 then
        for _, new_enemy in ipairs(enemies_to_add) do
            table.insert(enemy.enemies, new_enemy)
        end
        enemies_to_add = {} -- リストをクリア
    end
end

function enemy.draw()
    for _, current_enemy in ipairs(enemy.enemies) do
        current_enemy:draw()
    end
end

function enemy.reset()
    enemy.enemies = {}
    enemy_spawn_timer = 0
    enemies_to_add = {} -- リストをクリア
end

return enemy
