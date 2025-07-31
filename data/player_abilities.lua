-- ======================================================================
-- !!! 最重要方針：既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- data/player_abilities.lua
-- 目的：キャラクター固有の“パッシブ/能力”をここで定義し、main.lua から
-- init()/update() を呼ぶだけにする。将来34キャラまで増やしても拡張しやすい。
--
-- いま実装：ID "swift" = 「勝手に経験値君」
--   ・各能力ランクF（定義は player_catalog.lua 側）
--   ・5秒ごとに経験値 +1 を自動獲得
--   ・xp_to_next_level が未定義なら 5 を入れる
--   ・★ 閾値に達したら「レベルアップUIを開いてほしい」というリクエストを立てる
--      （実際のUIオープンは main.lua が行う）
-- ======================================================================

local Ab = {}
Ab.current_id      = nil
Ab.t_accum         = 0        -- 経過タイマー（秒）
Ab.xp_interval     = 5.0      -- 5秒ごとに +1
Ab._want_levelupUI = false    -- UIオープン要求フラグ

function Ab.init(character_id, player, gs)
  Ab.current_id = character_id
  Ab.t_accum = 0
  Ab._want_levelupUI = false

  if player then
    player.xp = player.xp or 0
    player.level = player.level or 1
    if player.xp_to_next_level == nil then
      player.xp_to_next_level = 5
    end
  end
end

function Ab.update(dt, player, gs)
  if not Ab.current_id or not player then return end

  -- 勝手に経験値君（IDは "swift" のまま、表示名だけ変更）
  if Ab.current_id == "swift" then
    -- 自動でXP獲得
    Ab.t_accum = Ab.t_accum + dt
    if Ab.t_accum >= Ab.xp_interval then
      Ab.t_accum = Ab.t_accum - Ab.xp_interval
      player.xp = (player.xp or 0) + 1
    end

    -- レベルアップ判定（UIオープン要求を出すだけ）
    local need = player.xp_to_next_level or 5
    if (player.xp or 0) >= need and not Ab._want_levelupUI then
      -- 多重発火防止のため、この時点で消費・レベル更新まで済ませる
      player.xp = (player.xp or 0) - need
      player.level = (player.level or 1) + 1
      player.xp_to_next_level = need -- テスト用：固定のまま

      Ab._want_levelupUI = true
    end
  end
end

-- ★ main.lua がポーリングする用：true を返したらフラグを落とす
function Ab.poll_levelup_request()
  if Ab._want_levelupUI then
    Ab._want_levelupUI = false
    return true
  end
  return false
end

return Ab


