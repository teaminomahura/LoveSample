local game_state = {}
local i18n = require("i18n")
local game_settings = require("config.game_settings")
local utils = require("utils")
local test_editor = require("config.test_editor") -- 新しく追加

game_state.states = {
    PLAYING = 1,
    GAME_OVER = 2,
    LEVEL_UP_CHOICE = 3,
    PAUSED = 4
}
game_state.current_state = game_state.states.PLAYING
game_state.parameters = {} -- ゲーム中に変動するパラメータの司令塔

-- ゲームパラメータを初期設定からリセットする関数
function game_state.reset_parameters()
    -- game_settingsからディープコピーして、元の設定が変更されないようにする
    game_state.parameters = utils.deep_copy(game_settings)

    -- テストモードが有効な場合、設定を上書きする
    if game_state.parameters.test_mode and game_state.parameters.test_mode.enabled then
        local test_settings = game_state.parameters.test_mode
        if test_settings.multiply_enemy_spawn_rate_override ~= nil then
            -- ×敵の出現率を上書きし、他の敵の出現率を再計算して合計が1.0になるように調整
            local new_rates = utils.rebalance_spawn_rates(game_state.parameters.spawn_rates, "multiply_enemy", test_settings.multiply_enemy_spawn_rate_override)
            game_state.parameters.spawn_rates = new_rates
        end
        -- 他のテスト設定もここに追加可能
    end

    -- test_editorが有効な場合、その設定でさらに上書きする
    if test_editor.enabled then
        game_state.parameters.test_editor = test_editor -- test_editorの設定を司令塔にコピー
    end
end

function game_state.update(dt, player, bullet_module, upgrade_module)
    if game_state.current_state == game_state.states.PLAYING then
        if player.hp <= 0 then
            game_state.current_state = game_state.states.GAME_OVER
        end

        -- レベルアップ判定
        if player.xp >= player.xp_to_next_level then
            player.level = player.level + 1
            player.xp = player.xp - player.xp_to_next_level
            player.xp_to_next_level = math.floor(player.xp_to_next_level * game_state.parameters.xp_multiplier)
            game_state.current_state = game_state.states.LEVEL_UP_CHOICE
            upgrade_module.generate_choices()
        end
    end
end

function game_state.draw()
    if game_state.current_state == game_state.states.GAME_OVER then
        love.graphics.setColor(1, 1, 1, 1) -- 白に設定
        love.graphics.printf(i18n.t("game_over"), 0, love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        love.graphics.printf(i18n.t("press_r_to_restart"), 0, love.graphics.getHeight() / 2 + 20, love.graphics.getWidth(), "center")
    elseif game_state.current_state == game_state.states.PAUSED then
        love.graphics.setColor(1, 1, 1, 0.5) -- 半透明の白
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight()) -- 画面全体を覆う
        love.graphics.setColor(1, 1, 1, 1) -- 白に設定
        love.graphics.printf(i18n.t("paused"), 0, love.graphics.getHeight() / 2 - 10, love.graphics.getWidth(), "center")
    end
end

return game_state
