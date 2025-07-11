local timer = {}

timer.elapsed_time = 0 -- 経過時間（秒）

function timer.update(dt)
    timer.elapsed_time = timer.elapsed_time + dt
end

function timer.draw()
    local minutes = math.floor(timer.elapsed_time / 60)
    local seconds = math.floor(timer.elapsed_time % 60)
    local time_string = string.format("%02d:%02d", minutes, seconds)

    love.graphics.setColor(1, 1, 1, 1) -- 白に設定
    love.graphics.print(time_string, (love.graphics.getWidth() - love.graphics.getFont():getWidth(time_string)) / 2, 10) -- 上部中央に表示
end

function timer.reset()
    timer.elapsed_time = 0
end

return timer
