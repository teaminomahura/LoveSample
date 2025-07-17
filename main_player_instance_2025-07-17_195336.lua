-- main.lua Step1.3 Playerインスタンス版（テスト用）
-- 現在は移行テスト。問題あれば main_old_xxx.lua に戻せます。

-- Playerクラスを取得しインスタンスを使う
local _playerCompat, Player = require("player") -- 旧互換は未使用
local player -- Playerインスタンス保持

local enemy     = require("enemy")
local bullet    = require("bullet")
local utils     = require("utils")
local game_state= require("game_state")
local upgrade   = require("upgrade")
local i18n      = require("i18n")
local timer     = require("timer")
local camera    = require("camera")

function love.load()
    -- Playerインスタンス生成
    player = Player:new()

    -- フォント
    local font_path = "assets/fonts/MPLUS_FONTS-master/fonts/ttf/Mplus1Code-Regular.ttf"
    local font_size = 20
    local japanese_font = love.graphics.newFont(font_path, font_size)
    love.graphics.setFont(japanese_font)

    -- 日本語ロケール
    i18n.set_locale("ja")

    -- ゲームパラメータ初期化
    game_state.reset_parameters()
end

function love.update(dt)
    if game_state.current_state == game_state.states.PAUSED then
        return
    end

    -- ゲーム全体更新
    game_state.update(dt, player, bullet, upgrade)

    if game_state.current_state == game_state.states.PLAYING then
        player:update(dt)
        enemy.update(dt, player)
        bullet.update(dt, player, enemy)
        timer.update(dt)
        camera.update(player.x, player.y)
    end
end

function love.draw()
    if game_state.current_state == game_state.states.PLAYING
        or game_state.current_state == game_state.states.PAUSED then

        camera.set_world_transform()

        player:draw()
        enemy.draw()
        bullet.draw()

        camera.unset_world_transform()
        timer.draw()

        -- HUD
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(i18n.t("hp") .. ": " .. (player.hp or "?"), 10, 10)
        love.graphics.print(i18n.t("level") .. ": " .. (player.level or "?"), 10, 30)
        love.graphics.print(
            i18n.t("xp") .. ": " ..
            (player.xp or "?") .. " / " .. (player.xp_to_next_level or "?"),
            10, 50
        )

    elseif game_state.current_state == game_state.states.LEVEL_UP_CHOICE then
        upgrade.draw()
    end

    game_state.draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()

    elseif key == "p" then
        if game_state.current_state == game_state.states.PLAYING then
            game_state.current_state = game_state.states.PAUSED
        elseif game_state.current_state == game_state.states.PAUSED then
            game_state.current_state = game_state.states.PLAYING
        end

    elseif key == "r" and game_state.current_state == game_state.states.GAME_OVER then
        player:reset()
        enemy.reset()
        bullet.reset()
        timer.reset()
        game_state.reset_parameters()
        game_state.current_state = game_state.states.PLAYING

    elseif game_state.current_state == game_state.states.LEVEL_UP_CHOICE then
        if key == "up" then
            upgrade.selected_choice_index = math.max(1, upgrade.selected_choice_index - 1)
        elseif key == "down" then
            upgrade.selected_choice_index = math.min(#upgrade.choices, upgrade.selected_choice_index + 1)
        elseif key == "return" then
            upgrade.apply_choice(game_state)
            game_state.current_state = game_state.states.PLAYING
        end
    end
end


