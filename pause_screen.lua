-- ======================================================================
-- !!! 最重要方針：既存の仕様を一切消さない !!!
-- pause_screen.lua : ポーズ画面（出現率編集 / ゲーム終了）
-- ・open() 呼び出しで現在の出現率を読み込み
-- ・draw() で白枠は使わず従来表示を踏襲（半透明幕＋テキスト）
-- ・keypressed(key) で W/S/A/D/Enter を処理（true=処理した）
-- ======================================================================

local enemy = require("enemy")

local M = {
  menu_index = 1, -- 1: 出現率編集, 2: ゲームを終了する
  fields = {
    active_field = "minus", -- "minus" or "plus"
    minus_text = "",
    plus_text  = "",
  }
}

local function parse_int(str, default)
  local n = tonumber(str)
  if n == nil then return default end
  n = math.floor(n + 0.5)
  if n < 0 then n = 0 end
  return n
end

local function isEnterKey(key)
  return key == "return" or key == "kpenter" or key == "enter"
end

local function get_spawn_weights()
  if enemy.get_spawn_weights then
    return enemy.get_spawn_weights()
  else
    return 1,1
  end
end

local function set_spawn_weights(wMinus, wPlus)
  if enemy.set_spawn_weights then
    enemy.set_spawn_weights(wMinus, wPlus)
  end
end

function M.open()
  M.menu_index = 1
  M.fields.active_field = "minus"
  local wMinus, wPlus = get_spawn_weights()
  M.fields.minus_text = tostring(wMinus or 1)
  M.fields.plus_text  = tostring(wPlus  or 1)
end

function M.draw()
  love.graphics.setColor(0,0,0,0.6)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

  love.graphics.setColor(1,1,1,1)
  love.graphics.printf("PAUSED", 0, 60, love.graphics.getWidth(), "center")

  local mx = love.graphics.getWidth()/2 - 240
  local my = 120
  local line = 0
  local function row(txt, selected)
    line = line + 1
    local y = my + (line-1)*28
    if selected then
      love.graphics.setColor(1,1,0.4,1)
    else
      love.graphics.setColor(1,1,1,1)
    end
    love.graphics.print(txt, mx, y)
  end

  row("1) 敵の出現率を編集 (WASDで数値、Enter決定、Escキャンセル)", M.menu_index==1)
  row("2) ゲームを終了する (Enterで終了)",                                 M.menu_index==2)

  if M.menu_index == 1 then
    local cx = mx
    local cy = my + 70
    love.graphics.setColor(0.8,0.9,1,1)
    love.graphics.print("Minus (青):", cx, cy)
    love.graphics.setColor(M.fields.active_field=="minus" and 1 or 0.6, M.fields.active_field=="minus" and 1 or 0.6, 1, 1)
    love.graphics.rectangle("line", cx+120, cy-4, 130, 32)
    love.graphics.print(M.fields.minus_text, cx+128, cy)

    love.graphics.setColor(0.8,1,0.8,1)
    love.graphics.print("Plus  (緑):", cx, cy+50)
    love.graphics.setColor(M.fields.active_field=="plus" and 1 or 0.6, 1, M.fields.active_field=="plus" and 1 or 0.6, 1)
    love.graphics.rectangle("line", cx+120, cy+46, 130, 32)
    love.graphics.print(M.fields.plus_text, cx+128, cy+50)

    love.graphics.setColor(1,1,1,0.9)
    love.graphics.print("操作: W/S=選択  A/D=数値  Enter=適用  Esc=戻る", cx, cy+90)
  end
end

-- true を返すと「処理済み」
function M.keypressed(key)
  if key == "w" then
    M.menu_index = math.max(1, M.menu_index - 1)
    return true
  elseif key == "s" then
    M.menu_index = math.min(2, M.menu_index + 1)
    return true
  elseif isEnterKey(key) then
    if M.menu_index == 2 then
      love.event.quit()
      return true
    end
    if M.menu_index == 1 then
      local wM = parse_int(M.fields.minus_text, 1)
      local wP = parse_int(M.fields.plus_text,  1)
      set_spawn_weights(wM, wP)
      return true -- 適用（Escで戻るのは main 側の既存挙動）
    end
    return true
  elseif key == "a" or key == "d" then
    if M.menu_index == 1 then
      local delta = (key=="a") and -1 or 1
      if M.fields.active_field == "minus" then
        local v = parse_int(M.fields.minus_text, 1) + delta
        if v < 0 then v = 0 end
        M.fields.minus_text = tostring(v)
      else
        local v = parse_int(M.fields.plus_text, 1) + delta
        if v < 0 then v = 0 end
        M.fields.plus_text = tostring(v)
      end
      return true
    end
  elseif key == "w" or key == "s" then
    return true
  end
  return false
end

return M
