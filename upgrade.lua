-- 最重要方針：既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- upgrade.lua（UI本体）
-- ・config/upgrades.lua を安全に読み込む（データが無ければ内蔵2択にフォールバック）
-- ・apply_choice は (game_state) / (player, game_state) どちらでも可
-- ・描画は message.lua（白い角丸枠＋黒文字）

local upgrade = {}
local message = require("message")

-- 内部状態 ------------------------------------------------
upgrade.choices = {}
upgrade.selected_choice_index = 1

-- 内蔵フォールバック（必ず2択が出る）
local DEFAULT_DATA = {
  common = {
    {
      id = "MOVE_SPEED_PLUS10",
      title = "移動 +10%",
      desc  = "移動速度が 10% 上がります。",
      apply_effect = function(player, gs)
        if player and player.move_speed then
          player.move_speed = math.floor(player.move_speed * 1.10 + 0.5)
          if player.speed ~= nil then player.speed = player.move_speed end
        end
        if gs and gs.parameters then
          local cur = gs.parameters.move_speed or (player and player.move_speed) or 120
          gs.parameters.move_speed = math.floor(cur * 1.10 + 0.5)
        end
      end
    },
    {
      id = "COOLDOWN_MINUS10",
      title = "発射クールダウン -10%",
      desc  = "弾の間隔が少し短くなります。",
      apply_effect = function(player, gs)
        if gs and gs.parameters then
          local cd = gs.parameters.fire_cd or (player and player.fire_cooldown) or 1.0
          gs.parameters.fire_cd = cd * 0.90
        end
        if player and player.fire_cooldown then
          player.fire_cooldown = player.fire_cooldown * 0.90
        end
      end
    },
  },
  rare = {}
}

-- データ読込（config/upgrades.lua が“データ表”の場合のみ採用）
local function load_upgrades_data()
  local ok, mod = pcall(require, "config.upgrades")
  if not ok or type(mod) ~= "table" then return nil end
  local has_common = (type(mod.common) == "table" and #mod.common > 0)
  local has_rare   = (type(mod.rare)   == "table" and #mod.rare   > 0)
  if has_common or has_rare then
    return mod
  end
  return nil
end

local upgrades_data = load_upgrades_data() or DEFAULT_DATA

-- 乱数ヘルパー -------------------------------------------
local function shuffle_inplace(t)
  for i = #t, 2, -1 do
    local j = love.math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

-- プール作成 ---------------------------------------------
local function build_pool()
  local pool = {}
  if upgrades_data.common then
    for _,u in ipairs(upgrades_data.common) do table.insert(pool, u) end
  end
  if upgrades_data.rare then
    for _,u in ipairs(upgrades_data.rare) do table.insert(pool, u) end
  end
  return pool
end

-- レベルアップ時の候補生成（少なくとも2択は保証）---------
function upgrade.generate_choices()
  local pool = build_pool()
  if #pool == 0 then
    -- 予防：万一データが空でもフォールバック2択を入れる
    upgrades_data = DEFAULT_DATA
    pool = build_pool()
  end
  shuffle_inplace(pool)
  upgrade.choices = {}
  for i = 1, math.min(2, #pool) do
    table.insert(upgrade.choices, pool[i])
  end
  upgrade.selected_choice_index = 1
end

-- 上下移動 ------------------------------------------------
function upgrade.navigate_selection(dir)
  if #upgrade.choices == 0 then return end
  upgrade.selected_choice_index = upgrade.selected_choice_index + dir
  if upgrade.selected_choice_index < 1 then
    upgrade.selected_choice_index = #upgrade.choices
  elseif upgrade.selected_choice_index > #upgrade.choices then
    upgrade.selected_choice_index = 1
  end
end

-- 決定（どちらの呼び方でもOK）---------------------------
function upgrade.apply_choice(a, b)
  local player, gs
  if b == nil then gs = a else player, gs = a, b end

  local choice = upgrade.choices[upgrade.selected_choice_index]
  if not choice then return end

  if type(choice.apply_effect) == "function" then
    choice.apply_effect(player, gs)
  end

  upgrade.choices = {}
  upgrade.selected_choice_index = 1

  if gs and gs.states and gs.states.PLAYING then
    gs.current_state = gs.states.PLAYING
  end
end

-- 描画（白枠＋黒文字）------------------------------------
function upgrade.draw()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local bw, bh = w - 80, 220
  local bx, by = 40, (h - bh) / 2
  message.box(bx, by, bw, bh, 12)
  message.print("レベルアップ！ えらんでね（W/Sで選んで Enter）", bx + 16, by + 14, bw - 32)

  local y = by + 60
  for i, c in ipairs(upgrade.choices) do
    local title = c.title or ("選択肢 " .. tostring(i))
    local desc  = c.desc  or ""
    local head = (i == upgrade.selected_choice_index) and "▶ " or "   "
    message.print(head .. title, bx + 32, y)
    love.graphics.setColor(0,0,0,0.85)
    love.graphics.print(desc, bx + 52, y + 22)
    y = y + 70
  end
end

function upgrade.reset()
  upgrade.choices = {}
  upgrade.selected_choice_index = 1
end

return upgrade


