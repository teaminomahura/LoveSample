local utils = require("utils")
local game_state = require("game_state")

--- Step1.2 init対策: Playerクラス定義とコンストラクタ ---
local Player = utils.class()

function Player:init(...)
    -- デバッグ用: コンストラクタ呼び出し確認 (コメントアウト可)
    -- print("Player:init called")
    self:initialize(...) -- 既存のinitializeメソッドを呼び出す
end

function Player:initialize()
    -- 全てのフィールドを数値で初期化 (nil対策)
    self.x = 1280 / 2
    self.y = 720 / 2
    self.speed = 200
    self.hp = 10
    self.xp = 0
    self.level = 1
    self.invincible_timer = 0 -- 数値で初期化
    self.xp_to_next_level = 3
end

function Player:update(dt)
    -- nilチェックとデフォルト値設定 (安全ガード)
    self.invincible_timer = self.invincible_timer or 0

    if self.invincible_timer > 0 then
        self.invincible_timer = self.invincible_timer - dt
    end

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
    self.hp = game_state.parameters.player_initial_hp -- 司令塔から読み込む
    self.xp = 0
    self.level = 1
    self.invincible_timer = 0
    self.xp_to_next_level = 3
end

-- 既存のplayerテーブル (互換性のために当面は変更しない)
local player = {
    x = 1280 / 2,
    y = 720 / 2,
    speed = 200, -- Step1.2 互換性フォロー: 外部コードが参照する可能性のある初期値
    hp = 10, -- Step1.2 互換性フォロー: 外部コードが参照する可能性のある初期値
    xp = 0, -- Step1.2 互換性フォロー: 外部コードが参照する可能性のある初期値
    level = 1,
    invincible_timer = 0,
    xp_to_next_level = 3,
    _inst = nil -- Step1.2 互換委譲: Playerクラスのインスタンスを保持
}

-- Step1.2 互換委譲: 内部インスタンスから公開テーブルへ状態を同期するヘルパー関数
local function sync_state_from_instance()
    if not player._inst then return end -- nilチェック: インスタンスがない場合は何もしない
    player.x = player._inst.x
    player.y = player._inst.y
    player.speed = player._inst.speed
    player.hp = player._inst.hp
    player.xp = player._inst.xp
    player.level = player._inst.level
    player.invincible_timer = player._inst.invincible_timer
    player.xp_to_next_level = player._inst.xp_to_next_level
end

function player.load()
    -- Step1.2 互換委譲: Playerクラスのインスタンスを生成
    player._inst = Player:new()
    -- Step1.2 互換委譲: 初期状態を同期
    sync_state_from_instance()
end

function player.update(dt)
    -- Step1.2 互換委譲: 万が一loadが呼ばれていなくてもインスタンスを生成する (lazy-load)
    if not player._inst then player.load() end

    -- 処理を内部インスタンスに委譲
    player._inst:update(dt)
    -- 変更された状態を同期して互換性を維持
    sync_state_from_instance()
end

function player.draw()
    -- Step1.2 互換委譲: 処理を内部インスタンスに委譲
    if player._inst then
        player._inst:draw()
    else
        -- フォールバック: インスタンスがない場合は旧描画処理
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", player.x - 10, player.y - 10, 20, 20)
    end
end

function player.reset()
    -- Step1.2 互換委譲: 万が一loadが呼ばれていなくてもインスタンスを生成する (lazy-load)
    if not player._inst then player.load() end

    -- 処理を内部インスタンスに委譲
    player._inst:reset()
    -- 変更された状態を同期して互換性を維持
    sync_state_from_instance()
end

-- 既存の互換APIを壊さないため、playerテーブルとPlayerクラスの両方を返す
-- 呼び出し側(main.luaなど)は local player = require("player") で引き続きplayerテーブルを取得でき、動作に影響はない。
-- 2つ目の返り値(Player)は、今後のステップで利用するために公開している。
return player, Player



