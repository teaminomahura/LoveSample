-- 最重要方針：既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- 変更点：移動速度プロパティを move_speed に統一（互換のため legacy の speed も常に同期）
-- 既存の機能・挙動・引数互換は保持（Player:new(x,y) / Player:new{...} の両対応）

local Player = {}
Player.__index = Player

-- 互換：move_speed と legacy speed を常に同値に保つ
local function sync_speed(self)
  if self.move_speed == nil then
    self.move_speed = (self.speed ~= nil) and self.speed or 140
  end
  self.speed = self.move_speed
end

function Player:new(a, b)
  local obj = setmetatable({}, self)
  if type(a) == "table" then
    local o = a
    obj.x = o.x or 200
    obj.y = o.y or 200
    obj.w = o.w or 20
    obj.h = o.h or 20
    obj.move_speed = o.move_speed or o.speed or 140
  else
    obj.x = a or 200
    obj.y = b or 200
    obj.w = 20
    obj.h = 20
    obj.move_speed = 140
  end
  sync_speed(obj)
  return obj
end

function Player:update(dt)
  local dx, dy = 0, 0
  if love.keyboard.isDown("left","a")  then dx = dx - 1 end
  if love.keyboard.isDown("right","d") then dx = dx + 1 end
  if love.keyboard.isDown("up","w")    then dy = dy - 1 end
  if love.keyboard.isDown("down","s")  then dy = dy + 1 end

  if dx ~= 0 or dy ~= 0 then
    local len = math.sqrt(dx*dx + dy*dy)
    dx, dy = dx/len, dy/len
    -- ここを move_speed で統一（内部で legacy speed も同期）
    self.x = self.x + dx * self.move_speed * dt
    self.y = self.y + dy * self.move_speed * dt
  end

  -- 毎フレーム同期（外部から speed を直接触られても整合を保つ）
  sync_speed(self)
end

function Player:draw()
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle("line", self.x - self.w/2, self.y - self.h/2, self.w, self.h)
end

return Player








