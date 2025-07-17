--[[
  MinusEnemy Class

  マイナス敵（青色）の具体的な振る舞いを定義するクラス。
  Enemyベースクラスを継承する。
]]

local utils = require("utils")
local Enemy = require("enemy_base") -- 親クラスを読み込む

local MinusEnemy = utils.class(Enemy) -- Enemyを継承

function MinusEnemy:init(x, y)
    -- 親クラスのコンストラクタを呼び出し、基本設定を行う
    Enemy.init(self, x, y, "minus_enemy")
    self.level = 1 -- マイナス敵はレベル1で開始
end

-- MinusEnemy独自の更新ロジック
function MinusEnemy:update(dt, player, all_enemies)
    -- まず親クラスの共通updateを呼び出す（無敵時間タイマーなど）
    Enemy.update(self, dt, player, all_enemies)

    -- プレイヤーを追跡する移動ロジック
    local angle = math.atan2(player.y - self.y, player.x - self.x)
    self.x = self.x + math.cos(angle) * self.speed * dt
    self.y = self.y + math.sin(angle) * self.speed * dt
end

-- MinusEnemy独自の描画ロジック
function MinusEnemy:draw()
    Enemy.draw(self) -- まず親クラスの共通描画（四角形と半透明処理）を呼び出す

    -- レベルの数値を上に表示する
    if self.level then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(tostring(self.level), self.x - 10, self.y - 12, 20, "center")
    end
end

return MinusEnemy
