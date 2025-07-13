local utils = {}

function utils.checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and
           y1 < y2 + h2 and y1 + h1 > y2
end

-- テーブルを再帰的にコピーする（ネストされたテーブルも対応）
function utils.deep_copy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = utils.deep_copy(v)
        end
        copy[k] = v
    end
    return copy
end

-- 特定の敵の出現率を変更し、他の敵の出現率を合計が1.0になるように再調整する
function utils.rebalance_spawn_rates(original_rates, target_key, new_rate)
    local new_rates = utils.deep_copy(original_rates)
    new_rates[target_key] = new_rate

    local current_total = 0
    for _, rate in pairs(new_rates) do
        current_total = current_total + rate
    end

    local remaining_total = 1.0 - new_rate
    local original_other_total = 1.0 - original_rates[target_key]

    for key, rate in pairs(new_rates) do
        if key ~= target_key and original_other_total > 0 then
            new_rates[key] = (original_rates[key] / original_other_total) * remaining_total
        end
    end
    return new_rates
end

-- シンプルなクラス作成ヘルパー関数
function utils.class(base)
    local new_class = {}
    new_class.__index = new_class

    function new_class:new(...)
        local instance = setmetatable({}, new_class)
        if instance.init then instance:init(...) end
        return instance
    end

    return new_class
end

return utils