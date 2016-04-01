local bg={}
local gridSize=64
local gridCanvas=love.graphics.newCanvas(gridSize,gridSize)
gridCanvas:setWrap('repeat','repeat')

love.graphics.setCanvas(gridCanvas)
love.graphics.setColor(0, 0, 255)
love.graphics.rectangle('line',0.5,0.5,gridSize,gridSize)	
love.graphics.setCanvas()

local screenQuad = love.graphics.newQuad(0,0,w(), h(), gridSize, gridSize)

function bg:update()
	screenQuad:setViewport(cam.x, cam.y+5, w(), h() )
end



function bg.draw()
	love.graphics.setColor(255, 255, 255, 155)
	--love.graphics.draw(gridCanvas,screenQuad)
	love.graphics.draw(gridCanvas,screenQuad,w()*(1-cam.scale)/2,h()*(1-cam.scale)/2,0,cam.scale,cam.scale)


	cam:draw(function()
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.line(-w()/2,0,w()/2,0)
	love.graphics.line(0, -h()/2, 0,h()/2)
	end)
end
	
return bg