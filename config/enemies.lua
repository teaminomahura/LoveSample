local enemies_data = {
    -- マイナス（青い）敵
    minus_enemy = {
        speed = 100,
        hp = 1,
        spawn_invincibility_duration = 0.2, -- 生成後の無敵時間（秒）
        color = {0, 0, 1, 1}, -- R, G, B, A
    },
    -- プラス（緑の）敵
    plus_enemy = {
        speed = 100,
        hp = 1,
        spawn_invincibility_duration = 0.2,
        color = {0, 1, 0, 1}, -- R, G, B, A
    },
    -- ×（かける）敵
    multiply_enemy = {
        speed = 100,
        hp = 1,
        spawn_invincibility_duration = 0.2,
        color = {1, 0, 0, 1}, -- R, G, B, A (赤)
    },
    -- ÷（わる）敵
    divide_enemy = {
        speed = 100,
        hp = 1,
        spawn_invincibility_duration = 0.2,
        color = {0.5, 0, 0.5, 1}, -- R, G, B, A (紫)
    },
}

return enemies_data