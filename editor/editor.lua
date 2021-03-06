local editor={}
editor.currentProject="default"
editor.currentScene="default"

editor.world= love.physics.newWorld(0,9.8*64,false)
editor.linearDamping=1
editor.angularDamping=1
editor.meter=64
editor.groupIndex=1
love.physics.setMeter(editor.meter)
------------------------------------------------------
editor.LoveFrames= require "libs.loveframes"
editor.helper = require "editor/box2dhelper"(editor)
editor.Delaunay=require "libs/delaunay"
editor.bloom=require "libs/bloom"(w()/2,h()/2)
editor.trace = require "libs/trace".new(0.005)
editor.meta = require "libs/metaball"
editor.grid = require "libs/grid".new(editor)
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
editor.renderCanvas = love.graphics.newCanvas()



function editor:init()

	self.W = w()
	self.H = h()
	self.interface:init()
	
	editor:beforeStart()
	self.bg:init()
	self.state="body"
	self:keyBound()	
	
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
		--print(self.action)
		editor.log:push(self.action)
		editor.system:pushUndo()
		self.action=nil
	end

	if self.state=="test" and not self.testMode.pause then 
		self.world:update(dt)
		self.helper.update(self.world)
	end
end





function editor:drawKeyBounds()
	love.graphics.setColor(255, 255, 255, 255)
	for i,v in ipairs(self.keys) do
		love.graphics.print(v.key.."------"..v.name, 10,i*20)
	end
end





function editor:draw()
	
    love.graphics.setCanvas(self.renderCanvas)
    love.graphics.clear()
    love.graphics.setColor(255, 255, 255, 255)
	self.cam:draw(function()	
		self.helper.draw(self.world)
		love.graphics.setColor(255, 0, 0, 255)
		if global then
			--print(#global)
			love.graphics.points(global)
		end
	end)
	love.graphics.setCanvas()

	love.graphics.setColor(255, 255, 255, 255)

	if self.helper.visible.trace then
		self.trace:predraw()
		love.graphics.draw(self.renderCanvas)
		self.trace:postdraw()
	end
	
	love.graphics.setColor(255, 255, 255, 255)
	if self.helper.visible.bloom then
		editor.bloom:predraw()
	    editor.bloom:enabledrawtobloom()
	    love.graphics.draw(self.renderCanvas)
		editor.bloom:postdraw()
	end

	
	love.graphics.setColor(255, 255, 255, 255)
	if self.interface.visible.grid then
		editor.grid:predraw()
	    love.graphics.draw(self.renderCanvas)
		editor.grid:postdraw()
	end

	love.graphics.draw(self.renderCanvas)
	
	self.cam:draw(function()
		love.graphics.setLineWidth(1)
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.line(-editor.W/2,0,editor.W/2,0)
		love.graphics.line(0, -editor.H/2, 0,editor.H/2)
		love.graphics.setLineWidth(3)
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

	self.units:draw()
	self.log:draw()
	love.graphics.setColor(155, 155, 155, 255)
	local str = self.state.. " mode"
	if self.testMode.pause then str=str.."\npause" end
	love.graphics.printf(str,0,100,w()/3,"center",0,3,3)

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
		local target 
		if self.selector.rightselection then
			target = self.selector.rightselection
		end
		
		local hover = self.LoveFrames.util.GetHoverObject()

		if button== "r" and  hover and hover:GetType() == "textinput" then
			
			local key = hover.keyObj
			local name = key:GetText()
			local obj= self.interface.property.target
			self.helper.setProperty(obj,name,target)
			self.interface.property:create()
		end

		if self.state=="body" then
			editor.selector:click(button)
		elseif self.state=="test" and 
			(self.testMode.mouseMode=="power" 
				or self.testMode.mouseMode=="key"
				or self.testMode.mouseMode == "grab") then
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
					if self.state=="test" and self.testMode.mouseMode == "key" then
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
		self.testMode.pause = false
	end
	if which then 
		self.state=which
	else
		local i=table.getIndex(modeList,self.state)
		self.state=modeList[i+1] and modeList[i+1] or modeList[1]
	end

	if editor.selector.selection and editor.selector.selection[1]:type()=="Body" then
		editor.cam.target=editor.selector.selection[1]
	end

	self:cancel()
	
	self[self.state.."Mode"]:new()
	
end

function editor:copyTutorial()
	local function recursiveEnumerate(folder,target)
		local lfs = love.filesystem
		local filesTable = lfs.getDirectoryItems(folder)
		for i,v in ipairs(filesTable) do
			local file = folder.."/"..v
			local nextTarget = target .. "/" .. v
			if lfs.isFile(file) then
				lfs.write(nextTarget,lfs.read(file))
			elseif lfs.isDirectory(file) then
				love.filesystem.createDirectory(nextTarget)
				recursiveEnumerate(file,nextTarget)
			end
		end
	end
	recursiveEnumerate("tutorial","")
end


function editor:beforeStart()
	
	local file = love.filesystem.newFile("appData", "r")
	if not file then
		love.window.showMessageBox("firstMet", "This is our firstMet.\nfor more details QQ1643386616", "info")
		editor:copyTutorial()
		editor.system.newProject()
		return 
	end
	local data=loadstring(file:read())()
	editor.loadProject=data.project
	editor.system:loadProject()
	
end

function editor:resize()
	editor.W=w()
	editor.H=h()
	editor.renderCanvas = love.graphics.newCanvas()
	
	editor.interface:resetLayout()
	editor.cam:resize()
	editor.bloom=require "libs/bloom"(w()/2,h()/2)
	editor.trace.new()
	editor.grid.new(editor)
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

end

function editor:openSave()
	local proj = editor.currentProject
	local path = love.filesystem.getAppdataDirectory( )
	local id = love.filesystem.getIdentity()
	love.system.openURL(path.."/"..id)
	love.system.openURL(path.."/LOVE/"..id)
end


function editor:keyBound()
	local bound={
		createCircle=function() self.createMode:new("circle") end,
		createBox=function()  self.createMode:new("box") end,
		createLine=function() self.createMode:new("line") end,
		createEdge=function() self.createMode:new("edge") end,
		createPolygon=function()  self.createMode:new("polygon") end,
		createFreeline=function()  self.createMode:new("freeline") end,
		createText = function() self.createMode:text() end,		

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
		selectAll=function()
			if self.state == "body" then
				self.selector:selectAll()
			elseif self.state == "fixture" then
				--self.jointMode:comboFind()
			elseif self.state == "joint" then
				self.jointMode:comboFind()
			end
		end,
		comboSet=function()
			if self.state == "body" then

			elseif self.state == "fixture" then
				self.fixtureMode:comboSet()
			elseif self.state == "joint" then
				self.jointMode:comboSet()
			end
		end,
		selectNone=function() self.selector:clearSelection() end,

		alineHorizontal=function() self.bodyMode:aline(true) end,
		alineVerticle=function() self.bodyMode:aline(false) end,
		
		removeBody=function()
			if self.state == "body" then
				self.bodyMode:removeBody()
			elseif self.state == "fixture" then
				self.fixtureMode:removeFixture()
			elseif self.state == "joint" then
				self.jointMode:removeJoint()
			end 
		end,
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
		saveUnit=function() self.units:save() end,
		quickSave=function() self.units:quickSave() end,



		toggleSystem=function() 
			editor.interface:setVisible("system", not editor.interface.visible.system) 
		end,
		nextPropTab=function() 
			editor.interface.property:nextTab() 
		end, 
		toggleGrid=function() 
			editor.interface:setVisible("grid", not editor.interface.visible.grid) 
		end,
		toggleLog=function() 
			editor.interface:setVisible("log", not editor.interface.visible.log) 
		end,
		toggleBuild=function()
			editor.interface:setVisible("build", not editor.interface.visible.build) 
		end,
		toggleProperty=function()
			editor.interface:setVisible("property", not editor.interface.visible.property)
		end,
		toggleUnit=function()
			editor.interface:setVisible("unit", not editor.interface.visible.unit)						
		end,
		toggleHistroy=function()
			editor.interface:setVisible("history", not editor.interface.visible.history)		
		end,
		openSaveFolder=function()
			self:openSave()
		end,
		teststd = function()
			self.testMode:toggleMouse(1)
		end,
		testpower = function()
			self.testMode:toggleMouse(2)
		end,
		testball = function()
			self.testMode:toggleMouse(3)
		end,
		testkey = function()
			self.testMode:toggleMouse(4)
		end,
		testscissor = function()
			self.testMode:toggleMouse(5)
		end,
		testgrab = function()
			self.testMode:toggleMouse(6)
		end,
		getConvex =  function()
			self.createMode:getImageBoundingBox(true)
		end,
		getConcave =  function()
			self.createMode:getImageBoundingBox()
		end,
		exportJson = function()
			self.system:exportAsJson()
		end
	}

	local keys ={}
	self.keyconf=self.keyconf or require "editor/keyconf"
	for commadName,key in pairs(self.keyconf) do
		table.insert(keys, {key=key,commad=bound[commadName],name=commadName})
	end
	self.commmadBounds=bound
	
	self.keys= keys
end


return editor


