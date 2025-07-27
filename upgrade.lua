-- upgrade.lua (drop-in replacement)
-- かんたん説明：
-- このファイルは「レベルアップのえらぶ画面」を作ります。
-- エラー「upgrade.apply_choice の引数がちがう」をなくすため、
-- apply_choice は (player, game_state) でも (game_state) でも どちらでも動きます。

local upgrade = {}

-- 内部状態（今えらべるカード）---------------------------
upgrade.choices = {}
upgrade.selected_choice_index = 1

-- 安全にアップグレード定義を読み込む ----------------------
local upgrades_data = nil
do
  local ok, mod = pcall(require, "config.upgrades")
  if ok and mod then
    upgrades_data = mod
  else
    -- 予備（最小セット）。タイトルと効果だけのシンプル版です。
    upgrades_data = {
      common = {
        {
          id = "MAX_HP_PLUS3",
          title = "最大HP +3",
          desc  = "最大HPが 3 増えます。",
          apply_effect = function(player, gs)
            -- player や gs が nil でも落ちないようにチェック
            if gs and gs.player_max_hp then
              gs.player_max_hp = gs.player_max_hp + 3
            end
            if player and player.max_hp then
              player.max_hp = player.max_hp + 3
            end
          end
        },
        {
          id = "MOVE_SPEED_PLUS15",
          title = "移動 +15%",
          desc  = "移動速度が 15% 上がります。",
          apply_effect = function(player, gs)
            if gs and gs.player_move_speed then
              gs.player_move_speed = gs.player_move_speed * 1.15
            end
            if player and player.move_speed then
              player.move_speed = player.move_speed * 1.15
            end
          end
        },
        {
          id = "COOLDOWN_MINUS10",
          title = "発射クールダウン -10%",
          desc  = "弾の間隔が 少し短くなります。",
          apply_effect = function(player, gs)
            if gs and gs.player_shot_cd then
              gs.player_shot_cd = gs.player_shot_cd * 0.90
            end
            if player and player.shot_cooldown then
              player.shot_cooldown = player.shot_cooldown * 0.90
            end
          end
        },
      },
      rare = {
        {
          id = "REVIVE_PLUS1",
          title = "復活 +1（無敵つき）",
          desc  = "やられても 1 回だけ 復活できます。",
          apply_effect = function(player, gs)
            if gs and gs.revives then
              gs.revives = gs.revives + 1
            elseif player and player.revives then
              player.revives = player.revives + 1
            end
          end
        }
      }
    }
  end
end

-- 乱数ヘルパー -------------------------------------------
local function shuffle_inplace(t)
  for i = #t, 2, -1 do
    local j = love.math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

-- プール（候補）を作る -----------------------------------
local function build_pool()
  local pool = {}
  if upgrades_data.common then
    for _,u in ipairs(upgrades_data.common) do table.insert(pool, u) end
  end
  if upgrades_data.rare then
    -- レアは少し出にくくする（2 枚に 1 回くらいの気持ち）
    for _,u in ipairs(upgrades_data.rare) do table.insert(pool, u) end
  end
  return pool
end

-- レベルアップ時に 3 つの候補を作る ----------------------
function upgrade.generate_choices()
  local pool = build_pool()
  if #pool == 0 then
    upgrade.choices = {}
    upgrade.selected_choice_index = 1
    return
  end
  shuffle_inplace(pool)
  upgrade.choices = {}
  for i = 1, math.min(3, #pool) do
    table.insert(upgrade.choices, pool[i])
  end
  upgrade.selected_choice_index = 1
end

-- 上下キーで カーソルを動かす ----------------------------
function upgrade.navigate_selection(dir)
  if #upgrade.choices == 0 then return end
  upgrade.selected_choice_index = upgrade.selected_choice_index + dir
  if upgrade.selected_choice_index < 1 then
    upgrade.selected_choice_index = #upgrade.choices
  elseif upgrade.selected_choice_index > #upgrade.choices then
    upgrade.selected_choice_index = 1
  end
end

-- 決定：選んだ効果を反映 --------------------------------
-- （どちらでもOK）apply_choice(game_state)
-- （あたらしい）  apply_choice(player, game_state)
function upgrade.apply_choice(a, b)
  local player, gs
  if b == nil then
    -- 1 引数（古い呼び方）
    gs = a
    -- player はわからないことがあるので nil のままでもOK（多くの効果は gs 側だけでも動くように書いています）
  else
    -- 2 引数（新しい呼び方）
    player, gs = a, b
  end

  local choice = upgrade.choices[upgrade.selected_choice_index]
  if not choice then
    return
  end

  if type(choice.apply_effect) == "function" then
    -- Lua は 余分な引数を 無視するので、
    -- apply_effect が (gs) だけでも (player, gs) でも OK
    choice.apply_effect(player, gs)
  end

  -- 使い終わったら候補を消す（次のレベルでまた生成）
  upgrade.choices = {}
  upgrade.selected_choice_index = 1

  -- 状態を「プレイ中」に戻す（gs があれば）
  if gs and gs.states and gs.states.PLAYING then
    gs.current_state = gs.states.PLAYING
  end
end

-- 画面に 選択肢を描く ------------------------------------
function upgrade.draw()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", 20, 20, w - 40, h - 40, 8, 8)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf("レベルアップ！ えらんでね（上下で選んで Enter）", 40, 40, w - 80)

  local y = 90
  for i, c in ipairs(upgrade.choices) do
    if i == upgrade.selected_choice_index then
      love.graphics.setColor(1, 1, 0.2, 1) -- 選択中は 黄色
    else
      love.graphics.setColor(1, 1, 1, 1)
    end
    local title = c.title or c.title_key or ("選択肢 " .. tostring(i))
    local desc  = c.desc  or c.desc_key  or ""
    love.graphics.print(("- %s"):format(title), 60, y)
    love.graphics.setColor(0.9, 0.9, 0.9, 1)
    love.graphics.print(desc, 80, y + 20)
    y = y + 60
  end
end

-- 予備：全部リセット --------------------------------------
function upgrade.reset()
  upgrade.choices = {}
  upgrade.selected_choice_index = 1
end

return upgrade

