local anim8 = require "lib.anim8"

return function(world, player, obj, entities)
  local pig
  local width = 16
  local height = 16
  local spritewidth = 34
  local spriteheight = 30
  local x = obj.x - width / 2
  local y = obj.y - height / 2

  local body = love.physics.newBody(world, x, y, "dynamic")
  local shape = love.physics.newRectangleShape(width, height)
  local fixture = love.physics.newFixture(body, shape)
  fixture:setFriction(0)
  fixture:setCategory(3)
  fixture:setMask(3)

  local image = love.graphics.newImage("assets/sprites/pig.png")
  local g = anim8.newGrid(spritewidth, spriteheight, image:getWidth(), image:getHeight())
  local crateimage = love.graphics.newImage("assets/sprites/crate.png")
  local crateg = anim8.newGrid(22, 16, crateimage:getWidth(), crateimage:getHeight())
  local anims = {
    normal = {
      idle = anim8.newAnimation(g("1-11", 1), 0.1),
      run = anim8.newAnimation(g("1-6", 2), 0.1),
      jump = anim8.newAnimation(g(1, 3), 0.1),
      fall = anim8.newAnimation(g(1, 4), 0.1),
      ground = anim8.newAnimation(g(1, 5), 0.1),
      attack = anim8.newAnimation(g("1-5", 6), 0.1,
        function()
          pig.attacking = false
          pig.attacktimeout = 0.3
        end),
      hit = anim8.newAnimation(g("1-2", 7), 0.1,
        function()
          pig.anim:pauseAtEnd()
          pig.damaged = false
          pig.anim:resume()
        end),
      dead = anim8.newAnimation(g("1-4", 8), 0.1,
        function()
          pig.anim:pauseAtEnd()
          pig:kill()
        end),
    },
    withCrate = {
      idle = anim8.newAnimation(g("1-9", 9), 0.1),
      run = anim8.newAnimation(g("1-6", 10), 0.1),
      pickup = anim8.newAnimation(g("1-5", 11), 0.1),
      throw = anim8.newAnimation(g("1-5", 12), 0.1),
    },
    withBomb = {
      idle = anim8.newAnimation(g("1-10", 13), 0.1),
      run = anim8.newAnimation(g("1-6", 14), 0.1),
      pickup = anim8.newAnimation(g("1-4", 15), 0.1),
      throw = anim8.newAnimation(g("1-5", 16), 0.1),
    },
    crate = {
      idle = anim8.newAnimation(crateg(1, 1), 0.1),
    },
    insideCrate = {
      peek = anim8.newAnimation(g("1-3", 17), { 0.1, 0.1, 0.4 },
        function()
          pig.anim = pig.anims.crate.idle
          pig.crate = true
          pig.peektimeout = 5
        end),
      prepare = anim8.newAnimation(g("1-2", 18), 0.1),
      jump = anim8.newAnimation(g("1-2", 19), 0.1),
      fall = anim8.newAnimation(g(1, 20), 0.1),
      ground = anim8.newAnimation(g(1, 21), 0.1),
    },
    match = {
      idle = anim8.newAnimation(g("1-3", 22), 0.1),
      light = anim8.newAnimation(g("1-3", 23), 0.1),
      cannon = anim8.newAnimation(g("1-3", 24), 0.1),
    },
  }
  local type_ = obj.type
  local anim = anims.normal.idle

  pig = {
    lives = 2,
    width = width,
    height = height,
    spritewidth = spritewidth,
    spriteheight = spriteheight,
    body = body,
    shape = shape,
    fixture = fixture,
    image = image,
    anims = anims,
    anim = anim,
    type = type_,
    dir = -1,
    attacktimeout = 0,
    attacking = false,
    damaged = false,
    attack = nil,
    crateimage = crateimage,
    crate = false,
    peektimeout = 5,
  }

  function pig:update(dt)
    if not player.dead then
      local x, y = self.body:getX(), self.body:getY()
    	local pdx, pdy = player.body:getLinearVelocity()
    	local xdist = player.body:getX() - x
    	local ydist = player.body:getY() - y

      if not self.attacking and not self.damaged then
        if self.attack then
          self.attack:destroy()
          self.attack = nil
        end

        if self.attacktimeout > 0 then
          self.attacktimeout = self.attacktimeout - dt
        end

        local dx, dy = self.body:getLinearVelocity()
      	if self.type == "normal" then
          if math.abs(xdist) < 24 and math.abs(ydist) < 10 then
            dx = 0
            dy = 0

            if self.attacktimeout <= 0 then
              self.anim = self.anims.normal.attack
              self.anim:gotoFrame(1)
              self.attacking = true

              if xdist < 0 then
                self.dir = -1
              else
                self.dir = 1
              end

              local body = love.physics.newBody(world, x + 4 * self.dir, y, "static")
              local shape = love.physics.newRectangleShape(16, 16)
              local fixture = love.physics.newFixture(body, shape)
              fixture:setSensor(true)
              fixture:setCategory(15)
              self.attack = fixture
            end
      	  elseif math.abs(xdist) < 128 and math.abs(ydist) < 10 then
      	  	self.anim = self.anims.normal.run
            if xdist < 0 then
              self.dir = -1
            else
              self.dir = 1
            end
            dx = self.dir * 50
      	  else
            self.anim = self.anims.normal.idle
            dx = 0.001
          end
      	elseif self.type == "insideCrate" then
          if self.peektimeout > 0 then
            self.peektimeout = self.peektimeout - dt
            self.anim = self.anims.crate.idle
            self.crate = true
          else
            self.anim = self.anims.insideCrate.peek
            self.crate = false
          end
        end

        self.body:setLinearVelocity(dx, dy)
      end
    else
      if not self.attacking then
        self.anim = self.anims.normal.idle
        self.body:setLinearVelocity(0, 0)
      end
    end

  	self.anim:update(dt)
  end

  function pig:draw()
  	if self.crate then
      local x = self.body:getX() + 4
      local y = self.body:getY() + 9

      self.anim:draw(self.crateimage, x, y, 0, 1, 1)
    else
      local x = self.body:getX() - self.width / 2 + 5
      local y = self.body:getY() - self.height / 2 + 3

      if self.dir == 1 then
        x = x + self.spritewidth + 5
      end

      self.anim:draw(self.image, x, y, 0, -self.dir, 1)
    end
  end

  function pig:label()
    return "Pig"
  end

  function pig:hit(nx)
    if self.attack then
      self.attack:destroy()
      self.attack = nil
    end
    if not self.damaged then
      self.damaged = true
      self.attacking = false
      self.lives = self.lives - 1
      if self.lives > 0 then
        self.anim = self.anims.normal.hit
        self.body:setLinearVelocity(nx * 200, -50)
      else
        self.anim = self.anims.normal.dead
        self.body:setLinearVelocity(nx * 100, -75)
      end
      self.anim:gotoFrame(1)
    end
  end

  function pig:kill()
    for i, entity in ipairs(entities) do
      if self == entity then
        table.remove(entities, i)
      end
    end

    self.fixture:destroy()
    self = nil
  end

  return pig
end
