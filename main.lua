io.stdout:setvbuf("no")
ui= require "libs.loveframes"
require "libs.util"
--require "ui"
bg= require "bg"

helper=require "b2helper"
cam = require("libs.gamera").new(-5000,-5000,10000,10000)
require "camera"
editor=require "editor"
--require "demo"


function love.update(dt)
	cam:update()	
	bg:update()
	editor:update(dt)
	ui.update(dt)
end

function love.draw()
	bg:draw()
	editor:draw()
	ui.draw()

end




function love.mousepressed(x, y, button)
	if button==1 then button="l"
	elseif button==2 then button="r" end
	ui.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	if button==1 then button="l"
	elseif button==2 then button="r" end
	editor:click(button)
	ui.mousereleased(x, y, button)
end

function love.keypressed(key, isrepeat)
	ui.keypressed(key, isrepeat)
	--if key == "f1" then ui.config["DEBUG"] = not ui.config["DEBUG"] end
end

function love.keyreleased(key)
	editor:keypress(key)
	ui.keyreleased(key)
end

function love.textinput(text)
	ui.textinput(text)
end

function love.wheelmoved(x, y)
    cam:scrollScale(y)
    if y > 0 then
        ui.mousepressed(x, y, "wu")
    elseif y < 0 then
        ui.mousepressed(x, y, "wd")
    end
end