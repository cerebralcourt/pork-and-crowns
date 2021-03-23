local cartographer = require "lib.cartographer"
local Camera = require "lib.brady"
local anim8 = require "lib.anim8"
local Player = require "player"
local Livebar = require "livebar"
local Pig = require "entities.pig"

local world,
      tilemap,
      cam,
      player,
      livebar,
      entry,
      exit,
      entities,
      doorimage,
      entryanim,
      exitanim,
      nextFrame

local function createFixture(col)
  local x = col.x
  local y = col.y

  if col.height == 12 then
    y = y - 10
  end

  if col.height == 4 then
    y = y - 14
    x = x - 8
  end

  if col.width > col.height then
    if col.width == 64 then
      x = x + 16
    else
      x = x + col.width / 2
    end
  elseif col.height > col.width then
    if col.height == 64 then
      y = y + 16
    else
      y = y + col.height / 2
    end
  end

  local body = love.physics.newBody(world, x, y)
  local shape = love.physics.newRectangleShape(col.width, col.height)
  local fixture = love.physics.newFixture(body, shape)
  fixture:setFriction(0)
  return fixture
end

local function beginContact(a, b, coll)
  local fixture = nil
  local x1, y1, x2, y2
  if player.fixture == a then
    fixture = b
  elseif player.fixture == b then
    fixture = a
  end

  if fixture then
    if fixture:getCategory() == 2 then
      local y1 = player.body:getY()
      local y2 = fixture:getBody():getY()

      if y1 < y2 then
        if fixture:isSensor() then
          nextFrame = function() fixture:setSensor(false) end
        end
      else
        fixture:setSensor(true)
      end
    elseif fixture:getCategory() == 15 then
      local x1 = player.body:getX()
      local x2 = fixture:getBody():getX()

      local nx
      if x1 < x2 then
        nx = -1
      else
        nx = 1
      end

      player:hit(nx)
      livebar:hit()
    end
  else
    local entity = nil
    local fixture = nil

    for i, e in ipairs(entities) do
      if e.fixture == a then
        entity = e
        fixture = b
      elseif e.fixture == b then
        entity = e
        fixture = a
      end
    end

    if entity then
      if entity:label() == "Pig" then
        if fixture:getCategory() == 2 then
          local y1 = entity.body:getY()
          local y2 = fixture:getBody():getY()

          if y1 < y2 then
            if fixture:isSensor() then
              nextFrame = function() fixture:setSensor(false) end
            end
          else
            fixture:setSensor(true)
          end
        elseif fixture:getCategory() == 16 then
          local x1 = entity.body:getX()
          local x2 = fixture:getBody():getX()

          local nx
          if x1 < x2 then
            nx = -1
          else
            nx = 1
          end

          entity:hit(nx)
        end
      end
    end
  end
end

local function endContact(a, b, coll)
  
end

local function preSolve(a, b, coll)
  
end

local function postSolve(a, b, coll, normalimpulse, tangentimpulse)
  local fixture = nil
  local x1, y1, x2, y2
  if player.fixture == a then
    fixture = b
  elseif player.fixture == b then
    fixture = a
  end

  if fixture then
    if player.jumping and (fixture:getCategory() == 1 or fixture:getCategory() == 2) then
      local nx, ny = coll:getNormal()

      if nx == 0 and ny == -1 and player.anim ~= player.anims.exit then
        player.jumping = false
        player.groundtimeout = 0.2
      end
    end
  end
end

return function(name)
  local screen = {}

  function screen:init(screens, changeScreen)
    world = love.physics.newWorld(0, 9.81 * 32)
  	tilemap = cartographer.load("levels/" .. name .. ".lua")
    cam = Camera(32 * 8, 32 * 6, { resizable = true, maintainAspectRatio = true })

    local function objects(name)
      return totable(filter(function(obj) return obj.name == name end, tilemap.layers.Objects.objects))
    end

    entry = objects("Entry")[1]
    exit = objects("Exit")[1]
    entities = {}

    for i, col in ipairs(tilemap.layers.Collisions.objects) do
      createFixture(col)
    end

    for i, col in ipairs(tilemap.layers.Sensors.objects) do
      local fixture = createFixture(col)
      fixture:setSensor(true)
      fixture:setCategory(col.type or 1)
    end

    player = Player(world, entry, exit)
    livebar = Livebar()

    for i, obj in ipairs(objects("Pig")) do
      table.insert(entities, Pig(world, player, obj, entities))
    end

    -- for i, obj in ipairs(objects("Crate")) do
    --   table.insert(entities, Crate(world, obj))
    -- end

    -- for i, obj in ipairs(objects("Bomb")) do
    --   table.insert(entities, Bomb(world, obj))
    -- end

    doorimage = love.graphics.newImage("assets/sprites/door.png")
    local doorg = anim8.newGrid(46, 56, doorimage:getWidth(), doorimage:getHeight())
    exitanim = anim8.newAnimation(doorg("1-5", 1), { 0.1, 0.1, 0.1, 0.1, 0.4 },
      function()
        exitanim:pauseAtEnd()
        changeScreen(screens.levels[1][1])
      end)
    entryanim = anim8.newAnimation(doorg("1-3", 2), { 0.6, 0.1, 0.1 }, function() entryanim = nil end)

    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
  end

  function screen:update(dt)
    if nextFrame then
      nextFrame()
      nextFrame = nil
    end

    world:update(dt)
    tilemap:update(dt)

    if entryanim then
      entryanim:update(dt)
    end

    for i, entity in ipairs(entities) do
      entity:update(dt)
    end

    player:update(dt)

    if player.anim == player.anims.exit then
      exitanim:update(dt)
    end

    livebar:update(dt)

    cam.translationX = player.body:getX() + player.width / 2
    cam.translationY = player.body:getY() + player.height / 2
    cam:update()
  end

  function screen:draw()
    cam:push()

    tilemap:draw()

    if entryanim then
      entryanim:draw(doorimage, entry.x + 1, entry.y)
    end

    if player.anim == player.anims.exit then
      exitanim:draw(doorimage, exit.x, exit.y)
    end

    for i, entity in ipairs(entities) do
      entity:draw()
    end

    player:draw()

    cam:pop()

    livebar:draw()
  end

  function screen:clean()
    world:destroy()
    entities = {}
  end

  function screen:isdead()
    return player.dead
  end

  return screen
end
