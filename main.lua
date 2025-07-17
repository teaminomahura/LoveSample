-- main.lua Playerインスタンス移行テスト版
-- Step1.3: player.luaのPlayerクラスを直接利用

local playerMod  = require("player")    -- 互換API + PlayerClass保持
local Player     = playerMod.PlayerClass
local player     -- Playerインスタンス（love.loadで生成）

local enemy      = require("enemy")
local bullet     = require("bullet")
local utils      = require("utils")
local game_state = require("game_state")
local upgrade    = require("upgrade")
local i18n       = require("i18n")
local timer      = require("timer")
local camera     = require("camera")

function love.load()
    -- Playerインスタンス生成
    player = Player:new()

    -- 日本語フォント
    local font_path  = "assets/fonts/MPLUS_FONTS-master/fonts/ttf/Mplus1Code-Regular.ttf"
    local font_size  = 20
    local jp_font    = love.graphics.newFont(font_path, font_size)
    love.graphics.setFont(jp_font)

    -- 言語設定
    i18n.set_locale("ja")

    -- ゲームパラメータ初期化
    game_state.reset_parameters()
end

function love.update(dt)
    -- ポーズ時スキップ
    if game_state.current_state == game_state.states.PAUSED then
        return
    end

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
        love.graphics.print(i18n.t("hp")    .. ": " .. player.hp,                10, 10)
        love.graphics.print(i18n.t("level") .. ": " .. player.level,             10, 30)
        love.graphics.print(i18n.t("xp")    .. ": " .. player.xp .. " / " ..
                                              player.xp_to_next_level,          10, 50)
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



