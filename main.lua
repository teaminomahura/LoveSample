-- ======================================================================
-- !!! 最重要方針：既存の仕様を一切消さない !!!
-- 本ファイルは「追記・強化のみ」。既存（プレイヤー選択、ポーズ、HUD、
-- レベルアップUI、カース、BGM/グラ、ステージオブジェクト）のロジックは保持します。
-- 追加点（今回）：
--  ・controller.lua を導入：入出力の一本化（キーボード＋ゲームパッド）
--  ・決定キーに Q/Z を追加、矢印↑↓でもメニュー移動
--  ・パッド A/B/Start → Enter/Esc/P にフォワード
--  ・パッド LT（左トリガ軸）→ T にフォワード（テストポーズ）
-- ======================================================================

local Player         = require("player")
local enemy          = require("enemy")
local bullet         = require("bullet")
local utils          = require("utils")
local game_state     = require("game_state")
local upgrade        = require("upgrade")
local i18n           = require("i18n")
local timer          = require("timer")
local camera         = require("camera")
local message        = require("message")
local char_loader    = require("data.character_loader")
local player_select  = require("player_selection")
local pause_screen   = require("pause_screen")
local abilities      = require("data.player_abilities")
local curse_select   = require("curse_selection")
local stage_objects  = require("stage_objects")
local music          = require("music_command")
local graphics_cmd   = require("graphic_command")

-- ★ 入力の一本化
local controller     = require("controller")

-- ボタン判定（決定）: Enter / KeypadEnter / Q / Z
local function isConfirmKey(key)
  return (key == "return" or key == "kpenter" or key == "enter" or key == "q" or key == "z")
end

-- UI用：レベルアップ2択を開いたかどうか（既存）
local levelup_ui = { active = false }

-- ---- 既存：フォールバック選択肢生成・描画 等（省略せず保持） ----
local function ensure_upgrade_choices(player)
  if upgrade and upgrade.generate_choices then
    if (not upgrade.choices) or (#upgrade.choices == 0) then
      upgrade.generate_choices()
    end
  end
  if (not upgrade.choices) or (#upgrade.choices == 0) then
    local two = {}
    two[1] = {
      id = "MOVE_SPEED_PLUS10",
      title = "移動 +10%",
      desc  = "移動速度が 10% 上がります。",
      apply_effect = function(p, gs)
        if p and p.move_speed then
          p.move_speed = math.floor(p.move_speed * 1.10 + 0.5)
          if p.speed ~= nil then p.speed = p.move_speed end
        end
        if gs and gs.parameters then
          local cur = gs.parameters.move_speed or (p and p.move_speed) or 120
          gs.parameters.move_speed = math.floor(cur * 1.10 + 0.5)
        end
      end
    }
    two[2] = {
      id = "COOLDOWN_MINUS10",
      title = "発射クールダウン -10%",
      desc  = "弾の間隔が 少し短くなります。",
      apply_effect = function(p, gs)
        if gs and gs.parameters then
          local cd = gs.parameters.fire_cd or (p and p.fire_cooldown) or 1.0
          gs.parameters.fire_cd = cd * 0.90
        end
        if p and p.fire_cooldown then
          p.fire_cooldown = p.fire_cooldown * 0.90
        end
      end
    }
    upgrade.choices = two
  end
  upgrade.selected_choice_index = upgrade.selected_choice_index or 1
end

local function draw_upgrade_fallback()
  local w, h = love.graphics.getWidth(), love.graphics.getHeight()
  local bw, bh = w - 80, 220
  local bx, by = 40, (h - bh) / 2
  message.box(bx, by, bw, bh, 12)
  message.print("レベルアップ！ えらんでね（上下で選んで 決定）", bx + 16, by + 14, bw - 32)
  local y = by + 60
  for i, c in ipairs(upgrade.choices or {}) do
    local title = c.title or ("選択肢 " .. tostring(i))
    local desc  = c.desc  or ""
    local head = (i == upgrade.selected_choice_index) and "▶ " or "   "
    message.print(head .. title, bx + 32, y)
    love.graphics.setColor(0,0,0,0.85)
    love.graphics.print(desc, bx + 52, y + 22)
    y = y + 70
  end
end

local function apply_selected_choice()
  local applied = false
  if upgrade and upgrade.apply_choice then
    upgrade.apply_choice(game_state)
    applied = true
  end
  if not applied then
    local c = (upgrade.choices or {})[upgrade.selected_choice_index or 1]
    if c and type(c.apply_effect) == "function" then
      c.apply_effect(_G.player, game_state)
    end
  end
  music.play_me("levelup")
end

-- ゲーム内インスタンス
local player
_G.player = nil

local function _apply_selected_character(id)
  char_loader.select_character(id, nil)
  player = Player:new()
  _G.player = player
  char_loader.select_character(id, player)
  if player.move_speed and player.speed ~= nil then
    player.speed = player.move_speed
  end
  abilities.init(id, player, game_state)

  music.play_bgm("field")
  graphics_cmd.set_player_variant(id)

  curse_select.init({ interval = 60.0 })
  stage_objects.init()
end

-- ★ パッド軸（LT）のエッジ検出用
local last_trigger_left = 0.0

function love.load()
  -- フォント & 言語（既存）
  local font_path  = "assets/fonts/MPLUS_FONTS-master/fonts/ttf/Mplus1Code-Regular.ttf"
  local font_size  = 20
  pcall(function()
    local jp_font = love.graphics.newFont(font_path, font_size)
    love.graphics.setFont(jp_font)
  end)
  i18n.set_locale("ja")

  if game_state.reset_parameters then game_state.reset_parameters() end

  -- 音・画像（既存）
  music.init()
  graphics_cmd.init()

  -- ★ 入力
  controller.init()
  controller.hook_keyboard_isDown() -- ← これで isDown がパッド移動にも反応

  player_select.init({
    ids   = { "standard", "swift" },
    names = { standard = "スタンダード君", swift = "勝手に経験値君" },
    on_decide = function(id)
      _apply_selected_character(id)
      game_state.current_state = game_state.states.PLAYING
    end,
    on_cancel = function() love.event.quit() end
  })
end

function love.update(dt)
  -- ★ 入力更新（仮想キー）
  controller.update(dt)

  if player_select.is_active() then return end
  if levelup_ui.active or (curse_select.is_active and curse_select.is_active()) then return end
  if game_state.current_state == game_state.states.PAUSED then return end

  graphics_cmd.update(dt, player)
  music.update(dt)

  abilities.update(dt, player, game_state)
  curse_select.update(dt, player, game_state)
  if curse_select.is_active and curse_select.is_active() then return end
  stage_objects.update(dt, player, game_state)

  if abilities.poll_levelup_request and abilities.poll_levelup_request() then
    ensure_upgrade_choices(player)
    levelup_ui.active = true
    return
  end

  if game_state.update then
    game_state.update(dt, player, bullet, upgrade)
  end

  if game_state.current_state == game_state.states.PLAYING then
    if player and player.update then player:update(dt) end
    if enemy.update then enemy.update(dt, player) end
    if bullet.update then bullet.update(dt, player, enemy) end
    if timer.update then timer.update(dt) end
    if camera.update then camera.update(player.x, player.y) end
  end
end

function love.draw()
  if player_select.is_active() then player_select.draw(); return end

  if levelup_ui.active then
    if upgrade and upgrade.draw and upgrade.choices and #upgrade.choices > 0 then
      upgrade.draw()
    else
      draw_upgrade_fallback()
    end
    return
  end

  if curse_select.is_active and curse_select.is_active() then
    curse_select.draw()
    return
  end

  if game_state.current_state == game_state.states.PLAYING
     or game_state.current_state == game_state.states.PAUSED then

    if camera.set_world_transform then camera.set_world_transform() end
    graphics_cmd.draw_background(player)
    stage_objects.draw()
    if player and player.draw then player:draw() end
    graphics_cmd.draw_player(player)
    if enemy.draw then enemy.draw() end
    if bullet.draw then bullet.draw() end
    if camera.unset_world_transform then camera.unset_world_transform() end

    if timer.draw then timer.draw() end

    love.graphics.setColor(1, 1, 1, 1)
    local P = game_state.parameters or {}
    local enemies_count = (enemy.count and enemy.count()) or (enemy.enemies and #enemy.enemies) or 0

    love.graphics.print(i18n.t("hp")    .. ": " .. (player and player.hp or "?"),                        10, 10)
    love.graphics.print(i18n.t("level") .. ": " .. (player and player.level or "?"),                     10, 30)
    love.graphics.print(i18n.t("xp")    .. ": " .. (player and player.xp or 0) .. " / " .. (player and player.xp_to_next_level or 0), 10, 50)
    love.graphics.print(("Enemies: %d"):format(enemies_count),                                 10, 70)

    local mv = (player and player.move_speed) or (P.move_speed) or 120
    love.graphics.print(("CD: %.2fs  Move: %d  Luck: %d"):format(P.fire_cd or 1.0, mv, P.luck or 0), 10, 92)
    love.graphics.print(("ShotCost: %s shots/-1HP  Inv:%0.1fs"):format(P.hp_shot_cost or 10, P.invincible_time or 0.6), 10, 114)
  elseif game_state.current_state == game_state.states.LEVEL_UP_CHOICE then
    if upgrade and upgrade.draw then upgrade.draw() end
  end

  if game_state.draw then game_state.draw() end
  if game_state.current_state == game_state.states.PAUSED then
    pause_screen.draw()
  end
end

function love.keypressed(key)
  -- プレイヤー選択画面
  if player_select.is_active() then
    -- 既存：W/S/Enter に加え 矢印↑↓ と Q/Z を許可
    if key == "w" or key == "up" then
      player_select.keypressed("up")
      return
    elseif key == "s" or key == "down" then
      player_select.keypressed("down")
      return
    elseif isConfirmKey(key) then
      player_select.keypressed("enter")
      return
    elseif key == "escape" or key == "x" or key == "backspace" then
      player_select.keypressed("escape")
      return
    end
    return
  end

  -- カース選択UI
  if curse_select.is_active and curse_select.is_active() then
    if key == "w" or key == "up" then
      curse_select.keypressed("w")
    elseif key == "s" or key == "down" then
      curse_select.keypressed("s")
    elseif isConfirmKey(key) then
      curse_select.keypressed("enter")
    elseif key == "escape" or key == "x" or key == "backspace" then
      curse_select.keypressed("escape")
    end
    return
  end

  -- レベルアップ2択UI
  if levelup_ui.active then
    if key == "w" or key == "up" then
      upgrade.selected_choice_index = math.max(1, (upgrade.selected_choice_index or 1) - 1)
    elseif key == "s" or key == "down" then
      upgrade.selected_choice_index = math.min(#(upgrade.choices or {}), (upgrade.selected_choice_index or 1) + 1)
    elseif isConfirmKey(key) then
      apply_selected_choice()
      levelup_ui.active = false
    elseif key == "escape" or key == "x" or key == "backspace" then
      levelup_ui.active = false
    end
    return
  end

  -- 共通：キャンセル
  if key == "escape" or key == "x" or key == "backspace" then
    if game_state.current_state == game_state.states.PAUSED then
      game_state.current_state = game_state.states.PLAYING
      return
    end
    love.event.quit()
    return
  end

  -- ポーズ
  if key == "p" then
    if game_state.current_state == game_state.states.PLAYING then
      game_state.current_state = game_state.states.PAUSED
      pause_screen.open()
    elseif game_state.current_state == game_state.states.PAUSED then
      game_state.current_state = game_state.states.PLAYING
    end
    return
  end

  -- ★ テストポーズ（T）
  if key == "t" then
    if game_state.current_state ~= game_state.states.PAUSED then
      game_state.current_state = game_state.states.PAUSED
      if pause_screen.open then pause_screen.open("test") end
    else
      game_state.current_state = game_state.states.PLAYING
    end
    return
  end

  -- スキル：フィールド画面時（Enter/Q/Z/A→Enterフォワード済）
  if isConfirmKey(key) then
    if game_state.current_state == game_state.states.PLAYING then
      if _G.player and _G.player.use_skill then
        _G.player:use_skill(game_state) -- ※ 未実装でも安全
      end
    end
    return
  end

  -- 既存：LEVEL_UP_CHOICEの旧分岐（保持）
  if game_state.current_state == game_state.states.LEVEL_UP_CHOICE then
    if key == "w" or key == "up" then
      upgrade.selected_choice_index = math.max(1, (upgrade.selected_choice_index or 1) - 1)
    elseif key == "s" or key == "down" then
      upgrade.selected_choice_index = math.min(#(upgrade.choices or {}), (upgrade.selected_choice_index or 1) + 1)
    elseif isConfirmKey(key) then
      apply_selected_choice()
      game_state.current_state = game_state.states.PLAYING
    end
    return
  end
end

-- ★ ゲームパッドのボタン → キー相当へフォワード
function love.gamepadpressed(joystick, button)
  if button == "a" then
    love.keypressed("return")      -- 決定/スキル
  elseif button == "b" then
    love.keypressed("escape")      -- キャンセル
  elseif button == "start" then
    love.keypressed("p")           -- ポーズ
  elseif button == "dpup" then
    love.keypressed("up")
  elseif button == "dpdown" then
    love.keypressed("down")
  elseif button == "dpleft" then
    love.keypressed("left")
  elseif button == "dpright" then
    love.keypressed("right")
  end
end

-- ★ LT（左トリガ）は軸入力：しきい値を越えた瞬間に T キー相当を送る
function love.gamepadaxis(joystick, axis, value)
  if axis == "triggerleft" then
    local th = 0.6
    if last_trigger_left <= th and value > th then
      love.keypressed("t")
    end
    last_trigger_left = value
  end
end

























