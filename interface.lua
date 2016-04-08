local interface={}
local editor
local ui

interface.propTagIndex=1
interface.propItemIndex=1


function interface:init()
	ui=editor.LoveFrames
	--self.preview=require "preview"(editor)
	self:createBuildFrame()
	self:createJointFrame()
	self:createSystemFrame()
end

function interface:update(dt)
	ui.update(dt)
	self:updatePropFrame()
end

function interface:draw()


end

function interface:isHover()
	if ui.util.GetHover() and love.mouse.isDown(1) then
		self.hover=true
	elseif not ui.util.GetHover() and not love.mouse.isDown(1) then
		self.hover=false
	end
    local hoverobject = ui.util.GetHoverObject()
    if hoverobject and hoverobject.type=="textinput" then
    	if hoverobject.focus then
    		self.hover=true
    	end
    end
	return self.hover
end

------------------prop------------------



----------------build-------------------

local createShape={"circle","box","polygon","line","edge","freeline"}
function interface:createBuildFrame()
	self.createFrame= ui.Create("frame")
	local frame = self.createFrame
	frame:SetName("Shape")
	frame:SetSize(50, 250)
	frame:SetPos(10, 100)
	frame:ShowCloseButton(false)
	self.createList=ui.Create("list", frame)
	local list = self.createList
	list:SetPos(5, 30)
	list:SetSize(39, 215)
	list:SetSpacing(3)
	list:SetPadding(3)
	self.createButtons={}
	local createButtons=self.createButtons
	for i,v in ipairs(createShape) do
		local b= ui.Create("imagebutton")
		b:SetImage("icons/".. v ..".png")
		b:SetText("")
		b:SizeToImage()
		table.insert(self.createButtons, b)
		list:AddItem(b)
		b.OnClick=function(obj)
			editor.createMode:new(v)
		end
	end
end

local createJoint={"distance","rope","revolute","prismatic","weld","wheel","pully"}
function interface:createJointFrame()
	self.jointFrame= ui.Create("frame")
	local frame = self.jointFrame
	frame:SetName("Joint")
	frame:SetSize(50, 290)
	frame:SetPos(10, 380)
	frame:ShowCloseButton(false)
	self.jointList=ui.Create("list", frame)
	local list = self.jointList
	list:SetPos(5, 30)
	list:SetSize(39, 250)
	list:SetSpacing(3)
	list:SetPadding(3)
	self.jointButtons={}
	local jointButtons=self.jointButtons
	for i,v in ipairs(createJoint) do
		local b= ui.Create("imagebutton")
		b:SetImage("icons/".. v ..".png")
		b:SetText("")
		b:SizeToImage()
		table.insert(self.jointButtons, b)
		list:AddItem(b)
		b.OnClick=function()
			editor.createMode[v](editor.createMode)
		end
	end

end

--save,load, undo, redo,
--mode toggle edit/test/vert
--show/hide shape/joint/prop/unit/history/miniMap/world/grid

function interface:createSystemFrame()
	self.sysList=ui.Create("list")
	local list = self.sysList
	list:SetPos(0, 0)
	list:SetSize(300, 30)
	list:SetSpacing(0)
	list:SetPadding(3)
	list:SetDisplayType("horizontal")

	self.sysButtons={}
	local sysButtons=self.sysButtons
	
	local b= ui.Create("button")
	b:SetText("save")
	list:AddItem(b)
	b.OnClick=function()
		editor.system:saveToFile()
	end
	sysButtons.save=b

	local b= ui.Create("button")
	b:SetText("load")
	list:AddItem(b)
	b.OnClick=function()
		print("save")
	end
	sysButtons.save=b
end

function interface:createUnitFrame(files)


end

function interface:createLoadWorldFrame()
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

function interface:createSaveWorldFrame()
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
			if love.keyboard.isDown("lctrl") and love.keyboard.isDown("lalt") then
				love.filesystem.remove( "save/"..b:GetText() )
				frame:Remove()
				system:loadFromFile()
			else
				local file = love.filesystem.newFile("save/"..b:GetText())
				file:open("r")
				local str=file:read()
				editor.world = love.physics.newWorld(0, 9.8*64, false)
				editor.helper.createWorld(editor.world,loadstring(str)())
				editor.selector.selction=nil
				frame:Remove()
			end
		end
	end

end


local propTagList={"body","shape","fixture","joint","userdata"}

local function setProp(target,prop,...)
	local tag=interface.propTag
	if tag=="userdata" then
		for i,v in ipairs(target) do
			if v.prop==prop then
				v.value=...
				break
			end
		end
		--interface.targetFixture:setUserData(target)
	else
		target["set"..prop](target,...)
	end
	
	editor.action="change property"

end

function interface:nextTag()
	self.propTagIndex=self.propTagIndex+1
	if not propTagList[self.propTagIndex] then self.propTagIndex=1 end
end

function interface:updatePropFrame()
	local selection=editor.selector.selection
	
	if not selection then 
		self:removePropFrame()
		return 
	end

	local tag=propTagList[self.propTagIndex]
	local index=self.propItemIndex
	local selectedBody=selection[1]
	
	if self.obody==selectedBody and self.oindex==index and self.otag==tag and self.propFrame then 
		if not self:isHover() then 
			self:resetPropFrame()
		end
	else
		self:removePropFrame()
		self.obody=selectedBody
		self.oindex=index
		self.otag=tag
		self:createPropFrame(selectedBody,index,tag)
	end

end

function interface:resetPropFrame()
	if self.propTag=="userdata" then
		self.propData=self.targetFixture:getUserData()
	else
		self.propData={}
		local tmp=editor.helper.getStatus(self.propTarget,self.propTag)
		for i,v in ipairs(editor.helper.properties[self.propTag]) do
			if tmp[v]~=nil then table.insert(self.propData,{prop=v,value=tmp[v]}) end
		end
	end

	for i,v in ipairs(self.propData) do

		local value=self.propGrid[i][2]
		if type(v.value)=="number" then
			value:SetText(tostring(v.value))
		elseif type(v.value)=="table" then
			local str=""
			for i,v in ipairs(v.value) do
				str=str..tostring(v)..","
			end
			value:SetText(str)
		elseif type(v.value)=="boolean" then
			value:SetChecked(v.value)
		elseif type(v.value)=="string" then
			value:SetText(tostring(v.value))
		end
		
	end

end

function interface:removePropFrame()
	if self.propFrame then
		self.propList:Remove()
		self.propFrame:Remove() 
	end
end

function interface:createPropFrame(selectedBody,index,tag)

	local target
	if tag=="body" then
		self.popItem=nil
		target=selectedBody
	elseif tag=="shape" then
		self.propItems=selectedBody:getFixtureList()
		target=self.propItems[index] and self.propItems[index]:getShape() or self.propItems[1]:getShape()
	elseif tag=="fixture" then
		self.propItems=selectedBody:getFixtureList()
		target=self.propItems[index] or self.propItems[1]
	elseif tag=="joint" then
		self.propItems=selectedBody:getJointList()
		target=self.propItems[index] or self.propItems[1]
	elseif tag=="userdata" then
		self.propItems=selectedBody:getFixtureList()
		local fixture=self.propItems[index] or self.propItems[1]
		target=fixture:getUserData()
		if not target then
			target={
			{prop="name",value="default"},
			{prop="name",value="default"},
			{prop="name",value="default"},
			{prop="name",value="default"},
		}
		self.targetFixture=fixture
		fixture:setUserData(target)
		end
	end	

	if not target then
		self:nextTag()
		return
	end
	self.propTarget=target


	------------------------------------------------
	if tag=="userdata" then
		self.propData=target
	else
		self.propData={}
		local tmp=editor.helper.getStatus(target,tag)
		for i,v in ipairs(editor.helper.properties[tag]) do
			if tmp[v]~=nil then table.insert(self.propData,{prop=v,value=tmp[v]}) end
		end
	end



	self.propTag=tag
	self.propFrame= ui.Create("frame")
	local frame = self.propFrame
	frame:SetName(tag)
	frame:SetSize(250, 35+#self.propData*30)
	frame:SetPos(w()*0.8, 300)
	frame:ShowCloseButton(false)
	self.propList=ui.Create("grid", frame)
	local list = self.propList
	list:SetPos(5, 30)
	list:SetSize(240, #self.propData*20)
	list:SetCellWidth(110)
	list:SetCellHeight(20)
	list:SetRows(#self.propData)
	list:SetColumns(2)
	list:SetItemAutoSize(true)


	self.propGrid={}
	for i,v in ipairs(self.propData) do
		local key = ui.Create("button")
		key:SetText(v.prop)
		local value
		if type(v.value)=="number" then
			value = ui.Create("textinput")
			value:SetText(tostring(v.value))
			value.OnEnter=function(obj)
				local text=value:GetText()
				local num=tonumber(text)
				if num then
					setProp(target,v.prop,num)
				end
				obj.focus=false
			end
			
		elseif type(v.value)=="table" then
			value = ui.Create("textinput")
			local str=""
			for i,v in ipairs(v.value) do
				str=str..tostring(v)..","
			end
			value:SetText(str)
			value.OnEnter=function(obj)
				local text=value:GetText()
				local tab= string.split(text,",")
				setProp(target,v.prop,unpack(tab))
				obj.focus=false
			end
			
		elseif type(v.value)=="boolean" then
			value = ui.Create("checkbox")
			value:SetChecked(v.value)
			value.OnChanged=function()
				setProp(target,v.prop,value:GetChecked())
			end
			
		elseif type(v.value)=="string" then
			value = ui.Create("textinput")
			value:SetText(tostring(v.value))
			value.OnEnter=function(obj)
				local text=value:GetText()
				setProp(target,v.prop,text)
				obj.focus=false
			end
			
		end
		if tag~="userdata" and not target["set"..v.prop] then 
			if value.SetEditable then
				value:SetEditable(false)
			else
				value:SetEnabled(false)
			end
		end
		list:AddItem(key,i,1)
		list:AddItem(value,i,2)
		table.insert(self.propGrid, {key,value})
	end
	list:update()
end




return function(parent) 
	editor=parent
	return interface
end