local upgrades = {
    bullet_interval_reduction = {
        name = "Rapid Fire",
        description = "Decreases bullet firing interval.",
        apply_effect = function(player_module, bullet_module)
            bullet_module.bullet_interval = math.max(0.1, bullet_module.bullet_interval - 0.1)
        end
    },
    -- 将来的に他のアップグレードをここに追加
}

return upgrades
