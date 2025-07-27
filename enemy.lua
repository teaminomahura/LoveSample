-- enemy.lua ーー 既存仕様を壊さない最小構成
-- ・青(−)と緑(＋)をスポーン
-- ・出現率の取得/設定API（pause中のUIから使える）
-- ・HUD用に enemy.count() を提供
-- ・既存の bullet.lua が参照するであろうフィールド:
--    e.type ("minus"/"plus"), e.x, e.y, e.w, e.h, e.level などを保持

local enemy = {}

enemy.enemies = {}

-- 生成タイマー
local spawn_timer = 0
local SPAWN_INTERVAL = 2.5 -- 秒

-- 出現率（合計1.0に正規化されます）
local weights = { minus = 0.6, plus = 0.4 }

--=== 公開API：出現率の取得/設定 =========================================
function enemy.get_spawn_weights()
  -- 呼び出し側で編集しないようコピーを返す
  return { minus = weights.minus, plus = weights.plus }
end

function enemy.set_spawn_weights(minus_w, plus_w)
  local m = tonumber(minus_w) or weights.minus
  local p = tonumber(plus_w) or weights.plus
  local sum = m + p
  if sum <= 0 then m, p, sum = 1, 1, 2 end
  weights.minus, weights.plus = m / sum, p / sum
end

-- HUD 用：敵の総数
function enemy.count()
  return #enemy.enemies
end

-- リスタート時など
function enemy.reset()
  enemy.enemies = {}
  spawn_timer = 0
end

--=== 内部：ユーティリティ ==============================================
local function new_enemy(kind, x, y)
  local e = {
    type  = kind,      -- "minus" / "plus" （bullet.lua想定の名称）
    kind  = kind,      -- 互換のため同値も入れておく
    x     = x, y = y,
    w     = 18, h = 18,
    speed = (kind == "minus") and 60 or 50,
    color = (kind == "minus") and {0.2, 0.6, 1.0} or {0.3, 0.9, 0.3},
    level = 1,         -- 将来の −Lv/＋Lv 用にダミー値を保持
    inv   = 0.2,       -- 生成直後の安全時間（描画アルファを下げる）
  }
  table.insert(enemy.enemies, e)
  return e
end

local function pick_kind()
  local r = love.math.random()
  return (r < weights.minus) and "minus" or "plus"
end

--=== 更新・描画 =========================================================
function enemy.update(dt, player)
  -- スポーン
  spawn_timer = spawn_timer + dt
  if spawn_timer >= SPAWN_INTERVAL then
    spawn_timer = spawn_timer - SPAWN_INTERVAL

    local W, H = love.graphics.getWidth(), love.graphics.getHeight()
    local side = love.math.random(4)
    local x, y
    if side == 1 then
      x, y = love.math.random(W), -20           -- 上
    elseif side == 2 then
      x, y = love.math.random(W), H + 20        -- 下
    elseif side == 3 then
      x, y = -20, love.math.random(H)           -- 左
    else
      x, y = W + 20, love.math.random(H)        -- 右
    end

    new_enemy(pick_kind(), x, y)
  end

  -- 挙動
  for i = #enemy.enemies, 1, -1 do
    local e = enemy.enemies[i]
    if e.inv > 0 then e.inv = e.inv - dt end

    if e.type == "minus" then
      -- −敵：プレイヤー追尾
      local dx, dy = player.x - e.x, player.y - e.y
      local len = (dx*dx + dy*dy)^0.5
      if len > 0 then
        e.x = e.x + dx/len * e.speed * dt
        e.y = e.y + dy/len * e.speed * dt
      end

    elseif e.type == "plus" then
      -- ＋敵：最も近い −敵へ、いなければプレイヤーへ
      local tx, ty, bestd2
      for _, t in ipairs(enemy.enemies) do
        if t ~= e and t.type == "minus" then
          local dx, dy = t.x - e.x, t.y - e.y
          local d2 = dx*dx + dy*dy
          if not bestd2 or d2 < bestd2 then
            bestd2 = d2; tx = t.x; ty = t.y
          end
        end
      end
      tx, ty = tx or player.x, ty or player.y
      local dx, dy = tx - e.x, ty - e.y
      local len = (dx*dx + dy*dy)^0.5
      if len > 0 then
        e.x = e.x + dx/len * e.speed * dt
        e.y = e.y + dy/len * e.speed * dt
      end
    end
  end
end

function enemy.draw()
  for _, e in ipairs(enemy.enemies) do
    local a = (e.inv > 0) and 0.6 or 1.0
    love.graphics.setColor(e.color[1], e.color[2], e.color[3], a)
    love.graphics.rectangle("fill", e.x - e.w/2, e.y - e.h/2, e.w, e.h)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

return enemy







