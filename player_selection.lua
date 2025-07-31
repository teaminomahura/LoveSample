-- ======================================================================
-- !!! 最重要方針：既存の仕様を一切消さない !!!
-- player_selection.lua : プレイヤー選択画面（W/S で選択、Enter で決定）
-- ・白枠UIは message.lua を使用（黒文字）
-- ・外部から init({ ids, names, on_decide, on_cancel }) を呼ぶ
-- ======================================================================

local message = require("message")

local M = {
  active = false,
  ids    = { "standard", "swift" },
  names  = { standard = "スタンダード君", swift = "スウィフト君" },
  index  = 1,
  on_decide = nil,
  on_cancel = nil,
}

local function isEnterKey(key)
  return key == "return" or key == "kpenter" or key == "enter"
end

function M.init(opt)
  M.ids      = (opt and opt.ids)   or M.ids
  M.names    = (opt and opt.names) or M.names
  M.index    = 1
  M.on_decide = opt and opt.on_decide
  M.on_cancel = opt and opt.on_cancel
  M.active   = true
end

function M.is_active()
  return M.active
end

function M.draw()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local bw, bh = 520, 200
  local bx, by = (w-bw)/2, (h-bh)/2
  message.box(bx, by, bw, bh, 12)
  message.print("キャラクターを選んでください（W/Sで選択、Enterで決定）", bx+16, by+14)
  local y = by + 60
  for i, id in ipairs(M.ids) do
    local name = (M.names and M.names[id]) or id
    local head = (i == M.index) and "▶ " or "   "
    message.print(head .. name, bx+30, y)
    y = y + 40
  end
end

function M.keypressed(key)
  if not M.active then return end
  if key == "w" then
    M.index = math.max(1, M.index - 1)
  elseif key == "s" then
    M.index = math.min(#M.ids, M.index + 1)
  elseif isEnterKey(key) then
    local id = M.ids[M.index]
    if M.on_decide then M.on_decide(id) end
    M.active = false
  elseif key == "escape" then
    if M.on_cancel then M.on_cancel() end
  end
end

return M
