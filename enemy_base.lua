local utils = require("utils")
local enemies_data = require("config.enemies")

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
    -- 各敵固有の移動ロジックやプレイヤーとの衝突判定は、派生クラスで実装される
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
    -- 各敵固有の描画（例：レベル表示）は、派生クラスで実装される
end

return Enemy
