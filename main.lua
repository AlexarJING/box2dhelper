if arg[#arg] == "-debug" then require("mobdebug").start() end 
require "libs.util"

local editor=require "editor/editor"

function love.filedropped( file )
	editor.createMode:importFromImage(file)
end


function love.load()
	editor:init()
end

function love.update(dt)
	editor:update(dt)
end

function love.draw()
	editor:draw()
	--if canvas then love.graphics.draw(canvas) end
end

function love.mousepressed(x, y, button)
	editor:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	editor:mousereleased(x, y, button)
end

function love.keypressed(key, scancode, isrepeat )
	editor:keypressed(key, isrepeat)
end

function love.keyreleased(key)
	editor:keyreleased(key)
end

function love.textinput(text)
	editor:textinput(text)
end

function love.wheelmoved(x, y)
    editor:wheelmoved(x, y)
end