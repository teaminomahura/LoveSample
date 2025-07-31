-- ======================================================================
-- !!! 最重要方針：既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- message.lua : 白い角丸メッセージ枠＋黒文字（SFC『ライブ・ア・ライブ』風）
-- ・枠は白（塗り＋細線）、文字は黒に統一
-- ・どこからでも require(\"message\").box / .print で使用可能
-- ======================================================================

local M = {}

function M.box(x, y, w, h, r)
  r = r or 10
  -- 白い塗り
  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.rectangle("fill", x, y, w, h, r, r)
  -- 輪郭（うすい黒）
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.setLineWidth(2)
  love.graphics.rectangle("line", x + 1, y + 1, w - 2, h - 2, r, r)
end

function M.print(text, x, y, limit, align)
  love.graphics.setColor(0, 0, 0, 1) -- 黒文字
  if limit then
    love.graphics.printf(text, x, y, limit, align or "left")
  else
    love.graphics.print(text, x, y)
  end
end

return M
