local editor={}
editor.world= love.physics.newWorld(0, 9.8*64, false)
love.physics.setMeter(64)




------------------------------------------------------
editor.LoveFrames= require "libs.loveframes"
editor.helper = require "editor/b2dhelper"
--------------------------------------------------
editor.log = require "editor/log"(editor)
editor.bg = require "editor/bg"(editor)
editor.cam = require "editor/camera"(editor)
editor.selector= require "editor/selector"(editor)
editor.system= require "editor/system"(editor)
editor.units = require "editor/units"(editor)
editor.interface= require "editor/interface"(editor)
-------------------------------------------------------------
editor.createMode=require "modes/createMode"(editor)
editor.editMode= require "modes/editMode"(editor)
editor.vertMode= require "modes/vertMode"(editor)
editor.testMode= require "modes/testMode"(editor)
editor.jointMode= require "modes/jointMode"(editor)

--editor.world:update(1)

function editor:init()
	self.W = w()
	self.H = h()
	self.bg:init()
	self.state="Edit Mode"
	self.keys= self:keyBound()	
	self.interface:init()
	self.action="system start"
	editor.log:push("welcome to LoveBox2D editor !")
	

	local world=editor.world
	local box  = love.physics.newBody(world, 500, 200, "static")
	local shape = love.physics.newRectangleShape(50, 50)
	local fixture = love.physics.newFixture(box, shape, 1)

	local circle  = love.physics.newBody(world, 650, 200, "dynamic")
	local shape = love.physics.newCircleShape( 0, 0, 50)
	local fixture = love.physics.newFixture(circle, shape, 1)

	local joint = love.physics.newRopeJoint(box, circle, 500,200,650,200,150)




	local box  = love.physics.newBody(world, 600, 500, "static")
	local shape = love.physics.newRectangleShape(50, 50)
	local fixture = love.physics.newFixture(box, shape, 1)

	local circle  = love.physics.newBody(world, 600, 500, "dynamic")
	local shape = love.physics.newCircleShape( 0, 0, 50)
	local fixture = love.physics.newFixture(circle, shape, 1)

	local joint2 = love.physics.newRevoluteJoint(box,circle,600,500,false)

	joint2:setMotorEnabled(true)
	joint2:setMotorSpeed(10000)
	joint2:setMaxMotorTorque(10000)

end


function editor:update(dt)
	self.bg:update()
	self.cam:update()
	self.interface:update(dt)
	if not  self.interface:isHover() then --如果鼠标在ui上 而且是按下状态 则不更新系统

		if self.state=="Create Mode" then
			self.createMode:update()
		elseif self.state=="Test Mode" then
			self.testMode:update(dt)
			if not self.selector.selection then self.selector:update() end
		elseif self.state=="Vertex Mode" then
			self.vertMode:update()
		elseif self.state=="Joint Mode" then
			self.jointMode:update()
		else
			if not self.selector.dragSelecting then self.editMode:update() end
			if not self.editMode.dragMoving then self.selector:update() end
		end
	end
	if self.action then
		editor.log:push(self.action)
		editor.system:pushUndo()
		self.action=nil
	end

	if self.state=="Test Mode" and not self.testMode.pause then self.world:update(dt) end

end

function editor:drawKeyBounds()
	love.graphics.setColor(255, 255, 255, 255)
	for i,v in ipairs(self.keys) do
		love.graphics.print(v.key.."------"..v.name, 10,i*20)
	end

end

function editor:draw()
	
	self.bg:draw()
	--love.graphics.setColor(255,255,255,255)
	--love.graphics.printf(self.state, 0, 20, self.W/2, "center", 0, 2, 2)
	--self:drawKeyBounds()

	self.cam:draw(function()
		
		self.helper.draw(self.world)
		if self.state=="Create Mode" then
			self.createMode:draw()
		elseif self.state=="Vertex Mode" then
			self.vertMode:draw()
		elseif self.state=="Test Mode" then
			self.testMode:draw()
		elseif self.state=="Joint Mode" then
			self.jointMode:draw()
		end	

		self.selector:draw()
	end)

	self.LoveFrames.draw()

	self.units:draw()
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
	self.LoveFrames.keypressed(key, isrepeat)
	if self.interface:isHover() then return end
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
			if  not love.keyboard.isDown("lctrl")  and key==v.key then
				v.commad()
				break
			end
		end
	end
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
	self.state="Edit Mode"

	self:switchMode("edit")

end

function editor:switchMode(mode)
	for k,v in pairs(self.interface.toggleMode) do
		if k==mode then
			v.toggle=true
		else
			v.toggle=false
		end
	end
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
		selectNone=function() self.selector:clearSelection() end,

		alineHorizontal=function() self.editMode:aline(true) end,
		alineVerticle=function() self.editMode:aline(false) end,
		
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
		jointMode=function() self.jointMode:new() end,


		test=function() self.testMode:new() end,
		pause=function() self.testMode:togglePause() end,
		toggleMouse=function() self.testMode:toggleMouse() end,
		reset=function() self.testMode:reset() end,

		loadWorld=function() self.system:loadFromFile() end,
		saveWorld=function() self.system:saveToFile() end,

		togglePropFrameStyle=function() self.interface:nextTag() end,
		saveUnit=function() self.units:getSaveName() end,
		quickSave=function() self.units:quickSave() end,

		toggleSystem=function() self.interface.sysList:SetVisible(not self.interface.sysList:GetVisible()) end,
		togglePropFrameStyle=function()self.editMode:toggleBodyType() end, 
		toggleGrid=function() 
						self.interface.uiVisible[1].toggle=not self.interface.uiVisible[1].toggle
						editor.bg.visible=not editor.bg.visible
						editor.log.visible= not editor.log.visible
					end,
		toggleCreate=function()
						self.interface.uiVisible[2].toggle=not self.interface.uiVisible[2].toggle
						self.interface.createFrame:SetVisible(not self.interface.createFrame:GetVisible())
						self.interface.jointFrame:SetVisible(self.interface.createFrame:GetVisible())
					end,
		toggleProperty=function()
						self.interface.uiVisible[3].toggle=not self.interface.uiVisible[3].toggle
						if self.interface.propFrame then
							self.interface.propFrame:SetVisible(not self.interface.propFrame:GetVisible())
						end
					end,
		toggleUnit=function()
						self.interface.uiVisible[4].toggle=not self.interface.uiVisible[4].toggle
						self.interface.unitFrame:SetVisible(not self.interface.unitFrame:GetVisible())						
					end,
		toggleHistroy=function()
						self.interface.uiVisible[5].toggle=not self.interface.uiVisible[5].toggle
						self.interface.historyFrame:SetVisible(not self.interface.historyFrame:GetVisible())						
					end,
	}

	local keys ={}

	for commadName,key in pairs(require "editor/keyconf") do
		table.insert(keys, {key=key,commad=bound[commadName],name=commadName})
	end
	self.commmadBounds=bound
	
	return keys
end
--[[
local data  = love.image.newImageData("1.png")
local width, height = data:getDimensions()
local brickW=1
local brickH=1
local offx
local count=0
local scale=5
local step=5

for x=0,width-3,step do
	for y=0, height-3,step do
		if y%2==0 then 
			offx=0
		else
			offx=1
		end
		local r,g,b,a=data:getPixel( x, y )
		
		if r<250 or b<250 or g<250 then
			local body = love.physics.newBody(editor.world, x*scale-width*scale/2, y*scale-height*scale/2,"dynamic")
			local shape = love.physics.newRectangleShape(brickW*scale*step,brickH*scale*step)
			local fixture = love.physics.newFixture(body, shape)
		end
	end
end
]]

return editor


