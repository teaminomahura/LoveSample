function love.load()
    -- ゲームの初期化処理
    print("Hello, Love2D!")
end

function love.update(dt)
    -- ゲームの更新処理 (dtは前回のフレームからの経過時間)
end

function love.draw()
    -- 描画処理
    love.graphics.print("Hello, Love2D!", 400, 300)
end
