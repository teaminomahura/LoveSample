local game_state = {}

function game_state.update(dt, player)
    if player.hp <= 0 then
        love.event.quit() -- ゲームオーバー
    end
end

function game_state.draw()
    -- ゲーム状態に応じた描画（今はゲームオーバーのみ）
end

return game_state