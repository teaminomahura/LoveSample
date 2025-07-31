-- ======================================================================
-- !!! 既存の仕様を一切消さない追加層 !!!
-- data/character_loader.lua
-- ・ランク表とカタログから“実数値”を作る
-- ・game_state.parameters へ安全に注入
-- ・既存の Player インスタンスに反映（ある項目だけ存在すれば上書き）
-- ・move_speed に統一（互換として player.speed があれば同値を入れる）
-- ======================================================================

-- RANK テーブル（外部が無い場合でも動くようフォールバック）
local okRank, RANK = pcall(require, "data.stat_ranks")
if not okRank or not RANK then
  RANK = {
    max_hp = { S=30, A=25, B=20, C=15, D=12, E=10, F=8, X=50 },
    fire_cd = { S=0.60, A=0.70, B=0.80, C=1.00, D=1.20, E=1.40, F=1.60, X=0.40 },
    projectile_speed = { S=420, A=360, B=300, C=240, D=200, E=160, F=120, X=520 },
    range_px = { S=360, A=300, B=240, C=180, D=150, E=120, F=90, X=420 },
    bullet_ttl = { S=1.6, A=1.4, B=1.2, C=1.0, D=0.9, E=0.8, F=0.7, X=2.0 },
    move_speed = { S=180, A=160, B=140, C=120, D=110, E=100, F=90, X=200 },
    shots_per_hp = { S=14, A=12, B=10, C=10, D=8, E=7, F=6, X=16 },
    luck = { S=8, A=6, B=4, C=2, D=1, E=0, F=0, X=10 },
    invincible_time = { S=0.9, A=0.8, B=0.7, C=0.6, D=0.5, E=0.4, F=0.3, X=1.2 },
    revive = { S=2, A=1, B=1, C=0, D=0, E=0, F=0, X=3 },
  }
end

local CATALOG = require("data.player_catalog")

local M = {}

-- ランク文字→数値
local function pick(tableByRank, rankLetter)
  if not rankLetter then return nil end
  return tableByRank[rankLetter]
end

-- カタログ → 実数パラメータ化
local function materialize_params(cat_entry)
  local rk = cat_entry.ranks or {}
  local p = {
    max_hp           = (cat_entry.overrides and cat_entry.overrides.max_hp)           or pick(RANK.max_hp, rk.max_hp),
    fire_cd          = (cat_entry.overrides and cat_entry.overrides.fire_cd)          or pick(RANK.fire_cd, rk.fire_cd),
    projectile_speed = (cat_entry.overrides and cat_entry.overrides.projectile_speed) or pick(RANK.projectile_speed, rk.projectile_speed),
    range_px         = (cat_entry.overrides and cat_entry.overrides.range_px)         or pick(RANK.range_px, rk.range),
    bullet_ttl       = (cat_entry.overrides and cat_entry.overrides.bullet_ttl)       or pick(RANK.bullet_ttl, rk.range),
    move_speed       = (cat_entry.overrides and cat_entry.overrides.move_speed)       or pick(RANK.move_speed, rk.move_speed),
    shots_per_hp     = (cat_entry.overrides and cat_entry.overrides.shots_per_hp)     or pick(RANK.shots_per_hp, rk.shots_per_hp),
    luck             = (cat_entry.overrides and cat_entry.overrides.luck)             or pick(RANK.luck, rk.luck),
    invincible_time  = (cat_entry.overrides and cat_entry.overrides.invincible_time)  or pick(RANK.invincible_time, rk.invincible_time),
    revive           = (cat_entry.overrides and cat_entry.overrides.revive)           or pick(RANK.revive, rk.revive),
  }

  -- Cランク既定へフォールバック（“欠け”を埋める）
  local fallback = CATALOG.get("standard")
  local rf = fallback.ranks
  p.max_hp           = p.max_hp           or RANK.max_hp[rf.max_hp]
  p.fire_cd          = p.fire_cd          or RANK.fire_cd[rf.fire_cd]
  p.projectile_speed = p.projectile_speed or RANK.projectile_speed[rf.projectile_speed]
  p.range_px         = p.range_px         or RANK.range_px[rf.range]
  p.bullet_ttl       = p.bullet_ttl       or RANK.bullet_ttl[rf.range]
  p.move_speed       = p.move_speed       or RANK.move_speed[rf.move_speed]
  p.shots_per_hp     = p.shots_per_hp     or RANK.shots_per_hp[rf.shots_per_hp]
  p.luck             = p.luck             or RANK.luck[rf.luck]
  p.invincible_time  = p.invincible_time  or RANK.invincible_time[rf.invincible_time]
  p.revive           = p.revive           or RANK.revive[rf.revive]

  return p
end

-- game_state.parameters に安全注入（既存キーは保持しつつ不足分だけ埋める）
local function inject_to_game_state(params)
  local game_state = require("game_state")
  game_state.parameters = game_state.parameters or {}

  local P = game_state.parameters
  P.max_hp           = P.max_hp           or params.max_hp
  P.fire_cd          = P.fire_cd          or params.fire_cd
  P.projectile_speed = P.projectile_speed or params.projectile_speed
  P.projectile_range = P.projectile_range or params.range_px
  P.bullet_ttl       = P.bullet_ttl       or params.bullet_ttl
  P.move_speed       = P.move_speed       or params.move_speed
  P.hp_shot_cost     = P.hp_shot_cost     or params.shots_per_hp
  P.luck             = P.luck             or params.luck
  P.invincible_time  = P.invincible_time  or params.invincible_time
  P.revive           = P.revive           or params.revive

  -- 既定：毎Lvで最大HP+1 の共通ルール（既にあるなら触らない）
  P.lvup_maxhp_plus  = (P.lvup_maxhp_plus ~= nil) and P.lvup_maxhp_plus or 1
end

-- 既存 Player インスタンスへ“存在する項目だけ”上書き
local function apply_to_player_instance(player, params)
  if not player then return end
  -- 体力
  if player.max_hp ~= nil then player.max_hp = params.max_hp end
  if player.hp     ~= nil then player.hp     = math.min(player.hp or params.max_hp, params.max_hp) end

  -- 可動
  if player.move_speed      ~= nil then player.move_speed      = params.move_speed end
  if player.speed           ~= nil then player.speed           = params.move_speed end -- ★ 互換（speed→move_speed統一）
  if player.invincible_time ~= nil then player.invincible_time = params.invincible_time end

  -- 射撃系
  if player.fire_cooldown ~= nil then player.fire_cooldown = params.fire_cd end
  if player.shots_per_hp  ~= nil then player.shots_per_hp  = params.shots_per_hp end
  if player.luck          ~= nil then player.luck          = params.luck end
end

-- 公開API：キャラIDを選択して各所に反映
local M = {}
function M.select_character(character_id, player_instance)
  local entry, resolved_id = CATALOG.get(character_id)
  entry.overrides = entry.overrides or {}

  local params = materialize_params(entry)
  inject_to_game_state(params)
  apply_to_player_instance(player_instance, params)

  return params, resolved_id, entry.display_name or resolved_id
end

return M

