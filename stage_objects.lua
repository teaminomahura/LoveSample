-- ======================================================================
-- !!! 既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- stage_objects.lua : ステージ・オブジェクト（2つ）
-- ① 回復池：円の中に 3 秒いると HP+1（hp/max_hp がある場合）
-- ② 減速床：矩形の上は移動速度 0.7 倍（出入りで復帰）。player.speed も同期。
-- 描画は「世界座標」前提：main.lua 側で camera.set_world_transform 中に呼ばれます。
-- ======================================================================

local M = {
  heal = { x = -120, y = -60, r = 90, t = 0, interval = 3.0 },
  slow = { x = 200, y = -80, w = 240, h = 160, inside = false },
}

function M.init()
  M.heal.t = 0
  M.slow.inside = false
end

local function point_in_circle(px, py, cx, cy, r)
  local dx, dy = px - cx, py - cy
  return (dx*dx + dy*dy) <= (r*r)
end

local function point_in_rect(px, py, rx, ry, rw, rh)
  return (px >= rx) and (px <= rx + rw) and (py >= ry) and (py <= ry + rh)
end

function M.update(dt, player, gs)
  if not player then return end

  -- ① 回復池：3秒滞在で +1
  if point_in_circle(player.x or 0, player.y or 0, M.heal.x, M.heal.y, M.heal.r) then
    M.heal.t = M.heal.t + dt
    if M.heal.t >= M.heal.interval then
      M.heal.t = M.heal.t - M.heal.interval
      if player.hp ~= nil then
        if player.max_hp ~= nil then
          player.hp = math.min(player.hp + 1, player.max_hp)
        else
          player.hp = player.hp + 1
        end
      end
    end
  else
    M.heal.t = 0
  end

  -- ② 減速床：入っている間だけ 0.7 倍、出たら戻す
  local inside = point_in_rect(player.x or 0, player.y or 0, M.slow.x, M.slow.y, M.slow.w, M.slow.h)
  if inside then
    local base = (gs and gs.parameters and gs.parameters.move_speed) or player.move_speed or 120
    local newv = math.max(1, math.floor(base * 0.7 + 0.5))
    if player.move_speed ~= newv then
      player.move_speed = newv
      if player.speed ~= nil then player.speed = player.move_speed end
    end
  else
    local back = (gs and gs.parameters and gs.parameters.move_speed) or player.move_speed or 120
    if player.move_speed ~= back then
      player.move_speed = back
      if player.speed ~= nil then player.speed = player.move_speed end
    end
  end
  M.slow.inside = inside
end

function M.draw()
  -- ここは「世界座標」で描く（main.lua がカメラを適用して呼び出す）
  -- 回復池（薄い水色）
  love.graphics.setColor(0.7, 0.85, 1.0, 0.25)
  love.graphics.circle("fill", M.heal.x, M.heal.y, M.heal.r)
  love.graphics.setColor(0.7, 0.85, 1.0, 0.9)
  love.graphics.circle("line", M.heal.x, M.heal.y, M.heal.r)

  -- 減速床（薄い紫）
  love.graphics.setColor(0.7, 0.6, 0.9, 0.20)
  love.graphics.rectangle("fill", M.slow.x, M.slow.y, M.slow.w, M.slow.h)
  love.graphics.setColor(0.7, 0.6, 0.9, 0.9)
  love.graphics.rectangle("line", M.slow.x, M.slow.y, M.slow.w, M.slow.h)
end

return M

