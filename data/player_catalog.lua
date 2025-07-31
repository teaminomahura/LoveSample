-- ======================================================================
-- !!! 既存の仕様を一切消さない追加層 !!!
-- data/player_catalog.lua
-- 各キャラクターの“初期ランク（S～F, X）”定義。
-- 2体：standard（標準） / swift（勝手に経験値君：全F）
-- 見つからないIDは 'standard' にフォールバック。
-- ======================================================================

local CATALOG = {
  -- ID: "standard"（スタンダード君）
  standard = {
    display_name = "スタンダード君",
    ranks = {
      max_hp = "C",
      fire_cd = "C",
      projectile_speed = "C",
      range = "C",   -- 射程/寿命の基準
      move_speed = "C",
      shots_per_hp = "C",
      luck = "C",
      invincible_time = "C",
      revive = "C",
    },
    overrides = {
      -- 特記なし（基準型）
    }
  },

  -- ID: "swift"（★ 勝手に経験値君：各能力 F）
  swift = {
    display_name = "勝手に経験値君",
    ranks = {
      max_hp = "F",
      fire_cd = "F",
      projectile_speed = "F",
      range = "F",
      move_speed = "F",
      shots_per_hp = "F",
      luck = "F",
      invincible_time = "F",
      revive = "F",
    },
    overrides = {
      -- 個別数値は未指定（ランクFの値を使用）
    }
  },
}

-- 見つからないIDは standard にフォールバック
function CATALOG.get(id)
  if id and CATALOG[id] then return CATALOG[id], id end
  return CATALOG["standard"], "standard"
end

return CATALOG


