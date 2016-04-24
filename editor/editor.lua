local editor={}
editor.world= love.physics.newWorld(0, 0, false)
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
editor.bodyMode= require "modes/bodyMode"(editor)
editor.shapeMode= require "modes/shapeMode"(editor)
editor.testMode= require "modes/testMode"(editor)
editor.jointMode= require "modes/jointMode"(editor)
editor.fixtureMode= require "modes/fixtureMode"(editor)


function editor:init()
	
	local body  = love.physics.newBody(self.world, 0, 0, "static")
	body:setLinearDamping(3)
	local shape   = love.physics.newRectangleShape(100,300)
	local fixture = love.physics.newFixture(body, shape, 1)
	fixture:setRestitution(0)
	fixture:setFriction(99)
	fixture:setUserData({
		{prop="material",value="rock"},
		{prop="hardness",value=3},
		{prop="magnet",value=1},
		 })
	editor.createMode:magnetField(fixture)


	local body  = love.physics.newBody(self.world, 100, -200, "dynamic")
	body:setLinearDamping(3)
	body:getAngularDamping(3)
	local shape   = love.physics.newRectangleShape(30,100)
	local fixture = love.physics.newFixture(body, shape, 2)
	fixture:setRestitution(0)
	fixture:setFriction(99)
	fixture:setUserData({
		{prop="material",value="rock"},
		{prop="hardness",value=3},
		{prop="magnet",value=-1},
		 })
	editor.createMode:magnetField(fixture)


	local body  = love.physics.newBody(self.world, -100, 200, "dynamic")
	body:setLinearDamping(3)
	body:getAngularDamping(3)
	local shape   = love.physics.newRectangleShape(30,100)
	local fixture = love.physics.newFixture(body, shape, 2)
	fixture:setRestitution(0)
	fixture:setFriction(99)
	fixture:setUserData({
		{prop="material",value="rock"},
		{prop="hardness",value=3},
		{prop="magnet",value=1},
		 })
	editor.createMode:magnetField(fixture)

	self.W = w()
	self.H = h()
	self.bg:init()
	self.state="body"
	self.keys= self:keyBound()	
	self.interface:init()
	self.action="system start"
	editor.log:push("welcome to LoveBox2D editor !")

end


function editor:update(dt)
	self.bg:update()
	self.cam:update()
	self.interface:update(dt)
	if not  self.interface:isHover() then --如果鼠标在ui上 而且是按下状态 则不更新系统

		if self.state=="create" then
			self.createMode:update()
		elseif self.state=="test" then
			self.testMode:update(dt)
		elseif self.state=="shape" then
			self.shapeMode:update()
		elseif self.state=="joint" then
			self.jointMode:update()
		elseif self.state=="fixture" then
			--
		else
			if not self.selector.dragSelecting then self.bodyMode:update() end
			if not self.bodyMode.dragMoving then self.selector:update() end
		end
	end
	if self.action then
		editor.log:push(self.action)
		editor.system:pushUndo()
		self.action=nil
	end

	if self.state=="test" and not self.testMode.pause then 
		self.world:update(dt) 
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


	self.cam:draw(function()
		
		self.helper.draw(self.world)
		if self.state=="create" then
			self.createMode:draw()
		elseif self.state=="shape" then
			self.shapeMode:draw()
		elseif self.state=="test" then
			self.testMode:draw()
			self.selector:draw()
		elseif self.state=="joint" then
			self.jointMode:draw()
		elseif self.state=="fixture" then
			self.fixtureMode:draw()
		elseif self.state=="body" then
			self.bodyMode:draw()
			self.selector:draw()
		end	
		love.graphics.setColor(255, 0, 0, 255)
		if test1 and #test1>2 then
			love.graphics.polygon("line", test1)
		end

		if test2 then 
			love.graphics.polygon("line", test2)
		end
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
	
	if self.interface:isHover() then
		self.LoveFrames.mousereleased(x, y, button)
	else
		if self.state=="body" or self.state=="test" then
			editor.selector:click(button)
		elseif self.state=="fixture" then
			editor.fixtureMode:click(button)
		elseif self.state=="joint" then
			editor.jointMode:click(button)
		elseif self.state=="shape" then
			editor.shapeMode:click(button)
		end
	end
end

function editor:keypressed(key, isrepeat)
	self.LoveFrames.keypressed(key, isrepeat)
	if isrepeat then return end
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
		elseif string.sub(v.key,1,6)=="shift+" then
			local tkey=string.sub(v.key,7,-1)
			if love.keyboard.isDown("lshift") and key==tkey then
				v.commad()
				break
			end
		else
			local down=love.keyboard.isDown("lctrl") or love.keyboard.isDown("lshift") or love.keyboard.isDown("lalt")
			if not down then
				if  key==v.key then
					if self.state=="test" then
						if key=="q" or key=="w" or key=="e" or key=="a" or key=="s" or key=="d" then
							return
						else
							v.commad()
						end
					else
						v.commad()
						break
					end
				end
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
end

local modeList={"body","fixture","shape","joint"}

function editor:changeMode(which)
	if self.state=="test" and which=="test" then
		self.testMode:togglePause()
		return
	elseif self.state=="test" and which~="test" then
		self.testMode:release()
	end
	if which then 
		self.state=which
	else
		local i=table.getIndex(modeList,self.state)
		self.state=modeList[i+1] and modeList[i+1] or modeList[1]
	end

	self:cancel()
	
	self[self.state.."Mode"]:new()
	
	for k,v in pairs(self.interface.toggleMode) do
		if k==self.state then
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
		

		createSoftRope=function()  self.createMode:new("softrope") end,
		createSoftCircle=function() self.createMode:new("softcircle") end,
		createSoftPolygon=function() self.createMode:new("softpolygon") end,
		createSoftBox=function() self.createMode:new("softbox") end,

		createWater=function() self.createMode:new("water") end,
		createBoom=function() self.createMode:new("explosion") end,

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

		alineHorizontal=function() self.bodyMode:aline(true) end,
		alineVerticle=function() self.bodyMode:aline(false) end,
		
		removeBody=function() self.bodyMode:removeBody() end,
		removeJoint=function() self.bodyMode:removeJoint() end,
		copy=function() self.bodyMode:copy() end,
		paste=function() self.bodyMode:paste() end,
		combine=function() self.bodyMode:combine() end,
		divide=function() self.bodyMode:divide() end,
		toggleBodyType=function() self.bodyMode:toggleBodyType() end,
		undo=function() self.system:undo() end,
		redo=function() self.system:redo() end,
		clear=function() self.system:clear() end,

		toggleMode=function() self:changeMode() end,
		bodyMode=function() self:changeMode("body") end,
		shapeMode=function() self:changeMode("shape") end,
		jointMode=function() self:changeMode("joint") end,
		fixtureMode=function() self:changeMode("fixture") end,
		test=function() self:changeMode("test") end,
		pause=function() self.testMode:togglePause() end,
		toggleMouse=function() self.testMode:toggleMouse() end,
		reset=function() self.testMode:reset() end,


		loadWorld=function() self.system:loadFromFile() end,
		saveWorld=function() self.system:saveToFile() end,

		togglePropFrameStyle=function() self.interface:nextTag() end,
		saveUnit=function() self.units:getSaveName() end,
		quickSave=function() self.units:quickSave() end,

		toggleSystem=function() self.interface.sysList:SetVisible(not self.interface.sysList:GetVisible()) end,
		togglePropFrameStyle=function() self.interface:toggleBodyType() end, 
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


