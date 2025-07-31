-- ============================================================================
-- 🚫 このファイルでは**最重要方針：既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!🚫
-- ============================================================================
-- game_state.lua  (safe superset / append-only style)
-- 目的: 以前のコードが前提にしていた値や関数を“すべて”用意し、nilで落ちないようにする。
--       ・ステート管理（PLAYING/PAUSED/GAME_OVER/LEVEL_UP_CHOICE）
--       ・ゲーム共通パラメータ（parameters） … bullet.lua などが参照
--       ・タイマー（ゲーム経過、カース/逆転の次回発生）
--       ・安全な update/draw API（main.lua が呼ぶ）
--       ※本ファイルは「既存仕様の土台」を維持しつつ、将来の拡張を受け入れる“器”です。
-- ============================================================================

local game_state = {}

-- -------------------------------
-- 1) ステート定義
-- -------------------------------
game_state.states = {
  PLAYING          = 1,
  PAUSED           = 2,
  GAME_OVER        = 3,
  LEVEL_UP_CHOICE  = 4,
}

game_state.current_state = game_state.states.PLAYING

-- -------------------------------
-- 2) 共通パラメータ（他モジュールが参照）
--    ※値は“既存仕様の想定”を満たす無難なデフォルト
-- -------------------------------
game_state.parameters = {
  -- プレイヤー関連（初期系）
  player = {
    base_max_hp        = 10,      -- 全キャラ既定の初期最大HP
    base_move_speed    = 120,     -- px/s
    invincible_time    = 0.6,     -- 被弾後の無敵時間
    shot_cost_per_n    = 10,      -- 弾をN発撃つごとにHP-1
  },

  -- 弾関連（bullet.lua が参照する想定）
  bullet = {
    speed              = 240,     -- 弾速(px/s)
    ttl                = 1.2,     -- 弾の寿命(秒)
    base_cooldown      = 1.0,     -- 発射CD(秒)
  },

  -- スポーン比率（敵の種類の重み：とりあえず青/緑のみ）
  spawn = {
    minus_weight       = 4,       -- 青（-）
    plus_weight        = 4,       -- 緑（+）
    mult_weight        = 1,       -- 赤（×）将来用
    div_weight         = 1,       -- 紫（÷）将来用
  },

  -- 周期イベント
  timer = {
    curse_period_sec   = 60,      -- カース周期（基準）
    reverse_period_sec = 180,     -- 逆転周期（基準）
  },
}

-- -------------------------------
-- 3) ランタイム状態（毎回リセットされる）
-- -------------------------------
local runtime = {
  time_sec          = 0,      -- 経過時間
  next_curse_sec    = nil,    -- 次カース発生予定時刻
  next_reverse_sec  = nil,    -- 次逆転発生予定時刻
}

-- -------------------------------
-- 4) セーフ初期化
-- -------------------------------
function game_state.reset_parameters()
  -- ここで“安全に”全てを初期化（nil比較で落ちないように）
  runtime.time_sec         = 0
  runtime.next_curse_sec   = game_state.parameters.timer.curse_period_sec or 60
  runtime.next_reverse_sec = game_state.parameters.timer.reverse_period_sec or 180

  -- 追加のゲーム内進行度などがあれば、ここで初期化しておく
  -- （例）スコア、ウェーブ、ボスフラグ等…将来の追記領域
end

-- 起動時に一応初期化しておく（呼び出し忘れの保険）
game_state.reset_parameters()

-- -------------------------------
-- 5) 補助：安全な min/max（nil 防止）
-- -------------------------------
local function safe_num(v, fallback) return (type(v) == "number") and v or fallback end

-- -------------------------------
-- 6) メイン更新（main.lua から毎フレーム呼ばれる）
--    ここでは“状態の更新・判定のみ”を行い、描画/入力は他に委譲。
-- -------------------------------
function game_state.update(dt, player, bullet, upgrade)
  -- ポーズやレベルアップ画面では進行しない（ただし描画は main 側）
  if game_state.current_state == game_state.states.PAUSED
     or game_state.current_state == game_state.states.LEVEL_UP_CHOICE
     or game_state.current_state == game_state.states.GAME_OVER then
    return
  end

  -- 経過時間
  runtime.time_sec = runtime.time_sec + safe_num(dt, 0)

  -- プレイヤー死亡 → GAME_OVER
  if player and player.hp and player.hp <= 0 then
    game_state.current_state = game_state.states.GAME_OVER
    return
  end

  -- 周期イベント（※本実装では“フラグ・通知だけ”を行う、詳細処理は将来追記）
  local t = runtime.time_sec
  local nextC   = safe_num(runtime.next_curse_sec,   60)
  local nextRev = safe_num(runtime.next_reverse_sec, 180)

  if t >= nextC then
    -- TODO: カース選択画面へ遷移 or カースイベント発火（将来追記）
    -- 今は次回時刻だけ更新してスキップ
    runtime.next_curse_sec = t + safe_num(game_state.parameters.timer.curse_period_sec, 60)
  end

  if t >= nextRev then
    -- TODO: 逆転現象のトグル（将来追記）
    runtime.next_reverse_sec = t + safe_num(game_state.parameters.timer.reverse_period_sec, 180)
  end

  -- レベルアップ検知（シンプルな条件、詳細は upgrade.lua に委譲）
  if player and player.xp and player.xp_to_next_level
     and player.xp >= player.xp_to_next_level then
    -- ここでは状態遷移のみ（UIは main.lua 側で upgrade.draw() を呼ぶ）
    game_state.current_state = game_state.states.LEVEL_UP_CHOICE
  end
end

-- -------------------------------
-- 7) オーバーレイ描画（ポーズ/ゲームオーバーなど）
--    ※ HUD は main.lua で描く想定、ここは状態メッセージ中心
-- -------------------------------
function game_state.draw()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()

  if game_state.current_state == game_state.states.PAUSED then
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("PAUSED  (Pで再開)", 0, h*0.45, w, "center")

  elseif game_state.current_state == game_state.states.GAME_OVER then
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1,0.2,0.2,1)
    love.graphics.printf("GAME OVER  (Rで再スタート)", 0, h*0.45, w, "center")

  elseif game_state.current_state == game_state.states.LEVEL_UP_CHOICE then
    -- レベルアップ選択中の背景薄暗
    love.graphics.setColor(0,0,0,0.35)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("レベルアップ！ 選択肢を選んでください。", 0, 20, w, "center")
  end

  -- デバッグ: 右上に時間と次回イベント予定
  love.graphics.setColor(1,1,1,0.9)
  local debug_y = 10
  local function dbg(s) love.graphics.print(s, w-280, debug_y); debug_y = debug_y + 18 end
  dbg(("Time: %.1fs"):format(safe_num(runtime.time_sec, 0)))
  dbg(("Next Curse: %.1fs"):format(safe_num(runtime.next_curse_sec, 0)))
  dbg(("Next Reverse: %.1fs"):format(safe_num(runtime.next_reverse_sec, 0)))
end

-- -------------------------------
-- 8) 外部から参照/操作するための補助関数
-- -------------------------------

-- 現在のスポーン重みセット（enemy.lua から参照されてもOK）
function game_state.get_spawn_weights()
  local s = game_state.parameters.spawn
  return safe_num(s.minus_weight, 4),
         safe_num(s.plus_weight,  4),
         safe_num(s.mult_weight,  1),
         safe_num(s.div_weight,   1)
end

-- スポーン重みの設定（UIやテスト入力から呼べる）
function game_state.set_spawn_weights(minus_w, plus_w, mult_w, div_w)
  local s = game_state.parameters.spawn
  s.minus_weight = math.max(0, math.floor(tonumber(minus_w) or s.minus_weight or 4))
  s.plus_weight  = math.max(0, math.floor(tonumber(plus_w)  or s.plus_weight  or 4))
  s.mult_weight  = math.max(0, math.floor(tonumber(mult_w)  or s.mult_weight  or 1))
  s.div_weight   = math.max(0, math.floor(tonumber(div_w)   or s.div_weight   or 1))
end

-- 現在の経過時間（必要なら他モジュールで利用）
function game_state.get_time_sec()
  return safe_num(runtime.time_sec, 0)
end

-- 次回イベント予定（デバッグ用）
function game_state.get_next_curse_sec()   return safe_num(runtime.next_curse_sec,   0) end
function game_state.get_next_reverse_sec() return safe_num(runtime.next_reverse_sec, 0) end

return game_state


