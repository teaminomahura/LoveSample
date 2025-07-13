local settings = {}

-- ゲームの基本設定
settings.player_initial_hp = 10
settings.bullet_speed = 500
settings.bullet_interval = 0.5 -- 弾の発射間隔

-- 敵の基本設定
settings.enemy_spawn_interval = 0.5 -- 敵の生成間隔
settings.max_enemies = 50 -- 画面内に存在できる敵の最大数
settings.enemy_cooldown_time = 0.5 -- 敵が弾の効果を受けるクールダウン時間

-- 敵の出現率 (合計1.0になるように調整)
settings.spawn_rates = {
    minus_enemy = 0.5,   -- マイナス敵 (青)
    plus_enemy = 0.0,    -- プラス敵 (緑)
    multiply_enemy = 0.0, -- ×敵 (赤)
    divide_enemy = 0.5,   -- ÷敵 (紫)
}

-- テスト用設定 (必要に応じてコメントアウトを外して使用)
settings.test_mode = {
    enabled = true, -- trueにすると以下のテスト設定が有効になる
    spawn_only_minus_enemy_level_3 = false, -- 最初からレベル3のマイナス敵のみ出現
    multiply_enemy_spawn_rate_override = 0.0, -- ×敵の出現率を0にする (テスト用)
}

-- 成長に関する設定
settings.xp_multiplier = 1.5 -- 次のレベルまでに必要な経験値の倍率

return settings