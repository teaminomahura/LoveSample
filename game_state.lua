local game_state = {}
local i18n = require("i18n")

game_state.states = {
    PLAYING = 1,
    GAME_OVER = 2,
    LEVEL_UP_CHOICE = 3,
    PAUSED = 4 -- ポーズ状態を追加
}
game_state.current_state = game_state.states.PLAYING

function game_state.update(dt, player, bullet_module, upgrade_module)
    if game_state.current_state == game_state.states.PLAYING then
        if player.hp <= 0 then
            game_state.current_state = game_state.states.GAME_OVER
        end

        -- レベルアップ判定
        if player.xp >= player.xp_to_next_level then
            player.level = player.level + 1
            player.xp = player.xp - player.xp_to_next_level
            player.xp_to_next_level = math.floor(player.xp_to_next_level * 1.5)
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
