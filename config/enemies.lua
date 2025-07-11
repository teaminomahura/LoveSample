local enemies_data = {
    -- マイナス（青い）敵
    minus_enemy = {
        speed = 100,
        hp = 1,
        color = {0, 0, 1, 1}, -- R, G, B, A
    },
    -- プラス（緑の）敵
    plus_enemy = {
        speed = 100,
        hp = 1,
        color = {0, 1, 0, 1}, -- R, G, B, A
    },
    -- 将来的に新しい敵をここに追加
    -- new_enemy_type = {
    --     speed = 120,
    --     hp = 2,
    --     color = {1, 0, 0, 1},
    -- },
}

return enemies_data
