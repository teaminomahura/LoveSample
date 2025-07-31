-- 最重要方針：既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- config/upgrades.lua（データ定義）
-- 2択（プラス効果）：移動 +10%／発射クールダウン -10%

local M = {}

M.common = {
  {
    id = "MOVE_SPEED_PLUS10",
    title = "移動 +10%",
    desc  = "移動速度が 10% 上がります。",
    apply_effect = function(player, gs)
      if player and player.move_speed then
        player.move_speed = math.floor(player.move_speed * 1.10 + 0.5)
        if player.speed ~= nil then player.speed = player.move_speed end
      end
      if gs and gs.parameters then
        local cur = gs.parameters.move_speed or (player and player.move_speed) or 120
        gs.parameters.move_speed = math.floor(cur * 1.10 + 0.5)
      end
    end
  },
  {
    id = "COOLDOWN_MINUS10",
    title = "発射クールダウン -10%",
    desc  = "弾の間隔が 少し短くなります。",
    apply_effect = function(player, gs)
      if gs and gs.parameters then
        local cd = gs.parameters.fire_cd or (player and player.fire_cooldown) or 1.0
        gs.parameters.fire_cd = cd * 0.90
      end
      if player and player.fire_cooldown then
        player.fire_cooldown = player.fire_cooldown * 0.90
      end
    end
  },
}

M.rare = {
  -- いまは空。将来ここにレア効果を追加。
}

return M


