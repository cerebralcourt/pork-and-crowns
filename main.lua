require "lib.fun" ()
local Camera = require "lib.brady"
local Music = require "music"
local Level = require "screens.level"

math.randomseed(os.time())

local world, cam, music, screens, screen

function changeScreen(nextScreen)
  screen:clean()
  screen = nextScreen
  screen:init(screens, changeScreen)
end

function love.load()
  love.window.setMode(640, 480, { resizable = true })
  love.window.setTitle("Pork and Crowns")
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setLineWidth(3)

  cam = Camera(32 * 8, 32 * 6, { resizable = true, maintainAspectRatio = true })
  music = Music()
  screens = {
    levels = {
      {
        Level("1_1"),
      },
    },
  }
  screen = screens.levels[1][1]
  screen:init(screens, changeScreen)
end

function love.update(dt)
  music:update(dt)
  screen:update(dt)

  cam.translationX = screen:getX()
  cam.translationY = screen:getY()
  cam:update()
end

function love.draw()
  love.graphics.clear(63 / 255, 56 / 255, 81 / 255)
  cam:push()
  screen:draw()
  cam:pop()
end
