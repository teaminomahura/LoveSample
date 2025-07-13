local utils = require("utils")
local enemies_data = require("config.enemies")
local game_state = require("game_state")

local bullet = {}

bullet.bullets = {}
local bullet_timer = 0

function bullet.update(dt, player, enemy)
    -- ナイフの発射
    bullet_timer = bullet_timer + dt
    if bullet_timer >= game_state.parameters.bullet_interval then
        table.insert(bullet.bullets, { x = player.x, y = player.y, angle = math.random() * math.pi * 2, lifetime = 0.5 }) -- 全方向に発射、寿命0.5秒
        bullet_timer = 0
    end

    -- ナイフの移動と画面外での消滅
    for i = #bullet.bullets, 1, -1 do
        local current_bullet = bullet.bullets[i]
        current_bullet.x = current_bullet.x + math.cos(current_bullet.angle) * game_state.parameters.bullet_speed * dt
        current_bullet.y = current_bullet.y + math.sin(current_bullet.angle) * game_state.parameters.bullet_speed * dt

        current_bullet.lifetime = current_bullet.lifetime - dt
        if current_bullet.lifetime <= 0 then
            table.remove(bullet.bullets, i)
        end
    end

    -- ナイフと敵の衝突判定
    for i = #bullet.bullets, 1, -1 do
        local current_bullet = bullet.bullets[i]
        for j = #enemy.enemies, 1, -1 do
            local current_enemy = enemy.enemies[j]
            if utils.checkCollision(current_bullet.x - 5, current_bullet.y - 5, 10, 10, current_enemy.x - 10, current_enemy.y - 10, 20, 20) then
                if current_enemy.type == "minus_enemy" then
                    table.remove(bullet.bullets, i) -- ナイフを削除
                    table.remove(enemy.enemies, j) -- 敵を削除
                    player.xp = player.xp + 1 -- 経験値獲得
                elseif current_enemy.type == "plus_enemy" and current_enemy.cooldown <= 0 then -- 緑の敵の場合 (クールダウンチェック)
                    table.remove(bullet.bullets, i) -- ナイフを削除
                    table.remove(enemy.enemies, j) -- 元の緑の敵を削除
                    current_enemy.cooldown = 0.5 -- 0.5秒のクールダウンを設定
                    -- 緑の敵を分裂させる
                    table.insert(enemy.enemies, { x = current_enemy.x + 15, y = current_enemy.y, hp = 1, type = "plus_enemy", speed = enemies_data.plus_enemy.speed, cooldown = 0, level = 0 })
                    table.insert(enemy.enemies, { x = current_enemy.x - 15, y = current_enemy.y, hp = 1, type = "plus_enemy", speed = enemies_data.plus_enemy.speed, cooldown = 0, level = 0 })
                elseif current_enemy.type == "multiply_enemy" and current_enemy.cooldown <= 0 then -- ×敵の処理 (クールダウンチェック)
                    table.remove(bullet.bullets, i) -- 元の弾を削除
                    current_enemy.cooldown = 0.5 -- 0.5秒のクールダウンを設定
                    -- 斜め四方向に新しい弾を発射
                    local base_angle = math.pi / 4 -- 45度
                    for k=0, 3 do
                        table.insert(bullet.bullets, { x = current_enemy.x, y = current_enemy.y, angle = base_angle + (k * math.pi / 2), lifetime = 0.5 })
                    end
                elseif current_enemy.type == "divide_enemy" and current_enemy.cooldown <= 0 then -- ÷敵の処理 (クールダウンチェック)
                    table.remove(bullet.bullets, i) -- 元の弾を削除
                    current_enemy.cooldown = game_state.parameters.enemy_cooldown_time -- 司令塔からクールダウン時間を取得
                    -- 上下に新しい弾を分裂させる
                    table.insert(bullet.bullets, { x = current_enemy.x, y = current_enemy.y, angle = -math.pi / 2, lifetime = 0.5 }) -- 上方向
                    table.insert(bullet.bullets, { x = current_enemy.x, y = current_enemy.y, angle = math.pi / 2, lifetime = 0.5 }) -- 下方向
                end
                break -- 1つのナイフは1体の敵にしか当たらない
            end
        end
    end
end

function bullet.draw()
    -- ナイフの描画
    love.graphics.setColor(1, 1, 1, 1) -- 白に設定（弾の色は一旦白で統一）
    for i, current_bullet in ipairs(bullet.bullets) do
        love.graphics.rectangle("fill", current_bullet.x - 5, current_bullet.y - 5, 10, 10) -- ナイフを小さな四角で描画
    end
end

function bullet.reset()
    bullet.bullets = {}
    bullet_timer = 0
end

return bullet
