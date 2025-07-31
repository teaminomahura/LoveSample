-- ======================================================================
-- !!! 既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- curse_selection.lua : カース（マイナス効果）2択UI
-- ・interval 秒ごとに UI を開き、2択からプレイヤーが選ぶ
-- ・効果：①移動-10% ②クールダウン+10%
-- ・表示は message.lua の白い角丸枠＋黒文字
-- ======================================================================

local message = require("message")

local M = {
  t = 0,
  interval = 60.0,
  active = false,
  choices = {},
  index = 1,
}

local function isEnterKey(key)
  return key == "return" or key == "kpenter" or key == "enter"
end

local function make_choices()
  return {
    {
      id = "CURSE_MOVE_MINUS10",
      title = "CURSE: 移動 -10%",
      desc  = "移動速度が 10% さがります。",
      apply = function(player, gs)
        if gs and gs.parameters then
          local cur = gs.parameters.move_speed or (player and player.move_speed) or 120
          gs.parameters.move_speed = math.max(1, math.floor(cur * 0.90 + 0.5))
        end
        if player and player.move_speed then
          player.move_speed = math.max(1, math.floor(player.move_speed * 0.90 + 0.5))
          if player.speed ~= nil then player.speed = player.move_speed end
        end
      end
    },
    {
      id = "CURSE_CD_PLUS10",
      title = "CURSE: 発射クールダウン +10%",
      desc  = "弾の間隔が 少し長くなります。",
      apply = function(player, gs)
        if gs and gs.parameters then
          local cd = gs.parameters.fire_cd or (player and player.fire_cooldown) or 1.0
          gs.parameters.fire_cd = cd * 1.10
        end
        if player and player.fire_cooldown then
          player.fire_cooldown = player.fire_cooldown * 1.10
        end
      end
    },
  }
end

function M.init(opt)
  M.interval = (opt and opt.interval) or 60.0
  M.t = 0
  M.active = false
  M.choices = {}
  M.index = 1
end

function M.is_active()
  return M.active
end

function M.update(dt, player, gs)
  if M.active then return end
  M.t = M.t + dt
  if M.t >= M.interval then
    M.t = M.t - M.interval
    M.choices = make_choices()
    M.index = 1
    M.active = true
  end
end

function M.draw()
  if not M.active then return end
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local bw, bh = w - 80, 220
  local bx, by = 40, (h - bh) / 2
  message.box(bx, by, bw, bh, 12)
  message.print("CURSE! えらんでね（W/Sで選んで Enter）", bx + 16, by + 14, bw - 32)

  local y = by + 60
  for i, c in ipairs(M.choices) do
    local head = (i == M.index) and "▶ " or "   "
    message.print(head .. (c.title or ("選択肢 " .. tostring(i))), bx + 32, y)
    love.graphics.setColor(0,0,0,0.85)
    love.graphics.print(c.desc or "", bx + 52, y + 22)
    y = y + 70
  end
end

function M.keypressed(key)
  if not M.active then return end
  if key == "w" then
    M.index = math.max(1, M.index - 1)
  elseif key == "s" then
    M.index = math.min(#M.choices, M.index + 1)
  elseif isEnterKey(key) then
    local c = M.choices[M.index]
    if c and type(c.apply) == "function" then
      c.apply(_G.player, require("game_state"))
    end
    M.active = false
  elseif key == "escape" then
    -- キャンセルで閉じる（必要なら無効化可）
    M.active = false
  end
end

return M

