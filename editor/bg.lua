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
	W=w()/editor.cam.scale
	H=h()/editor.cam.scale
	
	self.screenQuad = love.graphics.newQuad(0,0,W, H, gridSize, gridSize)
	screenQuad=self.screenQuad

	cam=self.editor.cam
	self.visible=editor.interface.visible.bg
	return self
end


function bg:resize()
	W=w()/editor.cam.scale
	H=h()/editor.cam.scale
	self.screenQuad = love.graphics.newQuad(0,0,W, H, gridSize, gridSize)
	screenQuad=self.screenQuad
end


function bg:update()
	screenQuad:setViewport(cam.x-W/cam.scale, cam.y-H/cam.scale, W, H )
end



function bg:draw()
	if not self.visible then return end
	love.graphics.setColor(255, 255, 255, 155)
	love.graphics.draw(gridCanvas,screenQuad,0,0,0,cam.scale,cam.scale)
	cam:draw(function()

	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.line(-W/2,0,W/2,0)
	love.graphics.line(0, -H/2, 0,H/2)
	end)
	editor.log:draw()
end
return function(parent) 
	editor=parent
	bg.editor=editor
	bg.cam=editor.cam
	return bg
end
