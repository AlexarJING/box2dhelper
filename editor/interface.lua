local interface={}
local editor
local ui

interface.propTagIndex=1
interface.propItemIndex=1


function interface:init()
	ui=editor.LoveFrames
	self:createBuildFrame()
	self:createJointFrame()
	self:createSystemFrame()
	self:createUnitFrame()
	self:createHistroyFrame()
end

function interface:update(dt)
	ui.update(dt)
	self:updatePropFrame()
	self:updateUnitFrame()
end

function interface:draw()


end

function interface:isHover()
	if ui.util.GetHover() and love.mouse.isDown(1) then
		self.hover=true
	elseif not ui.util.GetHover() and not love.mouse.isDown(1) then
		self.hover=false
	end
	if ui.inputobject then self.hover=true end
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
	frame:SetPos(10, 40)
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
	frame:SetPos(10, 315)
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
	list:SetSize(editor.W, 30)
	list:SetSpacing(0)
	list:SetPadding(0)
	list:SetDisplayType("horizontal")

	self.sysButtons={}
	local sysButtons=self.sysButtons
	
	local b= ui.Create("button")
	b:SetText("save")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.system:saveToFile()
	end


	local b= ui.Create("button")
	b:SetText("load")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.system:loadFromFile()
	end

	local b= ui.Create("button")
	b:SetText("undo")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.system:undo()
	end

	local b= ui.Create("button")
	b:SetText("redo")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.system:redo()
	end

	local b= ui.Create("button")
	b:SetText("save unit")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.units:getSaveName()
	end

	local b= ui.Create("button")
	b:SetText("copy")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.bodyMode:copy()
	end

	local b= ui.Create("button")
	b:SetText("paste")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.bodyMode:paste(0,0)
	end	
----------------------------------------------------
	self.toggleMode={}
	

	local modes=self.toggleMode
	
	local b= ui.Create("button")
	b:SetText("body")
	b:SetSize(70,10)
	b:SetToggleable(true)
	b.toggle=true

	list:AddItem(b)
	b.OnToggle=function(obj)
		editor:changeMode("body")
	end
	self.toggleMode.body=b

	local b= ui.Create("button")
	b:SetText("fixture")
	b:SetSize(70,10)
	b:SetToggleable(true)
	b.toggle=false

	list:AddItem(b)
	b.OnToggle=function(obj)
		editor:changeMode("fixture")
	end
	self.toggleMode.fixture=b

	local b= ui.Create("button")
	b:SetText("shape")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.OnToggle=function(obj)
		editor:changeMode("shape")
	end
	self.toggleMode.shape=b

	local b= ui.Create("button")
	b:SetText("joint")
	b:SetToggleable(true)
	b:SetSize(70,10)
	b.toggle=false
	list:AddItem(b)
	b.OnToggle=function(obj)
		editor:changeMode("joint")
	end
	self.toggleMode.joint=b

	local b= ui.Create("button")
	b:SetText("test")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.OnToggle=function(obj)
		editor:changeMode("test")
	end
	self.toggleMode.test=b


-----------------------------------------------
	local b= ui.Create("button")
	b:SetText("Hide All")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		self.createFrame:SetVisible(false)
		self.jointFrame:SetVisible(false)
		if self.propFrame then self.propFrame:SetVisible(false) end 
		self.unitFrame:SetVisible(false)
		self.historyFrame:SetVisible(false)
		editor.bg.visible=false
		editor.bg.visible=false
		for i,v in ipairs(self.uiVisible) do
			v.toggle=false
		end
	end


	self.uiVisible={}


	local b= ui.Create("button")
	b:SetText("Grid")
	b:SetSize(70,10)
	b:SetToggleable(true)
	b.toggle=true
	list:AddItem(b)
	b.OnClick=function()
		editor.bg.visible=not editor.bg.visible
		editor.log.visible= not editor.log.visible
	end
	table.insert(self.uiVisible,b)

	local b= ui.Create("button")
	b:SetText("create UI")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.toggle=true
	b.OnClick=function()
		self.createFrame:SetVisible(not self.createFrame:GetVisible())
		self.jointFrame:SetVisible(self.createFrame:GetVisible())
	end
	table.insert(self.uiVisible,b)

	local b= ui.Create("button")
	b:SetText("property UI")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.toggle=true
	b.OnClick=function()
		if self.propFrame then
			self.propFrame:SetVisible(not self.propFrame:GetVisible())
		else
			b.toggle=false
		end
	end
	table.insert(self.uiVisible,b)

	local b= ui.Create("button")
	b:SetText("unit UI")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.toggle=true
	b.OnClick=function()
		self.unitFrame:SetVisible(not self.unitFrame:GetVisible())
	end
	table.insert(self.uiVisible,b)

	

	local b= ui.Create("button")
	b:SetText("history")
	b:SetSize(70,10)
	b:SetToggleable(true)
	b.toggle=true
	list:AddItem(b)
	b.OnClick=function()
		self.historyFrame:SetVisible(not self.historyFrame:GetVisible())
	end
	table.insert(self.uiVisible,b)

	------------------------------
	local b= ui.Create("button")
	b:SetText("help")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		self:createHelpFrame()
	end

	local b= ui.Create("button")
	b:SetText("about")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		self:createAboutFrame()
	end
end

function interface:updateUnitFrame()
	if #love.filesystem.getDirectoryItems("units")~=self.unitCount then
		if self.unitFrame then self.unitFrame:Remove() end
		self:createUnitFrame()
	end
end


function interface:createUnitFrame()
	local files = love.filesystem.getDirectoryItems("units")
	local frame =ui.Create("frame")
	self.unitFrame=frame
	local count=#files
	self.unitCount=count
	local max=9
	frame:SetName("units")
	frame:SetSize(100,30*max+28)
	frame:SetPos(70,40)
	local list = ui.Create("list",frame)
	list:SetDisplayType("vertical")
	list:SetPos(5, 30)
	list:SetSize(90, 29.5*max)
	list:SetSpacing(3)
	list:SetPadding(3)
	for i,v in ipairs(files) do
		local b= ui.Create("button")
		b:SetText(v)
		list:AddItem(b)
		b.OnClick=function() --copy to editor.selector.copied
			if love.keyboard.isDown("lctrl") and love.keyboard.isDown("lalt") then
				love.filesystem.remove( "units/"..b:GetText() )
				frame:Remove()
				self:createUnitFrame()
			else
				editor.units:load(b:GetText())
			end
		end
		b.OnMouseEnter=function()
			editor.units:showPreview(b:GetText())
		end

		b.OnMouseExit=function()
			editor.units:showPreview(false)
		end
	end

end


function interface:createSaveUnitFrame()
	local frame =ui.Create("frame")
	frame:SetName("save to file...")
	frame:SetSize(300,80)
	frame:CenterWithinArea(0,0,w(),h())
	local input = ui.Create("textinput",frame)
	input:SetSize(280,30)
	input:SetPos(10,40)
	input:SetFocus(true)
	input.OnEnter=function()
		editor.units:save(input:GetText())
		input:Remove()
		frame:Remove()
	end
end


function interface:createSaveWorldFrame()
	local frame =ui.Create("frame")
	frame:SetName("save to file...")
	frame:SetSize(300,80)
	frame:CenterWithinArea(0,0,w(),h())
	local input = ui.Create("textinput",frame)
	input:SetSize(280,30)
	input:SetPos(10,40)
	input:SetFocus(true)
	input.OnEnter=function()
		love.filesystem.createDirectory("save")
		local file = love.filesystem.newFile("save/"..input:GetText()..".lua")
		file:open("w")
		file:write(table.save(editor.system.undoStack[editor.system.undoIndex].world))
		file:close()
		input:Remove()
		frame:Remove()
	end
end

function interface:updateHistoryFrame()
	local histroyList=self.histroyList
	histroyList:Clear()
	for i,v in ipairs(editor.system.undoStack) do
		local b= ui.Create("button")
		b:SetText(v.event)
		histroyList:AddItem(b)
		b.stackPos=i
		b.OnClick=function(obj)
			editor.system:returnTo(obj.stackPos)
		end
	end

end


function interface:createHistroyFrame()
	local frame =ui.Create("frame")
	self.historyFrame=frame
	local stack=editor.system.undoStack
	local count=#stack

	self.histroyCount=count
	local max=9
	frame:SetName("history")
	frame:SetSize(100,30*max+28)
	frame:SetPos(180, 40)
	local list = ui.Create("list",frame)
	list:SetDisplayType("vertical")
	list:SetPos(5, 30)
	list:SetSize(90, 29.5*max)
	list:SetSpacing(0)
	list:SetPadding(0)
	self.histroyList=list
	self:updateHistoryFrame()
end


function interface:createLoadWorldFrame()
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
				editor.selector.selection=nil
				frame:Remove()
			end
		end
	end

end






function interface:updatePropFrame()
	
	local selection = editor.selector.selection
	
	if not selection then 
		self:removePropFrame()
		self.propTarget=nil
		return 
	end

	local target=selection[1]

	if target==self.propTarget then
		if not self:isHover() then 
			if not self.uiVisible[3].toggle then return end
			self:resetPropFrame()
		end
	else
		self:removePropFrame()
		self:createPropFrame(target)
	end
	
end

function interface:resetPropFrame()
	local target=self.propTarget
	local tag=self.targetType
	local hasUserData
	
	if target.getUserData then hasUserData=true end
	local prop={}
	local data
	if hasUserData then
		data=target:getUserData()
	end
	local tmp=editor.helper.getStatus(target,tag)
	for i,v in ipairs(editor.helper.properties[tag]) do
		if tmp[v]~=nil then table.insert(prop,{prop=v,value=tmp[v]}) end
	end

	self.targetProp=prop
	self.targetData=data


	for i,v in ipairs(self.targetProp) do
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

	if not self.targetData then return end

	for i,v in ipairs(self.targetData) do
		local value=self.dataGrid[i][2]
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
		self.propFrame:Remove() 
	end
end


local function setProp(target,prop,...)
	
	if target["get"..prop] or target["is"..prop] or target["has"..prop] then
		if target["set"..prop] then target["set"..prop](target,...) end
	elseif target.update then --tt's a world
		if prop=="meter" then
			love.physics.setMeter(...)
		else
			editor[prop]=...
		end
	else
		for i,v in ipairs(target:getUserData()) do
			if v.prop==prop then
				v.value=...
				break
			end
		end
	end
	
	
	editor.action="change property"

end

function interface:setListItems(target,v)
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
	elseif type(v.value)=="userdata" then 
		value = ui.Create("textinput")
		value:SetText(tostring(v.value))
		value:SetEditable(false)
	end

	return key,value
end

local function makeList(count)
	local list = ui.Create("grid")
	list:SetPos(0, 0)
	list:SetCellWidth(100)
	list:SetCellHeight(20)
	list:SetRows(count)
	list:SetColumns(2)
	list:SetItemAutoSize(true)
	return list
end 



function interface:createPropFrame(target)
	local tType= string.lower(target:type()) 
	if string.find(tType,"joint") then tType="joint" end
	if string.find(tType,"shape") then tType="shape" end

	self.propTarget=target
	self.targetType=tType
	local hasUserData
	if target.getUserData then hasUserData=true end
	local prop={}
	local data={}
	if hasUserData then
		data=target:getUserData()
		if not data then
			error("no user data")
		end
	end
	local tmp=editor.helper.getStatus(target,tType)
	for i,v in ipairs(editor.helper.properties[tType]) do --为了排序
		if tmp[v]~=nil then table.insert(prop,{prop=v,value=tmp[v]}) end
	end
	self.targetProp=prop
	self.targetData=data

	self.propFrame= ui.Create("frame")
	self.propFrame:SetVisible(self.uiVisible[3].toggle)

	local count=#self.targetData+1>#self.targetProp and  #self.targetData+1 or #self.targetProp
	
	local frame = self.propFrame
	frame:SetName(tType)
	frame:SetSize(250, 70+count*30)
	frame:SetPos(w()-250, h()-(70+count*30))
	frame:ShowCloseButton(false)

	local tabs= ui.Create("tabs",frame)
	tabs:SetPos(5, 30)
	tabs:SetSize(240, count*30+35)

	self.propList=makeList(count)
	tabs:AddTab("Property", self.propList)

	self.propGrid={}
	for i,v in ipairs(self.targetProp) do
		local key,value= self:setListItems(target,v)
		self.propList:AddItem(key,i,1)
		self.propList:AddItem(value,i,2)
		table.insert(self.propGrid, {key,value})
	end
	self.propList:update()

	if not hasUserData then return end

	self.dataList=makeList(count)
	tabs:AddTab("UserData", self.dataList)
	self.dataGrid={}
	for i,v in ipairs(self.targetData) do
		local key,value= self:setListItems(target,v)
		self.dataList:AddItem(key,i,1)
		self.dataList:AddItem(value,i,2)
		table.insert(self.dataGrid, {key,value})
	end
	
	
	local name = ui.Create("textinput")
	local value = ui.Create("textinput")
	name:SetText("*new")
	name.OnFocusGained=function()
		name:SetText("")
	end
	
	name.OnEnter=function(obj)
		local k=name:GetText()
		local v=value:GetText()
		table.insert(target:getUserData(), {prop=k,value=v})
		self:removePropFrame()
		self:createPropFrame()
		obj.focus=false
	end
	value:SetText("none")
	value.OnFocusGained=function()
		value:SetText("")
	end
	
	value.OnEnter=function(obj)
		local k=name:GetText()
		local v=value:GetText()
		table.insert(target:getUserData(), {prop=k,value=v})
		self:removePropFrame()
		self:createPropFrame()
		obj.focus=false
	end
	self.dataList:AddItem(name,#self.targetData+1,1)
	self.dataList:AddItem(value,#self.targetData+1,2)
	
	self.dataList:update()

	if tType~="body" then return end
	
	self.worldList=makeList(count)
	tabs:AddTab("  world  ", self.worldList)
	self.worldGrid={}
	self.worldData={
		{prop="meter",value= love.physics.getMeter()},
		{prop="Gravity",value={editor.world:getGravity()}},
		{prop="linearDamping",value=editor.linearDamping},
		{prop="angularDamping",value=editor.angularDamping},
		{prop="SleepingAllowed",value=editor.world:isSleepingAllowed()}

	}
	for i,v in ipairs(self.worldData) do
		local key,value= self:setListItems(editor.world,v)
		self.worldList:AddItem(key,i,1)
		self.worldList:AddItem(value,i,2)
		table.insert(self.worldGrid, {key,value})
	end

end

local font = love.graphics.newFont(15)

local aboutText=[[

			Box2D Editor for Love
				
				  version 0.0.1

				program: Alexar

			All Right Reserved. 2016
]]

function interface:createAboutFrame()
	if self.aboutFrame then self.aboutFrame:Remove() end
	local frame =ui.Create("frame")
	self.aboutFrame=frame
	frame:SetName("about")
	frame:SetSize(300,200)
	frame:CenterWithinArea(0,0,w(),h())
	local text = ui.Create("text",frame)
	text:SetPos(10,30)
	text:SetFont(font)
	text:SetText(aboutText)
end

local helpText= require "editor/helpText"
local font = love.graphics.newFont("font/cn.ttf", 20)

function interface:createHelpFrame()
	if self.helpFrame then self.helpFrame:Remove() end
	local frame =ui.Create("frame")
	self.helpFrame=frame
	frame:SetName("help")
	frame:SetSize(500,600)
	frame:CenterWithinArea(0,0,w(),h())

	local list = ui.Create("list", frame)
	list:SetPos(5, 30)
	list:SetSize(490, 565)
	list:SetPadding(5)
	list:SetSpacing(5)


	
	local text = ui.Create("text",frame)
	text:SetPos(10,30)
	text:SetFont(font)
	text:SetText(helpText)

	list:AddItem(text)
end

return function(parent) 
	editor=parent
	return interface
end