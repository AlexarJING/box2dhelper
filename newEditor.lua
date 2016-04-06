local editor={}
editor.world= love.physics.newWorld(0, 9.8*64, false)
editor.bg = require "bg"(editor)
editor.cam = require "camera"(editor)
editor.helper = require "b2helper"
editor.LoveFrames= require "libs.loveframes"
editor.createMode=require "createMode"(editor)
editor.editMode= require "editMode"(editor)
editor.vertMode= require "vertMode"(editor)
editor.testMode= require "testMode"(editor)
editor.selector= require "selector"(editor)
editor.system= require "system"(editor)
--editor.preview = require "preview"
editor.log = require "log"

function editor:init()
	self.W = w()
	self.H = h()
	self.bg:init()
	self.state="Edit Mode"
	self.keys= self:keyBound()	
	love.physics.setMeter(64)
	self.objects={}
	self.action="system start"
	editor.log:push("welcome to LoveBox2D editor !")
end


function editor:update(dt)
	self.bg:update()
	self.cam:update()
	self.LoveFrames.update(dt)

	if self.state=="Create Mode" then
		self.createMode:update()
	elseif self.state=="Test Mode" then
		self.testMode:update(dt)
		if not self.selector.selection then self.selector:update() end
	elseif self.state=="Vertex Mode" then
		self.vertMode:update()
	else
		if not self.selector.dragSelecting then self.editMode:update() end
		if not self.editMode.dragMoving then self.selector:update() end
	end

	if self.action then
		editor.log:push(self.action)
		editor.system:pushUndo()
		self.action=nil
	end

end

function editor:drawKeyBounds()
	love.graphics.setColor(255, 255, 255, 255)
	for i,v in ipairs(self.keys) do
		love.graphics.print(v.key.."------"..v.name, 10,i*20)
	end

end

function editor:draw()
	
	self.bg:draw()
	love.graphics.setColor(255,255,255,255)
	love.graphics.printf(self.state, 0, 20, self.W/2, "center", 0, 2, 2)

	self.LoveFrames.draw()


	self:drawKeyBounds()
	self.log:draw(300,600)

	
	self.cam:draw(function()
		
		self.helper.draw(self.world)
		if self.state=="Create Mode" then
			self.createMode:draw()
		elseif self.state=="Vertex Mode" then
			self.vertMode:draw()
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
	if isrepeat then return end
	for i,v in ipairs(self.keys) do
		if string.sub(v.key,1,5)=="ctrl+" then
			local tkey=string.sub(v.key,6,-1)
			if love.keyboard.isDown("lctrl") and key==tkey then
				v.commad()
				print(v.name)
				break
			end
		elseif string.sub(v.key,1,4)=="alt+" then
			local tkey=string.sub(v.key,5,-1)
			if love.keyboard.isDown("lalt") and key==tkey then
				v.commad()
				print(v.name)
				break
			end
		else
			if not love.keyboard.isDown("lalt") and not love.keyboard.isDown("lctrl")  and key==v.key then
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
		createCircle=function() self.createMode:new("circle") end,
		createBox=function()  self.createMode:new("box") end,
		createLine=function() self.createMode:new("line") end,
		createEdge=function() self.createMode:new("edge") end,
		createPolygon=function()  self.createMode:new("polygon") end,
		createFreeline=function()  self.createMode:new("freeline") end,

		createDistance=function() self.createMode:distance() end,
		createRope=function() self.createMode:rope() end,
		createWeld=function() self.createMode:weld() end,
		createRevolute=function() self.createMode:revolute() end,
		createPrismatic=function() self.createMode:prismatic() end,
		createWheel=function() self.createMode:wheel() end,
		createPully=function() self.createMode:pully() end,

		cancel=function() self:cancel() end,
		selectAll=function() self.selector:selectAll() end,
		
		alineHorizontal=function() self.editMode:aline(false) end,
		alineVerticle=function() self.editMode:aline(true) end,
		
		removeBody=function() self.editMode:removeBody() end,
		removeJoint=function() self.editMode:removeJoint() end,
		copy=function() self.editMode:copy() end,
		paste=function() self.editMode:paste() end,
		combine=function() self.editMode:combine() end,
		divide=function() self.editMode:divide() end,
		toggleBodyType=function() self.editMode:toggleBodyType() end,
		undo=function() self.system:undo() end,
		redo=function() self.system:redo() end,

		vertexMode=function() self.vertMode:new() end,

		test=function() self.testMode:new() end,
		pause=function() self.testMode:togglePause() end,
		toggleMouse=function() self.testMode:toggleMouse() end,
		reset=function() self.testMode:reset() end,
	}

	local keys ={}

	for commadName,key in pairs(require "keyconf") do
		table.insert(keys, {key=key,commad=bound[commadName],name=commadName})
	end
	self.commmadBounds=bound
	
	return keys
end


return editor


