local player = require("player")
local enemy = require("enemy")
local bullet = require("bullet")
local utils = require("utils")
local game_state = require("game_state")
local upgrade = require("upgrade")
local i18n = require("i18n")
local timer = require("timer")
local camera = require("camera")

function love.load()
    -- ウィンドウ設定は conf.lua に移行
    -- 日本語フォントの読み込みと設定
    local font_path = "assets/fonts/MPLUS_FONTS-master/fonts/ttf/Mplus1Code-Regular.ttf"
    local font_size = 20 -- フォントサイズを調整
    local japanese_font = love.graphics.newFont(font_path, font_size)
    love.graphics.setFont(japanese_font)

    -- 言語設定を日本語に
    i18n.set_locale("ja")
end

function love.update(dt)
    -- ポーズ中は update をスキップ
    if game_state.current_state == game_state.states.PAUSED then
        return
    end

    game_state.update(dt, player, bullet, upgrade)

    if game_state.current_state == game_state.states.PLAYING then
        player.update(dt)
        enemy.update(dt, player)
        bullet.update(dt, player, enemy)
        timer.update(dt)
        camera.update(player.x, player.y)
    end
end

function love.draw()
    -- 描画はポーズ中でも行う
    if game_state.current_state == game_state.states.PLAYING or game_state.current_state == game_state.states.PAUSED then
        camera.set_world_transform()

        player.draw()
        enemy.draw()
        bullet.draw()

        camera.unset_world_transform()

        timer.draw()

        -- HPの表示
        love.graphics.setColor(1, 1, 1, 1) -- 白に設定
        love.graphics.print(i18n.t("hp") .. ": " .. player.hp, 10, 10)

        -- 経験値とレベルの表示
        love.graphics.print(i18n.t("level") .. ": " .. player.level, 10, 30)
        love.graphics.print(i18n.t("xp") .. ": " .. player.xp .. " / " .. player.xp_to_next_level, 10, 50)
    elseif game_state.current_state == game_state.states.LEVEL_UP_CHOICE then
        upgrade.draw()
    end

    game_state.draw() -- ゲームオーバーやポーズ画面の描画
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "p" then -- Pキーでポーズ/再開
        if game_state.current_state == game_state.states.PLAYING then
            game_state.current_state = game_state.states.PAUSED
        elseif game_state.current_state == game_state.states.PAUSED then
            game_state.current_state = game_state.states.PLAYING
        end
    elseif key == "r" and game_state.current_state == game_state.states.GAME_OVER then
        player.reset()
        enemy.reset()
        bullet.reset()
        timer.reset()
        game_state.current_state = game_state.states.PLAYING
    elseif game_state.current_state == game_state.states.LEVEL_UP_CHOICE then
        if key == "up" then
            upgrade.selected_choice_index = math.max(1, upgrade.selected_choice_index - 1)
        elseif key == "down" then
            upgrade.selected_choice_index = math.min(#upgrade.choices, upgrade.selected_choice_index + 1)
        elseif key == "return" then -- Enterキー
            upgrade.apply_choice(player, bullet)
            game_state.current_state = game_state.states.PLAYING
        end
    end
end
