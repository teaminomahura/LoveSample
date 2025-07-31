-- =====================================================================
-- 【重要】このファイルは「既存の仕様を絶対に消さない」方針で作られています。
-- 既存の enemy.enemies 配列・update/draw/reset の呼ばれ方を維持しつつ、
-- －/＋のスポーン比率を外部から編集できる API（get/set）と
-- 安全なスポナーを追加しています。
-- =====================================================================

local enemy = {}

-- 既存仕様：弾や他モジュールが参照する配列（変更しない）
enemy.enemies = {}

-- 内部：スポーン制御
local spawn_timer = 0
local SPAWN_INTERVAL = 2.0  -- 2秒ごとに1体（必要に応じて調整）

-- －/＋の“重み（チケット）” 例：minus=4, plus=6 → 60%で＋、40%で－
local spawn_weights = { minus = 4, plus = 6 }

-- 外部から取得/設定できるAPI（ポーズUI用）
function enemy.get_spawn_weights()
  return spawn_weights.minus, spawn_weights.plus
end

function enemy.set_spawn_weights(minus_weight, plus_weight)
  -- 0以上の整数に丸め、安全策として 0,0 は 1,1 に
  local function clamp_nonneg_int(n, default)
    n = tonumber(n) or default
    n = math.floor(n + 0.5)
    if n < 0 then n = 0 end
    return n
  end
  local m = clamp_nonneg_int(minus_weight, 1)
  local p = clamp_nonneg_int(plus_weight , 1)
  if (m + p) == 0 then m, p = 1, 1 end
  spawn_weights.minus, spawn_weights.plus = m, p
end

-- 敵を1体スポーン
local function spawn_one(kind, x, y)
  local e = {
    type   = kind,      -- 弾側が参照する可能性に配慮
    kind   = kind,      -- 念のため両方用意
    x      = x or love.graphics.getWidth()/2,
    y      = y or love.graphics.getHeight()/2,
    w      = 20,  h = 20,
    speed  = (kind == "minus") and 60 or 40,
    color  = (kind == "minus") and {0.2, 0.6, 1.0} or {0.2, 1.0, 0.2},
    level  = 1,   -- 既存弾ロジックが参照しても落ちないよう最低限の項目を用意
    hp     = 1,
    to_remove = false,
  }
  table.insert(enemy.enemies, e)
end

-- 安全な辺生成：画面外から出す
local function random_spawn_pos()
  local side = love.math.random(4)
  if side == 1 then
    return love.math.random(love.graphics.getWidth()), -24
  elseif side == 2 then
    return love.math.random(love.graphics.getWidth()), love.graphics.getHeight() + 24
  elseif side == 3 then
    return -24, love.math.random(love.graphics.getHeight())
  else
    return love.graphics.getWidth() + 24, love.math.random(love.graphics.getHeight())
  end
end

-- 外部向け：現在数を返す（HUDで使用）
function enemy.count()
  return #enemy.enemies
end

-- 既存：リセット
function enemy.reset()
  enemy.enemies = {}
  spawn_timer = 0
end

-- 既存：更新（プレイヤー追尾＋一定間隔スポーン）
function enemy.update(dt, player)
  -- 追尾
  for i = #enemy.enemies, 1, -1 do
    local e = enemy.enemies[i]
    local ang = math.atan2((player.y or 0) - e.y, (player.x or 0) - e.x)
    e.x = e.x + math.cos(ang) * e.speed * dt
    e.y = e.y + math.sin(ang) * e.speed * dt
    if e.to_remove then table.remove(enemy.enemies, i) end
  end

  -- スポーン（PLAYING 中のみ呼ばれる想定：main.lua 側で制御済み）
  spawn_timer = spawn_timer + dt
  if spawn_timer >= SPAWN_INTERVAL then
    spawn_timer = spawn_timer - SPAWN_INTERVAL

    -- 重み抽選
    local m, p = spawn_weights.minus, spawn_weights.plus
    local total = math.max(1, (m or 0) + (p or 0))
    local r = love.math.random(total)
    local kind = (r <= (m or 0)) and "minus" or "plus"

    local sx, sy = random_spawn_pos()
    spawn_one(kind, sx, sy)
  end
end

-- 既存：描画
function enemy.draw()
  for _, e in ipairs(enemy.enemies) do
    love.graphics.setColor(e.color[1], e.color[2], e.color[3], 1)
    love.graphics.rectangle("fill", e.x - e.w/2, e.y - e.h/2, e.w, e.h)
  end
  love.graphics.setColor(1,1,1,1)
end

return enemy








