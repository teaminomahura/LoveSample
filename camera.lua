local camera = {}

camera.x = 0
camera.y = 0

function camera.update(player_x, player_y)
    -- プレイヤーを画面中央に維持するようにカメラを移動
    camera.x = player_x - love.graphics.getWidth() / 2
    camera.y = player_y - love.graphics.getHeight() / 2
end

function camera.set_world_transform()
    love.graphics.push()
    love.graphics.translate(-camera.x, -camera.y)
end

function camera.unset_world_transform()
    love.graphics.pop()
end

return camera
