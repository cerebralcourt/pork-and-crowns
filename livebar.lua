local anim8 = require "lib.anim8"

return function()
  local livebar

  local barimage = love.graphics.newImage("assets/sprites/livebar.png")

  local livesimage = love.graphics.newImage("assets/sprites/lives.png")
  local g = anim8.newGrid(18, 14, livesimage:getWidth(), livesimage:getHeight())
  local heart = anim8.newAnimation(g("1-8", 1), 0.1)
  local hearthit = {
    anim = anim8.newAnimation(g("1-2", 2), 0.1, function() livebar.hearthit.pos = 0 end),
    pos = 0,
  }
  local diamond = anim8.newAnimation(g("1-8", 3), 0.1)

  local numimage = love.graphics.newImage("assets/sprites/numbers.png")
  local numg = anim8.newGrid(6, 8, numimage:getWidth(), numimage:getHeight())
  local numbers = anim8.newAnimation(numg("1-10", 1), 0.1)
  numbers:pause()
  numbers:gotoFrame(10)

  livebar = {
    barimage = barimage,
    livesimage = livesimage,
    numimage = numimage,
    heart = heart,
    hearthit = hearthit,
    diamond = diamond,
    numbers = numbers,
    lives = 3,
    diamonds = 0,
  }

  function livebar:update(dt)
  	self.heart:update(dt)
    self.diamond:update(dt)

    if self.hearthit.pos > 0 then
      self.hearthit.anim:update(dt)
    end
    
    self.numbers:update(dt)
  end

  function livebar:draw()
    local scale = 2

  	love.graphics.draw(self.barimage, 0, 0, 0, scale, scale)

    if self.lives >= 1 then
      self.heart:draw(self.livesimage, 22, 19, 0, scale, scale)
    end
    if self.lives >= 2 then
      self.heart:draw(self.livesimage, 43, 19, 0, scale, scale)
    end
    if self.lives >= 3 then
      self.heart:draw(self.livesimage, 65, 19, 0, scale, scale)
    end

    if self.hearthit.pos == 1 then
      self.hearthit.anim:draw(self.livesimage, 22, 18, 0, scale, scale)
    elseif self.hearthit.pos == 2 then
      self.hearthit.anim:draw(self.livesimage, 43, 18, 0, scale, scale)
    elseif self.hearthit.pos == 3 then
      self.hearthit.anim:draw(self.livesimage, 65, 18, 0, scale, scale)
    end

    local x, y = self.barimage:getWidth() - 28, self.barimage:getHeight() * 2 - 18
    self.diamond:draw(self.livesimage, x, y, 0, scale, scale)
    self.numbers:draw(self.numimage, x + 36, y + 4, 0, scale, scale)
  end

  function livebar:hit()
    self.hearthit.pos = self.lives
  	self.lives = self.lives - 1
  end

  function livebar:addHeart()
    self.lives = self.lives + 1
  end

  function livebar:addDiamond()
    self.diamonds = self.diamonds + 1
    if self.diamonds == 10 then
      self.diamonds = 0
      self.numbers:gotoFrame(10)
    else
      self.numbers:gotoFrame(self.diamonds)
    end
  end

  function livebar:isdead()
    return self.lives == 0
  end

  return livebar
end
