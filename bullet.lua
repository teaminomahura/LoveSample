local utils = require("utils")

local bullet = {}

bullet.bullets = {}
local bullet_speed = 500
bullet.bullet_interval = 0.5 -- 0.5秒ごとにナイフを発射
local bullet_timer = 0

function bullet.update(dt, player, enemy)
    -- ナイフの発射
    bullet_timer = bullet_timer + dt
    if bullet_timer >= bullet.bullet_interval then
        table.insert(bullet.bullets, { x = player.x, y = player.y, angle = math.random() * math.pi * 2, lifetime = 0.5 }) -- 全方向に発射、寿命0.5秒
        bullet_timer = 0
    end

    -- ナイフの移動と画面外での消滅
    for i = #bullet.bullets, 1, -1 do
        local current_bullet = bullet.bullets[i]
        current_bullet.x = current_bullet.x + math.cos(current_bullet.angle) * bullet_speed * dt
        current_bullet.y = current_bullet.y + math.sin(current_bullet.angle) * bullet_speed * dt

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
                -- ナイフはプラス属性なので、マイナス属性の敵を倒し、プラス属性の敵は消滅させる
                if current_enemy.type == "minus" then
                    table.remove(bullet.bullets, i) -- ナイフを削除
                    table.remove(enemy.enemies, j) -- 敵を削除
                    player.xp = player.xp + 1 -- 経験値獲得
                    if player.xp >= player.xp_to_next_level then
                        -- レベルアップは game_state で処理するため、ここでは経験値の加算のみ
                        player.xp = player.xp + 1
                    end
                else -- current_enemy.type == "plus"
                    table.remove(bullet.bullets, i) -- ナイフを削除
                    table.remove(enemy.enemies, j) -- 元の緑の敵を削除
                    -- 緑の敵を分裂させる
                    table.insert(enemy.enemies, { x = current_enemy.x + 15, y = current_enemy.y, hp = 1, type = "plus" })
                    table.insert(enemy.enemies, { x = current_enemy.x - 15, y = current_enemy.y, hp = 1, type = "plus" })
                    -- 経験値は入らない
                end
                break -- 1つのナイフは1体の敵にしか当たらない
            end
        end
    end
end

function bullet.draw()
    -- ナイフの描画
    love.graphics.setColor(1, 0, 0, 1) -- 赤に設定
    for i, current_bullet in ipairs(bullet.bullets) do
        love.graphics.rectangle("fill", current_bullet.x - 5, current_bullet.y - 5, 10, 10) -- ナイフを小さな四角で描画
    end
end

function bullet.reset()
    bullet.bullets = {}
    bullet_timer = 0
end

return bullet
