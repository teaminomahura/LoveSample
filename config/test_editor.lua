local editor = {}

-- [チェック方式] このエディタ機能全体を有効にするか (true / false)
editor.enabled = true

-- [敵を記入する場所] このリストに書かれた敵だけが出現するようになります。
-- 空っぽ（{}）にしておくと、通常の出現率（spawn_rates）に従います。
editor.enemy_spawn_list = {
    "multiply_enemy",
    "minus_enemy",
}

-- [敵のレベルを強制指定] 特定の敵を、指定したレベルで強制的に出現させます。
editor.forced_enemy_levels = {
    -- minus_enemy = 3,
    -- plus_enemy = 2, -- 例えば、こんな風に他の敵も指定できます
}

-- [時間の設定] 将来的には、ここにゲーム速度などを書くこともできます
-- editor.time_scale = 2.0 -- 例えば、ゲームを2倍速でテストする

-- [選択肢の指定] 将来的には、レベルアップ時の選択肢を固定することもできます
-- editor.force_upgrade_choices = { "upgrade_rapid_fire_name", ... }

return editor