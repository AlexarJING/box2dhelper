local editor={}
local getDist = function(x1,y1,x2,y2) return math.sqrt((x1-x2)^2+(y1-y2)^2) end
local getRot  = function (x1,y1,x2,y2) 
	if x1==x2 and y1==y2 then return 0 end 
	local angle=math.atan((x1-x2)/(y1-y2))
	if y1-y2<0 then angle=angle-math.pi end
	if angle>0 then angle=angle-2*math.pi end
	if angle==0 then return 0 end
	return -angle
end
local axisRot = function(x,y,rot) return math.cos(rot)*x-math.sin(rot)*y,math.cos(rot)*y+math.sin(rot)*x  end
local polygonTrans= function(x,y,rot,size,v)
	local tab={}
	for i=1,#v/2 do
		tab[2*i-1],tab[2*i]=axisRot(v[2*i-1],v[2*i],rot)
		tab[2*i-1]=tab[2*i-1]*size+x
		tab[2*i]=tab[2*i]*size+y
	end
	return tab
end
local function clamp(a,low,high)
	if low>high then 
		return math.max(high,math.min(a,low))
	else
		return math.max(low,math.min(a,high))
	end
end

editor.createMode=require "createMode"
editor.editMode= require "editMode"
editor.vertMode= require "vertMode"
editor.testMode= require "testMode"
editor.selector= require "selector"
editor.preview = require "preview"
editor.bg = require "bg"
editor.cam = require "camera"

function editor:init()
	world = love.physics.newWorld(0, 9.8*64, false)
	love.physics.setMeter(64)
	self.creator:init(self)
	self.world = world
	self.objects={}
	self.selection=nil
	self.inEditMode=true
	self.undoStack={}
	self.undoIndex=0
	self.action="initialize"
	self.units={}
	self.preview={}
	

	self.popTags={"body","shape","fixture","joint"}
	self.popTagIndex=1
	self.popItemIndex=1

	self.mouseBall={enable=false}

	self.showHelp=false
	self.shouUI=true

	self:popCreateFrame()

end


function editor:update(dt)
	self.bg:update()
	self:pushUndo()
	if self.inEditMode then
		if self:vertMode() then return end
		if self.createTag then 
			self:getPoints()
			self:getVerts()
			self:freeDraw()
			return 
		end
		if not self.dragSelecting and self:dragMove() then 
			--return 
		else
			self:dragSelect()
		end
		
		self:updateRelativeFrame()
		self:unpdatePopValue()
	else
		if self.mouseBall.enable then
			self.mouseBall.joint:setTarget(mouseX,mouseY)
		else
			
			if not self.dragSelecting then
				if not self:dragForce() then
					self:dragSelect()
				end
			else
				self:dragSelect()
			end
		end
		self:downForce()
		self.world:update(dt)
	end
	self:unpdatePopValue()
end





function editor:saveToFile()
	if self.popFrame then
		self.popList:Remove()
		self.popFrame:Remove() 
	end
	 
	local frame =ui.Create("frame")
	frame:SetName("save to file...")
	frame:SetSize(300,80)
	frame:CenterWithinArea(0,0,w(),h())
	local input = ui.Create("textinput",frame)
	input:SetSize(280,30)
	input:SetPos(10,40)
	input.OnEnter=function()
		love.filesystem.createDirectory("save")
		local file = love.filesystem.newFile("save/"..input:GetText()..".lua")
		file:open("w")
		file:write(table.save(self.undoStack[self.undoIndex].world))
		file:close()
		frame:Remove()
	end
end


function editor:loadFromFile()

	local files = love.filesystem.getDirectoryItems("save")
	local frame =ui.Create("frame")
	local count=#files
	frame:SetName("select a file to load...")
	frame:SetSize(300,30*count+30)
	frame:CenterWithinArea(0,0,w(),h())
	local list = ui.Create("list",frame)
	list:SetDisplayType("vertical")
	list:SetPos(5, 30)
	list:SetSize(280, 28*count)
	for i,v in ipairs(files) do
		local b= ui.Create("button")
		b:SetText(v)
		list:AddItem(b)
		b.OnClick=function()
			local file = love.filesystem.newFile("save/"..b:GetText())
			file:open("r")
			local str=file:read()
			world = love.physics.newWorld(0, 9.8*64, false)
			love.physics.setMeter(64)
			self.world = world
			self.objects=helper.createWorld(self.world,loadstring(str)())
			self:clearSelection()
			frame:Remove()
		end
	end
end



function editor:toggleUI()
	self.showUI=not self.showUI
	self.createFrame:SetVisible(self.showUI)
	if self.popFrame then
		self.popFrame:SetVisible(self.showUI)
	end
end



function editor:pushUndo()
	if self.action then
		self.undoIndex=self.undoIndex+1
		self.undoStack[self.undoIndex]={event=self.action,world=helper.getWorldData(self.world)}
		if #self.undoStack>10 then
			table.remove(self.undoStack, 1)
			self.undoIndex=10
		end
		for i=self.undoIndex+1,10 do
			self.undoStack[i]=nil
		end
		self.action=nil
	end
end

function editor:undo()
	--print("undo")
	self.undoIndex=self.undoIndex-1
	if self.undoIndex<1 then self.undoIndex=1 end
	world = love.physics.newWorld(0, 9.8*64, false)
	love.physics.setMeter(64)
	self.world = world
	self.objects=helper.createWorld(self.world,self.undoStack[self.undoIndex].world)
	self:clearSelection()
end

function editor:redo()
	--print("redo")
	self.undoIndex=self.undoIndex+1
	if self.undoIndex>#self.undoStack then self.undoIndex=#self.undoStack end
	world = love.physics.newWorld(0, 9.8*64, false)
	love.physics.setMeter(64)
	self.world = world
	self.objects=helper.createWorld(self.world,self.undoStack[self.undoIndex].world)
	self:clearSelection()
end

function editor:test()
	self.inEditMode = not self.inEditMode
	if self.inEditMode then
		self:redo()
	else
		self.action="test"
	end
end


function editor:keypress(key)
	
	if self.inEditMode then
		if key=="f1" then
			self:test()
		elseif key=="escape" then
			self:clearSelection()
		elseif key=="r" then
			self:rope()
		elseif key=="d" then
			self:distance()
		elseif key=="w" then
			self:weld()
		elseif key=="q" then
			self:prismatic()
		elseif key=="i" then
			self:wheel()
		elseif key=="u" then
			self:pully()
		elseif key=="o" then
			self:revolute()
		elseif key=="delete" then
			self:delete()
		elseif key=="v" then
			if love.keyboard.isDown("lctrl") then 
				self:duplicate() 
			else
				self:toggleUI()
			end
		elseif key=="f" then
			if love.keyboard.isDown("lctrl") then self:fix() end
		elseif key=="a" then
			if love.keyboard.isDown("lctrl") then 
				self:selectAll() 
			else
				self:aline(true)
			end
		elseif key=="s" then
			if love.keyboard.isDown("lctrl") then
				self:saveToFile()
			else
				self:aline(false)
			end
			
		elseif key=="end" then
			self:removeJoint()
		elseif key=="m" then
			if love.keyboard.isDown("lctrl") then self:combine() end
		elseif key=="b" then
			if love.keyboard.isDown("lctrl") then self:divide() end
		elseif key=="z" then
			if love.keyboard.isDown("lctrl") then self:undo() end
		elseif key=="y" then
			if love.keyboard.isDown("lctrl") then self:redo() end
		elseif tonumber(key) then
			if love.keyboard.isDown("lctrl") then self:saveUnit(key) end
			if love.keyboard.isDown("lalt") then self:loadUnit(key) end
			self:switchPreview(key)
		elseif key=="tab" then
			self:switchPopTag()
		elseif key=="`" then
			self:switchPopItemIndex()
		elseif key=="h" then
			self.showHelp=not self.showHelp
		elseif key=="l" then
			if love.keyboard.isDown("lctrl") then self:loadFromFile() end
		end

	else
		if key=="f1" then
			self:test()
		elseif key=="a" then
			if love.keyboard.isDown("lctrl") then 
				self:selectAll() 
			end
		elseif key=="escape" then
			self:clearSelection()
		elseif key=="m" then
			self:toggleMouse()
		end
	end

end




function editor:downCreate()
	if love.keyboard.isDown("c") then
		self.createTag="circle"
		self.needPoints=true
	elseif love.keyboard.isDown("b") then
		self.createTag="box"
		self.needPoints=true		
	elseif love.keyboard.isDown("l") then
		self.createTag="line"
		self.needPoints=true
	elseif love.keyboard.isDown("e") then
		self.createTag="edge"
		self.needVerts=true
	elseif love.keyboard.isDown("p") then
		self.createTag="polygon"
		self.needVerts=true
	elseif love.keyboard.isDown("f") then
		self.createTag="freeLine"
		self.needLines=true
	elseif love.keyboard.isDown("t") then
		self:rotate()
	elseif not self.uiCreate then
		self.createOX=nil
		self.createTag=nil
		return false
	end
	return true
end

function editor:saveUnit(slot)
	if not self.selection then return end
	self.action="save unit in slot "..slot
	local bodyList={}

	for i,v in ipairs(self:getSelected()) do

		bodyList[i]=v[1].body
	end
	
	self.units[slot]=helper.getWorldData(bodyList)
end

function editor:loadUnit(slot)
	if not self.units[slot] then return end
	self.action="load unit from slot"..slot
	local add=helper.createWorld(self.world,self.units[slot],mouseX,mouseY)
	local selection = {}
	for i,v in ipairs(add) do
		table.insert(self.objects, v)
		selection[i]={v}
	end
	self:clearSelection()
	self.selection=selection
	for i=1,#selection do
		self.selection[i][1].body:setUserData(true)
	end
	self.selectIndex=1
end



function editor:draw()
	self.bg:draw()

	cam:draw(function()
		self:drawEditor()
		helper.draw(self.world)	
	end)
	
	

	local text=[[
	select relative
	*****click to select, drag to multi-select,hold ctrl to addtive select, press esc to clear selection
	*****for selected objects, drag to move, holding t and left/right drag to rotate at center body/axis.
	---------------------------------------------------------------------------------------
	*****hold space button and drag to scoll the screen
	*****use mouse scroll to change the scale of the screen
	----------------------------------------------------------------------------------
	create relative
	*****hold button and drag/right click to create shapes
	c=circle b=box l=line p=polygon e=edge  f=freeline
	*****select 2 objects and press button to create joints
	r=rope, d=distance, w=weld, q= prismatic, i=wheel, u=pully, o=revolute
	-------------------------------------------------------------------------------------
	edit relative
	F1 	--- toggle test mode or edit mode
	f 	--- toggle static/dynamic
	del ---	delete selected bodies
	v 	--- copy selected bodies
	a 	--- aline horizontally
	s 	--- aline vertically
	end --- remove joint
	m 	--- combine fixtures to a body
	b 	--- divide fixtures into bodies
	ctrl+z 	undo
	ctrl+y 	redo
	----------------------------------------------------------------------------------------
	verticle relative
	********hold alt to edit verticle, drag to change the shape or radius
	-------------------------------------------------------------------------------------
	ctrl + number ----- save selected units
	number  ---- preview saved units
	alt + number ---- place unit to the position of mouse
	---------------------------------------------------------------------------------------
	tab --- switch "body" "shape" "fixture" "joint" info
	~ 	--- switch different "shape" "fixture" "joint" to the body
	]]

	love.graphics.setColor(255, 255, 255, 200)
	if self.showHelp then
		love.graphics.print(text, 10, 10, 0, 1,1)
	else
		love.graphics.print("press h to toggle help info", 10, 10, 0, 1.5,1.5)
	end
	love.graphics.setColor(255, 255, 255, 255)
	if self.inEditMode then
		love.graphics.printf("Edit Mode", 0, 20, w()/2, "center", 0, 2, 2)
	else
		love.graphics.printf("Test Mode", 0, 20, w()/2, "center", 0, 2, 2)
	end

end

return editor