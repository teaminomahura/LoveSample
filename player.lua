-- player.lua (simple square player with :new())
local Player = {}
Player.__index = Player

function Player:new(x, y)
  local obj = setmetatable({}, self)
  obj.x = x or 200
  obj.y = y or 200
  obj.w = 20
  obj.h = 20
  obj.speed = 140
  return obj
end

function Player:update(dt)
  local dx, dy = 0, 0
  if love.keyboard.isDown("left","a") then dx = dx - 1 end
  if love.keyboard.isDown("right","d") then dx = dx + 1 end
  if love.keyboard.isDown("up","w") then dy = dy - 1 end
  if love.keyboard.isDown("down","s") then dy = dy + 1 end
  if dx ~= 0 or dy ~= 0 then
    local len = math.sqrt(dx*dx + dy*dy)
    dx, dy = dx/len, dy/len
    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt
  end
end

function Player:draw()
  love.graphics.setColor(1,1,1,1)
  love.graphics.rectangle("line", self.x - self.w/2, self.y - self.h/2, self.w, self.h)
end

return Player







