-- ======================================================================
-- !!! 最重要方針：既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- controller.lua : 入力の一本化（キーボード＋ゲームパッド）
-- 目的：
--   ・移動：左スティック/十字キー → 仮想的に WASD/矢印 を押下状態にする
--   ・ボタン：main.lua 側で gamepadpressed をキー相当にフォワードする
-- 提供API：
--   controller.init()
--   controller.update(dt)               -- 毎フレーム更新（仮想キー更新）
--   controller.hook_keyboard_isDown()   -- love.keyboard.isDown を仮想キー対応に差し替え
--   controller.get_move_axis() -> dx,dy -- 参考用（必要なら）
-- 備考：
--   ・既存コードは love.keyboard.isDown('w','a','s','d') 等を使い続けられます。
--   ・このモジュールが、ゲームパッドの入力を「仮想的なキー押下」に変換します。
-- ======================================================================

local M = {}

-- 仮想キー押下状態（isDown で参照される）
local vkeys = {
  w=false, a=false, s=false, d=false,
  up=false, down=false, left=false, right=false
}

-- 元の isDown を保持
local _orig_isDown = nil

-- 左スティックの状態キャッシュ
local last_lx, last_ly = 0, 0
local deadzone = 0.25

function M.init()
  -- 何もしない（将来、複数パッド管理に拡張可）
end

function M.hook_keyboard_isDown()
  if _orig_isDown then return end
  _orig_isDown = love.keyboard.isDown
  love.keyboard.isDown = function(...)
    local args = {...}
    for i=1,#args do
      local k = args[i]
      if _orig_isDown(k) then return true end
      if vkeys[k] then return true end
    end
    return false
  end
end

-- 便宜：現在の移動ベクトル（正規化まではしない）
function M.get_move_axis()
  local dx = (vkeys.right and 1 or 0) - (vkeys.left and 1 or 0)
  local dy = (vkeys.down  and 1 or 0) - (vkeys.up   and 1 or 0)
  if dx==0 and dy==0 then
    dx = (vkeys.d and 1 or 0) - (vkeys.a and 1 or 0)
    dy = (vkeys.s and 1 or 0) - (vkeys.w and 1 or 0)
  end
  return dx, dy
end

-- 内部：仮想キーのセット
local function set_vkey(name, flag)
  if vkeys[name] ~= flag then
    vkeys[name] = flag
  end
end

-- D-Pad を反映
local function apply_dpad(js)
  local up    = js:isGamepadDown("dpup")
  local down  = js:isGamepadDown("dpdown")
  local left  = js:isGamepadDown("dpleft")
  local right = js:isGamepadDown("dpright")

  set_vkey("up",    up);    set_vkey("w", up)
  set_vkey("down",  down);  set_vkey("s", down)
  set_vkey("left",  left);  set_vkey("a", left)
  set_vkey("right", right); set_vkey("d", right)
end

function M.update(dt)
  -- すべての仮想キーをいったん false（後段で必要分を true）
  for k in pairs(vkeys) do vkeys[k] = false end

  local joysticks = love.joystick.getJoysticks()
  local js = joysticks and joysticks[1] or nil
  if js and js:isGamepad() then
    -- 左スティック
    local lx = js:getGamepadAxis("leftx") or 0
    local ly = js:getGamepadAxis("lefty") or 0

    if math.abs(lx) < deadzone then lx = 0 end
    if math.abs(ly) < deadzone then ly = 0 end

    if ly < 0 then set_vkey("up", true); set_vkey("w", true) end
    if ly > 0 then set_vkey("down", true); set_vkey("s", true) end
    if lx < 0 then set_vkey("left", true); set_vkey("a", true) end
    if lx > 0 then set_vkey("right", true); set_vkey("d", true) end

    -- D-Pad
    apply_dpad(js)

    last_lx, last_ly = lx, ly
  end
  -- キーボード単体の場合は本モジュールは何もしない（元の isDown が効く）
end

return M
