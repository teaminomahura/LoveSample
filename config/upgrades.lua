local upgrades = {
    bullet_interval_reduction = {
        name_key = "upgrade_rapid_fire_name",
        description_key = "upgrade_rapid_fire_description",
        apply_effect = function(game_state)
            game_state.parameters.bullet_interval = math.max(0.1, game_state.parameters.bullet_interval - 0.1)
        end
    },
    -- 将来的に他のアップグレードをここに追加
}

return upgrades
