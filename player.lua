local baton = require "lib.baton"
local anim8 = require "lib.anim8"

local player

local input = baton.new {
  controls = {
    left = {"key:left", "key:a", "axis:leftx-", "button:dpleft"},
    right = {"key:right", "key:d", "axis:leftx+", "button:dpright"},
    jump = {"key:up", "key:w", "key:space", "axis:lefty-", "button:dpup", "button:a"},
    attack = {"key:down", "key:s", "axis:lefty+", "button:dpdown", "button:x", "mouse:1"},
  },
  joystick = love.joystick.getJoysticks()[1],
}

return function(world, entry, exit, livebar)
  local width = 26
  local height = 26
  local spritewidth = 78
  local spriteheight = 58
  local x = entry.x + entry.width / 2 - width / 2
  local y = entry.y + entry.height - height / 2

  local body = love.physics.newBody(world, x, y, "dynamic")
  local shape = love.physics.newRectangleShape(width, height)
  local fixture = love.physics.newFixture(body, shape)
  fixture:setFriction(0)
  fixture:setMask(3)

  local image = love.graphics.newImage("assets/sprites/king-hammer.png")
  local g = anim8.newGrid(spritewidth, spriteheight, image:getWidth(), image:getHeight())
  local anims = {
    idle = anim8.newAnimation(g("1-11", 1), 0.1),
    run = anim8.newAnimation(g("1-8", 2), 0.1),
    jump = anim8.newAnimation(g(1, 3), 0.1),
    fall = anim8.newAnimation(g(1, 4), 0.1),
    ground = anim8.newAnimation(g(1, 5), 0.1),
    attack = anim8.newAnimation(g("1-3", 6), 0.1,
      function()
        player.anim:pauseAtEnd()
        player.attacking = false
        player.anim:resume()
        player.attacktimeout = 0.5
      end),
    hit = anim8.newAnimation(g("1-2", 7), 0.1,
      function()
        player.anim:pauseAtEnd()
        player.damaged = false
        player.anim:resume()
        if player.livebar:isdead() then
          player.anim = player.anims.dead
          player.dead = true
        end
      end),
    dead = anim8.newAnimation(g("1-4", 8), 0.1,
      function()
        player.anim:pauseAtEnd()
        player:kill()
      end),
    exit = anim8.newAnimation(g("1-8", 9), 0.1, function() player.anim:pauseAtEnd() end),
    enter = anim8.newAnimation(g("1-8", 10), 0.1,
      function()
        player.anim:pauseAtEnd()
        player.entering = false
      end),
  }
  local anim = anims.enter

  player = {
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
    dir = 1,
    livebar = livebar,
    groundtimeout = 0,
    attacktimeout = 0,
    jumping = false,
    attacking = false,
    entering = true,
    damaged = false,
    attack = nil,
    dead = false,
  }

  function player:update(dt)
    input:update()

    local dx, dy = self.body:getLinearVelocity()

    if self.dead then
      if math.abs(dy) < 0.1 then
        dx = 0
      end
      self.body:setLinearVelocity(dx, dy)
    elseif not self.entering and not self.damaged then
      if self.attacking then
        dx = 0
        dy = 0
      else
        if self.attack then
          self.attack:destroy()
          self.attack = nil
        end

        if input:down("left") then
          dx = -64
          self.dir = -1
        elseif input:down("right") then
          dx = 64
          self.dir = 1
        else
          dx = self.dir / 1000
        end

        if self.jumping then
          if dy < 0 then
            self.anim = self.anims.jump
          elseif dy > 0 then
            self.anim = self.anims.fall
          end
        else
          if input:down("jump") then
            dy = -150
            self.jumping = true
          end
          if self.groundtimeout <= 0 then
            if dx > 0.001 then
              self.anim = self.anims.run
            elseif dx < -0.001 then
              self.anim = self.anims.run
            else
              self.anim = self.anims.idle
            end
          elseif not self.attacking then
            self.anim = self.anims.ground
            self.groundtimeout = self.groundtimeout - dt
          end
        end

        if self.attacktimeout > 0 then
          self.attacktimeout = self.attacktimeout - dt
        end

        if input:down("attack") then
          local x = self.body:getX()
          local y = self.body:getY()

          if x - self.width / 2 > exit.x - exit.width / 2
          and y - self.height / 2 > exit.y - exit.height / 2
          and x + self.width / 2 < exit.x + exit.width
          and y + self.height / 2 < exit.y + exit.height
          then
            self.entering = true
            self.anim = self.anims.exit
            local x = exit.x + exit.width / 2 - width / 2
            local y = exit.y + exit.height - height / 2
            self.body:setPosition(x, y)
            dx = 0
            dy = 0
          elseif self.attacktimeout <= 0 then
            self.attacking = true
            self.anim = self.anims.attack
            self.anim:gotoFrame(1)

            local body = love.physics.newBody(world, x + 4 * self.dir, y, "static")
            local shape = love.physics.newRectangleShape(32, 56)
            local fixture = love.physics.newFixture(body, shape)
            fixture:setSensor(true)
            fixture:setCategory(16)
            fixture:setMask(1)
            self.attack = fixture
          end
        end
      end

      self.body:setLinearVelocity(dx, dy)
    end

    self.anim:update(dt)
  end

  function player:draw()
    local x = self.body:getX() - self.width / 2 - 3.5
    local y = self.body:getY() - self.height / 2 - 1

    if self.dir == -1 then
      x = x + self.spritewidth - self.width / 2
    end

    self.anim:draw(self.image, x, y, 0, self.dir, 1)
  end

  function player:hit(nx)
    if not self.damaged and not self.dead then
      self.damaged = true
      self.attacking = false
      self.body:setLinearVelocity(nx * 100, -50)
      self.anim = self.anims.hit
      self.anim:gotoFrame(1)
      self.livebar:hit()
    end
  end

  function player:kill()
    if self.attack then
      self.attack:destroy()
      self.attack = nil
    end
  end

  return player
end
