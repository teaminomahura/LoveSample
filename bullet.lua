-- [重要方針] 既存の仕様を一切削除しない。以下は「未設定でも落ちないようにする防御追加」と
-- 「nil安全化（デフォルト値の採用）」のみ。従来の弾挙動・敵との相互作用は維持する。

local utils      = require("utils")
local enemies_data = require("config.enemies") -- 既存参照（未使用でも削除しない）
local game_state = require("game_state")

local bullet = {}

bullet.bullets = {}
local bullet_timer = 0

-- 安全にパラメータを取得（未設定なら既定値を使用）
local function get_params()
    local p = game_state and game_state.parameters or {}
    return {
        bullet_interval      = p.bullet_interval      or 0.8,  -- 弾の発射間隔(秒)
        bullet_speed         = p.bullet_speed         or 200,  -- 弾速(px/s)
        enemy_cooldown_time  = p.enemy_cooldown_time  or 0.5,  -- 敵側クールダウンの既定
    }
end

function bullet.update(dt, player, enemy)
    local params = get_params()

    -- ナイフの発射（全方位ランダム角度）
    bullet_timer = bullet_timer + dt
    if bullet_timer >= params.bullet_interval then
        table.insert(bullet.bullets, {
            x = player.x, y = player.y,
            angle = math.random() * math.pi * 2,
            lifetime = 0.5
        })
        bullet_timer = 0
    end

    -- ナイフの移動と寿命
    for i = #bullet.bullets, 1, -1 do
        local b = bullet.bullets[i]
        b.x = b.x + math.cos(b.angle) * params.bullet_speed * dt
        b.y = b.y + math.sin(b.angle) * params.bullet_speed * dt

        b.lifetime = b.lifetime - dt
        if b.lifetime <= 0 then
            table.remove(bullet.bullets, i)
        end
    end

    -- ナイフと敵の衝突判定（既存の相互作用を保持）
    for i = #bullet.bullets, 1, -1 do
        local b = bullet.bullets[i]
        for j = #enemy.enemies, 1, -1 do
            local e = enemy.enemies[j]
            if utils.checkCollision(b.x - 5, b.y - 5, 10, 10,
                                    e.x - 10, e.y - 10, 20, 20) then
                local cd = e.cooldown or 0  -- nil 安全化

                if e.type == "minus_enemy" then
                    -- －敵：弾ヒットで撃破＆XP+1
                    table.remove(bullet.bullets, i)
                    e.to_remove = true
                    player.xp = (player.xp or 0) + 1

                elseif e.type == "plus_enemy" and cd <= 0 then
                    -- ＋敵：弾ヒットで元個体は消え、左右に2体分裂
                    table.remove(bullet.bullets, i)
                    e.to_remove = true
                    enemy.create("plus_enemy", e.x + 15, e.y)
                    enemy.create("plus_enemy", e.x - 15, e.y)

                elseif e.type == "multiply_enemy" and cd <= 0 then
                    -- ×敵：弾ヒットで斜め4方向に弾を拡散、元弾は削除
                    table.remove(bullet.bullets, i)
                    e.cooldown = 0.5
                    local base_angle = math.pi / 4
                    for k = 0, 3 do
                        table.insert(bullet.bullets, {
                            x = e.x, y = e.y,
                            angle = base_angle + (k * math.pi / 2),
                            lifetime = 0.5
                        })
                    end

                elseif e.type == "divide_enemy" and cd <= 0 then
                    -- ÷敵：弾ヒットで上下2方向に弾を分裂、元弾は削除
                    table.remove(bullet.bullets, i)
                    e.cooldown = params.enemy_cooldown_time
                    table.insert(bullet.bullets, { x = e.x, y = e.y, angle = -math.pi / 2, lifetime = 0.5 })
                    table.insert(bullet.bullets, { x = e.x, y = e.y, angle =  math.pi / 2, lifetime = 0.5 })
                end

                -- 1発につき1体まで
                break
            end
        end
    end
end

function bullet.draw()
    -- ナイフの描画（白い小さな四角）
    love.graphics.setColor(1, 1, 1, 1)
    for _, b in ipairs(bullet.bullets) do
        love.graphics.rectangle("fill", b.x - 5, b.y - 5, 10, 10)
    end
end

function bullet.reset()
    bullet.bullets = {}
    bullet_timer = 0
end

return bullet
