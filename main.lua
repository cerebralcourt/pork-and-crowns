require "lib.fun" ()
local cartographer = require "lib.cartographer"
local Camera = require "lib.brady"
local anim8 = require "lib.anim8"
local Player = require "player"
local Music = require "music"

math.randomseed(os.time())

local world, tilemap, entry, exit, player, cam, music, doorimage, entryanim, exitanim

function createFixture(col)
  local x = col.x
  local y = col.y

  if col.height == 12 then
    y = y - 10
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
  return love.physics.newFixture(body, shape)
end

function beginContact(a, b, coll)
  
end

function endContact(a, b, coll)
  
end

function preSolve(a, b, coll)
  
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
  if player.jumping and (player.fixture == a or player.fixture == b) then
    local nx, ny = coll:getNormal()

    if nx == 0 and ny == -1 and player.anim ~= player.anims.exit then
      player.jumping = false
      player.anim = player.anims.ground
      player.groundtimeout = 0.2
    end
  end
end

function love.load()
  love.window.setMode(640, 480, { resizable = true })
  love.window.setTitle("Pork and Crowns")
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setLineWidth(3)

  world = love.physics.newWorld(0, 9.81 * 32)
  tilemap = cartographer.load "levels/1_1.lua"

  local function objects(name)
    return totable(filter(function(obj) return obj.name == name end, tilemap.layers.Objects.objects))
  end

  entry = objects("Entry")[1]
  exit = objects("Exit")[1]

  for i, col in ipairs(tilemap.layers.Collisions.objects) do
    local fixture = createFixture(col)
    fixture:setFriction(0)
  end

  player = Player(world, entry, exit)
  cam = Camera(32 * 8, 32 * 6, { resizable = true, maintainAspectRatio = true })
  music = Music()

  doorimage = love.graphics.newImage("assets/sprites/door.png")
  local doorg = anim8.newGrid(46, 56, doorimage:getWidth(), doorimage:getHeight())
  exitanim = anim8.newAnimation(doorg("1-3", 1), 0.1, "pauseAtEnd")
  entryanim = anim8.newAnimation(doorg("1-3", 2), { 0.6, 0.1, 0.1 }, function() entryanim = nil end)

  world:setCallbacks(beginContact, endContact, preSolve, postSolve)
end

function love.update(dt)
  music:update(dt)
  world:update(dt)
  tilemap:update(dt)

  if entryanim then
    entryanim:update(dt)
  end

  player:update(dt)

  if player.anim == player.anims.exit then
    exitanim:update(dt)
  end

  cam.translationX = player.body:getX() + player.width / 2
  cam.translationY = player.body:getY() + player.height / 2
  cam:update()
end

function love.draw()
  love.graphics.clear(63 / 255, 56 / 255, 81 / 255)

  cam:push()

  tilemap:draw()

  if entryanim then
    entryanim:draw(doorimage, entry.x + 1, entry.y)
  end

  if player.anim == player.anims.exit then
    exitanim:draw(doorimage, exit.x, exit.y)
  end

  player:draw()

  cam:pop()
end
