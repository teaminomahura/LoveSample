-- player.lua 互換API + Playerクラス公開版
-- Step1.2 完了 / Step1.3 移行支援
-- 外部は従来どおり player = require("player") で利用可。
-- Playerクラスは player.PlayerClass から取得。

local utils      = require("utils")
local game_state = require("game_state")

----------------------------------------------------------------
-- Player クラス定義
----------------------------------------------------------------
local Player = utils.class()

function Player:init(...)
    -- LÖVE起動時に utils.class():new() から呼ばれる
    self:initialize(...)
end

function Player:initialize()
    self.x = 1280 / 2
    self.y = 720 / 2
    self.speed = 200
    self.hp = 10
    self.xp = 0
    self.level = 1
    self.invincible_timer = 0
    self.xp_to_next_level = 3
end

function Player:update(dt)
    -- 無敵タイマー
    self.invincible_timer = (self.invincible_timer or 0)
    if self.invincible_timer > 0 then
        self.invincible_timer = self.invincible_timer - dt
    end

    -- キー入力移動
    if love.keyboard.isDown("w", "up") then
        self.y = self.y - self.speed * dt
    end
    if love.keyboard.isDown("s", "down") then
        self.y = self.y + self.speed * dt
    end
    if love.keyboard.isDown("a", "left") then
        self.x = self.x - self.speed * dt
    end
    if love.keyboard.isDown("d", "right") then
        self.x = self.x + self.speed * dt
    end
end

function Player:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", self.x - 10, self.y - 10, 20, 20)
end

function Player:reset()
    self.x = 1280 / 2
    self.y = 720 / 2
    self.hp = game_state.parameters.player_initial_hp
    self.xp = 0
    self.level = 1
    self.invincible_timer = 0
    self.xp_to_next_level = 3
end

----------------------------------------------------------------
-- 旧互換API (従来の playerテーブル)
-- 他ファイルがまだ古い呼び方でも壊れないための薄いラッパー
----------------------------------------------------------------
local player = {
    x = 1280 / 2,
    y = 720 / 2,
    speed = 200,
    hp = 10,
    xp = 0,
    level = 1,
    invincible_timer = 0,
    xp_to_next_level = 3,
    _inst = nil,
}

-- 内部インスタンス→公開テーブル同期
local function sync_state_from_instance()
    local inst = player._inst
    if not inst then return end
    player.x = inst.x
    player.y = inst.y
    player.speed = inst.speed
    player.hp = inst.hp
    player.xp = inst.xp
    player.level = inst.level
    player.invincible_timer = inst.invincible_timer
    player.xp_to_next_level = inst.xp_to_next_level
end

function player.load()
    player._inst = Player:new()
    sync_state_from_instance()
end

function player.update(dt)
    if not player._inst then player.load() end
    player._inst:update(dt)
    sync_state_from_instance()
end

function player.draw()
    if player._inst then
        player._inst:draw()
    else
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", player.x - 10, player.y - 10, 20, 20)
    end
end

function player.reset()
    if not player._inst then player.load() end
    player._inst:reset()
    sync_state_from_instance()
end

----------------------------------------------------------------
-- Playerクラス公開
----------------------------------------------------------------
player.PlayerClass = Player
return player




