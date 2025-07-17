-- Phase0 Enemy Hotfix: 敵なし起動用
-- リファクタ作業中の一時ダミー。敵は出ません。

local enemy = {}
enemy.enemies = {}

function enemy.create(type, x, y, level_override)
    -- 何もしない
end

function enemy.update(dt, player)
    -- 何もしない
end

function enemy.draw()
    -- 何もしない
end

function enemy.reset()
    enemy.enemies = {}
end

return enemy
