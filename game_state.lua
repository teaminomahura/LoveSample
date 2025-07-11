local game_state = {}

game_state.states = {
    PLAYING = 1,
    GAME_OVER = 2
}
game_state.current_state = game_state.states.PLAYING

function game_state.update(dt, player)
    if game_state.current_state == game_state.states.PLAYING then
        if player.hp <= 0 then
            game_state.current_state = game_state.states.GAME_OVER
        end
    end
end

function game_state.draw()
    if game_state.current_state == game_state.states.GAME_OVER then
        love.graphics.setColor(1, 1, 1, 1) -- 白に設定
        love.graphics.printf("GAME OVER", 0, love.graphics.getHeight() / 2 - 20, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R to Restart", 0, love.graphics.getHeight() / 2 + 20, love.graphics.getWidth(), "center")
    end
end

return game_state
