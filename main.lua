require "libs.util"
editor=require "newEditor"

function love.load()
	editor:init()
	tab=loadstring(table.save({a=1,b=2,c={d=1,e=2},d=function() return 2 end},"abc",true))()
	print(tab.d())
end

function love.update(dt)
	editor:update(dt)
end

function love.draw()
	editor:draw()
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