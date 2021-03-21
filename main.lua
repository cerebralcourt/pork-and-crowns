require "lib.fun" ()
local cartographer = require "lib.cartographer"
local Camera = require "lib.brady"
local Player = require "player"

local world, tilemap, entry, exit, player, cam

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

    if nx == 0 and ny == -1 then
      player.jumping = false
      player.anim = player.anims.ground
      player.groundtimeout = 0.2
    end
  end
end

function love.load()
  love.window.setMode(640, 480, { resizable = true })
  love.window.setTitle("Kings and Pigs")
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

  player = Player(world, entry)
  cam = Camera(32 * 8, 32 * 6, { resizable = true, maintainAspectRatio = true })

  world:setCallbacks(beginContact, endContact, preSolve, postSolve)
end

function love.update(dt)
  world:update(dt)
  tilemap:update(dt)
  player:update(dt)
  cam.translationX = player.body:getX() + player.width / 2
  cam.translationY = player.body:getY() + player.height / 2
  cam:update()
end

function love.draw()
  love.graphics.clear(63 / 255, 56 / 255, 81 / 255)
  cam:push()
  tilemap:draw()
  player:draw()
  cam:pop()
end
