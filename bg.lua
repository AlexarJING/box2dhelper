local bg={}
local editor

local gridSize
local screenQuad
local gridCanvas
local W
local H
local cam

function bg:init()
	self.gridSize=64
	gridSize=self.gridSize
	
	self.gridCanvas=love.graphics.newCanvas(gridSize,gridSize)
	gridCanvas=self.gridCanvas
	gridCanvas:setWrap('repeat','repeat')
	love.graphics.setCanvas(gridCanvas)
	love.graphics.setColor(0, 0, 255)
	love.graphics.rectangle('line',0.5,0.5,gridSize,gridSize)	
	love.graphics.setCanvas()
	
	W=self.editor.W
	H=self.editor.H
	self.screenQuad = love.graphics.newQuad(0,0,W, H, gridSize, gridSize)
	screenQuad=self.screenQuad

	cam=self.editor.cam
	return self
end



function bg:update()
	screenQuad:setViewport(cam.x, cam.y+5, W, H )
end



function bg.draw()
	love.graphics.setColor(255, 255, 255, 155)
	love.graphics.draw(gridCanvas,screenQuad,W*(1-cam.scale)/2,H*(1-cam.scale)/2,0,cam.scale,cam.scale)

	cam:draw(function()
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.line(-W/2,0,W/2,0)
	love.graphics.line(0, -H/2, 0,H/2)
	end)
end
	
return function(editor) bg.editor=editor; bg.cam=editor.cam ; return bg end