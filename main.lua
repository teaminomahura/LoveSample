-- ======================================================================
-- 【重要宣言】このファイルの変更は「既存の仕様を一切削除しない」ことを最優先とする。
-- 既存のゲームループ、状態管理、UI、ポーズ、レベルアップ選択、敵・弾・カメラ・タイマーの呼び出し順は維持する。
-- 今回の修正は「HUD表示時に player.hp 等が nil の場合でも落ちない安全ガード」を加えるのみ。
-- ======================================================================

local Player     = require("player")
local enemy      = require("enemy")
local bullet     = require("bullet")
local utils      = require("utils")
local game_state = require("game_state")
local upgrade    = require("upgrade")
local i18n       = require("i18n")
local timer      = require("timer")
local camera     = require("camera")

local player -- Player インスタンス

-- 安全に文字列化（nilでも落ちない）
local function S(v) 
  if v == nil then return "?" end
  return tostring(v)
end

function love.load()
  -- フォント（日本語）
  local font_path  = "assets/fonts/MPLUS_FONTS-master/fonts/ttf/Mplus1Code-Regular.ttf"
  local font_size  = 20
  local ok, jp_font = pcall(love.graphics.newFont, font_path, font_size)
  if ok and jp_font then
    love.graphics.setFont(jp_font)
  end

  -- 言語
  if i18n and i18n.set_locale then i18n.set_locale("ja") end

  -- ゲームの初期パラメータ（弾TTLなどを使うモジュールがあるため最初に実行）
  if game_state and game_state.reset_parameters then
    game_state.reset_parameters()
  end

  -- 各モジュールのリセット（存在すれば）
  if enemy and enemy.reset then enemy.reset() end
  if bullet and bullet.reset then bullet.reset() end
  if timer  and timer.reset  then timer.reset()  end

  -- プレイヤー生成（既存のコンストラクタ仕様を尊重）
  if Player and Player.new then
    -- 既存実装が引数なし想定の場合に合わせる
    player = Player:new()
  end
end

function love.update(dt)
  -- ポーズ中は update スキップ（既存状態を尊重）
  if game_state.current_state == game_state.states.PAUSED then
    return
  end

  -- 既存のグローバル更新（順序維持）
  if game_state and game_state.update then
    -- 既存シグネチャを尊重（dt, player, bullet, upgrade を渡す実装）
    game_state.update(dt, player, bullet, upgrade)
  end

  if game_state.current_state == game_state.states.PLAYING then
    if player and player.update then player:update(dt) end
    if enemy  and enemy.update  then enemy.update(dt, player) end
    if bullet and bullet.update then bullet.update(dt, player, enemy) end
    if timer  and timer.update  then timer.update(dt) end
    if camera and camera.update then camera.update(player and player.x or 0, player and player.y or 0) end
  end
end

function love.draw()
  -- ポーズ中でも描画は継続（既存仕様）
  if game_state.current_state == game_state.states.PLAYING
     or game_state.current_state == game_state.states.PAUSED then

    if camera and camera.set_world_transform then camera.set_world_transform() end

    if player and player.draw then player:draw() end
    if enemy  and enemy.draw  then enemy.draw()  end
    if bullet and bullet.draw then bullet.draw() end

    if camera and camera.unset_world_transform then camera.unset_world_transform() end

    if timer and timer.draw then timer.draw() end

    -- ===== HUD（nilガード付きで安全に表示）=====
    love.graphics.setColor(1, 1, 1, 1)
    local hp_text    = S(player and player.hp)
    local lv_text    = S(player and player.level)
    local xp_text    = S(player and player.xp)
    local xp_next    = S(player and player.xp_to_next_level)

    local hp_label   = (i18n and i18n.t) and i18n.t("hp")    or "HP"
    local lv_label   = (i18n and i18n.t) and i18n.t("level") or "LEVEL"
    local xp_label   = (i18n and i18n.t) and i18n.t("xp")    or "XP"

    love.graphics.print(hp_label .. ": " .. hp_text, 10, 10)
    love.graphics.print(lv_label .. ": " .. lv_text, 10, 30)
    love.graphics.print(xp_label .. ": " .. xp_text .. " / " .. xp_next, 10, 50)

  elseif game_state.current_state == game_state.states.LEVEL_UP_CHOICE then
    if upgrade and upgrade.draw then upgrade.draw() end
  end

  if game_state and game_state.draw then
    game_state.draw() -- ゲームオーバーやポーズ等
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()

  elseif key == "p" then
    -- 既存のポーズ仕様を維持（状態トグル）
    if game_state.current_state == game_state.states.PLAYING then
      game_state.current_state = game_state.states.PAUSED
    elseif game_state.current_state == game_state.states.PAUSED then
      game_state.current_state = game_state.states.PLAYING
    end

  elseif key == "r" and game_state.current_state == game_state.states.GAME_OVER then
    -- リスタート（既存の順序を尊重）
    if player and player.reset then player:reset() end
    if enemy  and enemy.reset  then enemy.reset()  end
    if bullet and bullet.reset then bullet.reset() end
    if timer  and timer.reset  then timer.reset()  end
    if game_state and game_state.reset_parameters then game_state.reset_parameters() end
    game_state.current_state = game_state.states.PLAYING

  elseif game_state.current_state == game_state.states.LEVEL_UP_CHOICE then
    -- レベルアップ選択UI（既存のキー操作を維持）
    if key == "up" then
      upgrade.selected_choice_index = math.max(1, upgrade.selected_choice_index - 1)
    elseif key == "down" then
      upgrade.selected_choice_index = math.min(#upgrade.choices, upgrade.selected_choice_index + 1)
    elseif key == "return" or key == "space" then
      -- 既存の apply_choice 仕様を尊重（引数 game_state を渡す現行形）
      if upgrade and upgrade.apply_choice then
        upgrade.apply_choice(game_state)
      end
      game_state.current_state = game_state.states.PLAYING
    end
  end
end









