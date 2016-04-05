local editor={}
editor.world= love.physics.newWorld(0, 9.8*64, false)
editor.bg = require "bg"(editor)
editor.cam = require "camera"(editor)
editor.helper = require "b2helper"
editor.LoveFrames= require "libs.loveframes"
editor.createMode=require "createMode"(editor)
editor.editMode= require "editMode"(editor)
--editor.vertMode= require "vertMode"
--editor.testMode= require "testMode"
editor.selector= require "selector"(editor)
--editor.preview = require "preview"


function editor:init()
	self.W = w()
	self.H = h()
	self.bg:init()
	self.state="Edit Mode"
	self.keys= self:keyBound()
	self.mouseX =
	
	love.physics.setMeter(64)
	self.objects={}

end


function editor:update(dt)
	self.bg:update()
	self.cam:update()
	self.LoveFrames.update(dt)

	if self.state=="Create Mode" then
		self.createMode:update()
	--elseif self.state=="Test Mode" and not self.testMode.pause then
		--self.world:update(dt)
	else
		if not self.selector.dragSelecting then self.editMode:update() end
		if not self.editMode.dragMoving then self.selector:update() end
		
	end

	

end

function editor:draw()
	
	self.bg:draw()
	love.graphics.setColor(255,255,255,255)
	love.graphics.printf(self.state, 0, 20, self.W/2, "center", 0, 2, 2)

	self.LoveFrames.draw()

	
	self.cam:draw(function()
		
		self.helper.draw(self.world)
		if self.state=="Create Mode" then
			self.createMode:draw()
		end	

		self.selector:draw()
	end)
end


-------------------------------------------------------------

function editor:mousepressed(x, y, button)
	if button==1 then button="l"
	elseif button==2 then button="r" end
	self.LoveFrames.mousepressed(x, y, button)
end

function editor:mousereleased(x, y, button)
	if button==1 then button="l"
	elseif button==2 then button="r" end
	editor.selector:click(button)
	self.LoveFrames.mousereleased(x, y, button)
end

function editor:keypressed(key, isrepeat)
	for i,v in ipairs(self.keys) do
		if string.sub(v.key,1,5)=="ctrl+" then
			local tkey=string.sub(v.key,6,-1)
			if love.keyboard.isDown("lctrl") and key==tkey then
				v.commad()
				break
			end
		elseif string.sub(v.key,1,4)=="alt+" then
			local tkey=string.sub(v.key,5,-1)
			if love.keyboard.isDown("lalt") and key==tkey then
				v.commad()
				break
			end
		else
			if key==v.key then
				v.commad()
				break
			end
		end
	end
	self.LoveFrames.keypressed(key, isrepeat)
end

function editor:keyreleased(key)
	self.LoveFrames.keyreleased(key)
end

function editor:textinput(text)
	self.LoveFrames.textinput(text)
end

function editor:wheelmoved(x, y)
    self.cam:scrollScale(y)
    if y > 0 then
        self.LoveFrames.mousepressed(x, y, "wu")
    elseif y < 0 then
        self.LoveFrames.mousepressed(x, y, "wd")
    end
end
-------------------------------------------------------------------------


function editor:cancel()
	self.createMode:cancel()
	self.selector:clearSelection()

end


function editor:keyBound()
	local bound={
		createCircle=function() self:cancel();self.state="Create Mode"; self.createMode:new("circle") end,
		createBox=function() self:cancel();self.state="Create Mode"; self.createMode:new("box") end,
		createLine=function() self:cancel();self.state="Create Mode"; self.createMode:new("line") end,
		createEdge=function() self:cancel();self.state="Create Mode"; self.createMode:new("edge") end,
		createPolygon=function() self:cancel();self.state="Create Mode"; self.createMode:new("polygon") end,
		createFreeline=function() self:cancel();self.state="Create Mode"; self.createMode:new("freeline") end,

		cancel=function() self:cancel() end,
		selectAll=function() self.selector:selectAll() end,
		alineHorizontal=function() self.editMode:aline(false) end,
		alineVerticle=function() self.editMode:aline(true) end,
	}

	local keys ={}
	for commadName,key in pairs(require "keyconf") do
		table.insert(keys, {key=key,commad=bound[commadName]})
	end
	return keys
end


return editor


