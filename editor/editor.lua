local editor={}
editor.currentProject="default"
editor.currentScene="default"

editor.world= love.physics.newWorld(0,9.8*64,false)
editor.linearDamping=1
editor.angularDamping=1
editor.meter=64
love.physics.setMeter(editor.meter)
------------------------------------------------------
editor.LoveFrames= require "libs.loveframes"
editor.helper = require "editor/box2dhelper"
editor.Delaunay=require "libs/delaunay"
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
--------------------------------------------------------



function editor:init()
--[[
	local body  = love.physics.newBody(self.world, 300, 0, "dynamic")
	body:setUserData({})
	local shape = love.physics.newRectangleShape(50,100)
	local fixture = love.physics.newFixture(body, shape)
	fixture:setUserData({{prop="crashable",value=true}})

	local body3  = love.physics.newBody(self.world, -30, 0, "dynamic")
	local shape = love.physics.newRectangleShape(30,30)
	local fixture = love.physics.newFixture(body3, shape)
	self.createMode:setMaterial(fixture,"wood")
	body3:setUserData({
		{prop="jet",value="w"},
		{prop="power",value=-5000}
		})

	local body  = love.physics.newBody(self.world, 0, 0, "dynamic")
	local shape  = love.physics.newCircleShape(0,0,30)
	local fixture = love.physics.newFixture(body, shape)
	self.createMode:setMaterial(fixture,"wood")
	body:setUserData({
		{prop="roll",value="e"},
		{prop="rollback",value="q"}
		})

	local body2  = love.physics.newBody(self.world, 100, 0, "dynamic")
	local shape = love.physics.newRectangleShape(30,30)
	local fixture = love.physics.newFixture(body2, shape)
	self.createMode:setMaterial(fixture,"wood")
	body2:setUserData({
		{prop="fire",value="l"},
		{prop="bullet",value=self.createMode:defaultBoom()}
	})
	local joint = love.physics.newWeldJoint(body, body2, body2:getX(), body2:getY(), false)
	local joint = love.physics.newWeldJoint(body, body3, body3:getX(), body3:getY(), false)


	local body  = love.physics.newBody(self.world, 300, -100, "dynamic")
	local shape = love.physics.newRectangleShape(50,50)
	local fixture = love.physics.newFixture(body, shape)
	self.createMode:setMaterial(fixture,"wood")
	editor.helper.setProperty(fixture,"crashable",100)
	editor.helper.setProperty(fixture,"crashcombo",false)
	body:setType("static")

	local body  = love.physics.newBody(self.world, 0, 60, "dynamic")
	local shape = love.physics.newRectangleShape(30,30)
	local fixture = love.physics.newFixture(body, shape)
	fixture:setGroupIndex(-1)
	self.createMode:setMaterial(fixture,"wood")
	editor.helper.setProperty(body,"jump","w")
	editor.helper.setProperty(body,"jumpPower",3000)	
	editor.helper.setProperty(body,"jumpLeftKey","a")
	editor.helper.setProperty(body,"jumpRightKey","d")

	local body2  = love.physics.newBody(self.world, 0, 0, "dynamic")
	local shape = love.physics.newRectangleShape(30,70)
	local fixture = love.physics.newFixture(body2, shape)
	fixture:setGroupIndex(-1)
	self.createMode:setMaterial(fixture,"wood")


	local body3  = love.physics.newBody(self.world, 0, 40, "dynamic")
	local shape = love.physics.newRectangleShape(30,30)
	local fixture = love.physics.newFixture(body3, shape)
	fixture:setGroupIndex(-1)
	self.createMode:setMaterial(fixture,"wood")
	editor.helper.setProperty(body3,"balancer",true)

	local joint = love.physics.newWeldJoint(body, body2, body2:getX(), body2:getY(), false)
	local joint = love.physics.newWeldJoint(body2, body3, body3:getX(), body3:getY(), false)
]]
	

	--editor.helper.setProperty(body,"turnToMouse",5000)


	self.W = w()
	self.H = h()
	self.interface:init()
	
	editor:beforeStart()
	self.bg:init()
	self.state="body"
	self.keys= self:keyBound()	
	
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


local bloom=require "libs/bloom"(w()/1.5,h()/1.5)
local canvas = love.graphics.newCanvas()
local accum = love.graphics.newCanvas()

function editor:draw()
	
	self.bg:draw()
	self.log:draw()
	self.units:draw()

    love.graphics.setCanvas(canvas)
    love.graphics.clear()
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

	end)
	love.graphics.setCanvas()
	love.graphics.setColor(255, 255, 255, 255)
	
	if editor.enableBloom then
		bloom:predraw()
	    bloom:enabledrawtobloom()
	    love.graphics.draw(canvas)
		bloom:postdraw()
	end
	
	love.graphics.draw(canvas)
	self.LoveFrames.draw()

end


-------------------------------------------------------------

function editor:mousepressed(x, y, button)
	if self.state=="test" then self.helper.click(button) end
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
		if self.state=="body" then
			editor.selector:click(button)
		elseif self.state=="test" and self.testMode.mouseMode=="power" then
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
	if self.state=="test" then self.helper.press(key) end
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
	
end

function editor:beforeStart()
	local file = love.filesystem.newFile("appData", "r")
	if not file then
		love.window.showMessageBox("firstMet", "This is our firstMet.\nfor more details QQ1643386616", "info")
		editor.system.newProject()
		return 
	end
	local data=loadstring(file:read())()
	editor.loadProject=data.project
	editor.system:loadProject()
end



function editor:beforeQuit()
	local file = love.filesystem.newFile("appData", "w")
	local data={project=editor.currentProject,scene=currentScene}
	file:write(table.save(data))
	file:close()
end

function editor:quit()
	local title = "about to quit..."
	local message = "Are you sure to quit?"
	local buttons = {"Save and Quit", "Quit","Cancel", enterbutton=1,escapebutton = 3}
	 
	local b = love.window.showMessageBox(title, message, buttons,"warning",true)

	if b==1 then
		editor.system:saveScene()
		editor.system:saveProject()
		editor:beforeQuit()
		return 
	elseif b==2 then
		editor:beforeQuit()
		return
	end
	return true
--[[
	local file = love.filesystem.newFile("appData", "w")
	local data={project=editor.currentProject,scene=currentScene}
	file:write(table.save(data))
	file:close()]]
end

function editor:resize()


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
		saveScene=function() self.system:saveScene() end,
		saveProject=function() self.system:saveProject() end,
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
	self.keyconf=require "editor/keyconf"
	for commadName,key in pairs(self.keyconf) do
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


