local anim8 = require "lib.anim8"

return function(world, obj)
  local width = 16
  local height = 16
  local spritewidth = 34
  local spriteheight = 28
  local x = obj.x - width / 2
  local y = obj.y - height / 2

  local body = love.physics.newBody(world, x, y, "dynamic")
  local shape = love.physics.newRectangleShape(width, height)
  local fixture = love.physics.newFixture(body, shape)
  fixture:setFriction(0)
  fixture:setMask(16)

  local image = love.graphics.newImage("assets/sprites/pig.png")
  local g = anim8.newGrid(spritewidth, spriteheight, image:getWidth(), image:getHeight())
  local anims = {
    normal = {
      idle = anim8.newAnimation(g("1-11", 1), 0.1),
      run = anim8.newAnimation(g("1-6", 2), 0.1),
      jump = anim8.newAnimation(g(1, 3), 0.1),
      fall = anim8.newAnimation(g(1, 4), 0.1),
      ground = anim8.newAnimation(g(1, 5), 0.1),
      attack = anim8.newAnimation(g("1-5", 6), 0.1),
      hit = anim8.newAnimation(g("1-2", 7), 0.1),
      dead = anim8.newAnimation(g("1-4", 8), 0.1),
    },
  }
  -- local type_ = obj.type
  local type_ = "normal"
  local anim = "idle"

  local pig = {
    width = width,
    height = height,
    spritewidth = spritewidth,
    spriteheight = spriteheight,
    body = body,
    shape = shape,
    fixture = fixture,
    image = image,
    anims = anims,
    type = type_,
    anim = anim,
    dir = 1,
  }

  function pig:update(dt)
  	self.anims[self.type][self.anim]:update(dt)
  end

  function pig:draw()
  	local x = self.body:getX() - self.width / 2 + 5
    local y = self.body:getY() - self.height / 2 + 5
  	self.anims[self.type][self.anim]:draw(self.image, x, y, 0, self.dir, 1)
  end

  return pig
end
