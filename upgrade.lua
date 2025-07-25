local upgrade = {}
local upgrades_data = require("config.upgrades")
local i18n = require("i18n")

upgrade.choices = {}
upgrade.selected_choice_index = 1 -- 初期選択肢

function upgrade.generate_choices()
    upgrade.choices = {}
    local all_upgrades = {}
    for k, v in pairs(upgrades_data) do
        table.insert(all_upgrades, k)
    end

    -- 3つのランダムな選択肢を生成 (今は同じものしかないので同じものが3つ選ばれる)
    for i = 1, 3 do
        local random_index = math.random(1, #all_upgrades)
        table.insert(upgrade.choices, all_upgrades[random_index])
    end
    upgrade.selected_choice_index = 1 -- 選択肢生成時にリセット
end

function upgrade.apply_choice(game_state)
    local chosen_upgrade_key = upgrade.choices[upgrade.selected_choice_index]
    local chosen_upgrade = upgrades_data[chosen_upgrade_key]
    if chosen_upgrade and chosen_upgrade.apply_effect then
        chosen_upgrade.apply_effect(game_state)
    end
end

function upgrade.draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(i18n.t("level_up_title_part1") .. " " .. i18n.t("level_up_title_part2"), 0, love.graphics.getHeight() / 2 - 100, love.graphics.getWidth(), "center")

    for i, choice_key in ipairs(upgrade.choices) do
        local upgrade_info = upgrades_data[choice_key]
        local display_text = string.format("%d. %s: %s", i, i18n.t(upgrade_info.name_key), i18n.t(upgrade_info.description_key))
        
        if i == upgrade.selected_choice_index then
            love.graphics.setColor(1, 1, 0, 1) -- 選択中の選択肢は黄色
        else
            love.graphics.setColor(1, 1, 1, 1) -- それ以外は白
        end
        love.graphics.printf(display_text, 0, love.graphics.getHeight() / 2 - 50 + (i - 1) * 30, love.graphics.getWidth(), "center")
    end
end

return upgrade
