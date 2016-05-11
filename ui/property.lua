local property={}
local editor
local ui
local interface

function property:update()
	
	local selection = editor.selector.selection
	
	if not selection then 
		self:remove()
		return 
	end

	local target=selection[1]

	if not target or ( target.isDestroyed and target:isDestroyed() )then
		self:remove()
		return 	
	end

	if target==self.target then
		if not interface:isHover() then  --update data
			if not interface.visible.property then return end
			self:reset()
		end
	else
		self:remove() --rebuild frame
		self:create(target)
	end
	
end

local function updateData(obj,value)
	if type(value)=="number" then
		obj:SetText(tostring(value))
	elseif type(value)=="table" then
		local str=""
		for i,v in ipairs(value) do
			str=str..tostring(v)..","
		end
		obj:SetText(str)
	elseif type(value)=="boolean" then
		obj:SetChecked(value)
	elseif type(value)=="string" then
		obj:SetText(tostring(value))
	end	
end


function property:reset()  --update all data
	
	self:prepairData()

	for i,v in ipairs(self.targetProp) do
		local value=self.propGrid[i][2]
		updateData(value,v.value)
	end

	if not self.targetData then return end

	for i,v in ipairs(self.targetData) do
		local value=self.dataGrid[i][2]
		updateData(value,v.value)
	end
end

function property:remove()
	
	if self.frame then
		property.tabIndex=property.tabs.tab
		self.frame:Remove() 
	end
	self.target=nil
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
		editor.helper.setProperty(target,prop,...)
	end
	
	editor.action="change property"
end

local function removeProp(target,prop,...)
	local data=target:getUserData()
	for i,v in ipairs(data) do
		if v.prop==prop then
			table.remove(data, i)
			return
		end
	end
	
	editor.action="remove property"
end

function property:setListItems(parent,pos,target,data,itemCanRemove)
	local key = ui.Create("button")
	key:SetText(data.prop)

	if itemCanRemove then
		key.OnClick=function(obj)
			if love.keyboard.isDown("lctrl") and 
				love.keyboard.isDown("lalt") then
				removeProp(target,data.prop)
				self:remove()
				self:create()
			end
		end
	end


	local value
	if type(data.value)=="number" then
		value = ui.Create("textinput")
		value:SetText(tostring(data.value))
		value.OnEnter=function(obj)
			local text=value:GetText()
			local num=tonumber(text)
			if num then
				setProp(target,data.prop,num)
			end
			obj.focus=false
		end
		
	elseif type(data.value)=="table" then
		value = ui.Create("textinput")
		local str=""
		for i,v in ipairs(data.value) do
			str=str..tostring(v)..","
		end
		value:SetText(str)
		value.OnEnter=function(obj)
			local text=value:GetText()
			local tab= string.split(text,",")
			setProp(target,data.prop,unpack(tab))
			obj.focus=false
		end
		
	elseif type(data.value)=="boolean" then
		value = ui.Create("checkbox")
		value:SetChecked(data.value)
		value.OnChanged=function()
			setProp(target,data.prop,value:GetChecked())
		end
		
	elseif type(data.value)=="string" then
		value = ui.Create("textinput")
		value:SetText(tostring(data.value))
		value.OnEnter=function(obj)
			local text=value:GetText()
			setProp(target,data.prop,text)
			obj.focus=false
		end
	elseif type(data.value)=="userdata" then 
		value = ui.Create("textinput")
		value:SetText(tostring(data.value))
		value:SetEditable(false)
	end

	parent:AddItem(key,pos,1)
	parent:AddItem(value,pos,2)

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



function property:create(target)
	target = target or editor.selector.selection[1]
	self:prepairData(target)
	self:createFrame()
	self:createPropertyTab()
	
	if self.targetData then 
		property:createUserDataTab()
	end
	
	if self.targetType=="body" then 
		self:createWorldTab()
	end
	self.tabs:SwitchToTab(self.tabIndex or 1)
end

function property:prepairData(target)
	local tType

	if target then
		tType= string.lower(target:type()) 
		if string.find(tType,"joint") then tType="joint" end
		if string.find(tType,"shape") then tType="shape" end

		self.target=target
		self.targetType=tType
	else
		target=self.target
		tType=self.targetType
	end


	
	local data=target.getUserData and target:getUserData()
	
	local prop={}
	local tmp=editor.helper.getStatus(target,tType)
	for i,v in ipairs(editor.helper.properties[tType]) do --为了排序
		if tmp[v]~=nil then table.insert(prop,{prop=v,value=tmp[v]}) end
	end
	self.targetProp=prop
	self.targetData=data
end


function property:createFrame()
	self.frame= ui.Create("frame")
	self.frame:SetVisible(interface.visible.property)
	local count
	if self.targetType=="body" then
		count=#self.targetData+1>#self.targetProp+1 and  
		#self.targetData+1 or #self.targetProp+1
	elseif self.targetType=="fixture" then
		count=#self.targetData+1>#self.targetProp+2 and  
		#self.targetData+1 or #self.targetProp+2
	else
		count=#self.targetData+1>#self.targetProp and  
		#self.targetData+1 or #self.targetProp
	end

	self.rowCount=count
	local frame = self.frame
	frame:SetName(self.targetType)
	
	frame:SetSize(250, 70+count*30)

	frame:SetPos(w()-250, 30)
	interface.layout.property={frame:GetPos()}

	frame:ShowCloseButton(false)
	local tabs= ui.Create("tabs",self.frame)
	self.tabs=tabs
	tabs:SetPos(5, 30)
	tabs:SetSize(240, count*30+35)

end


function property:createPropertyTab()
	
	self.propList=makeList(self.rowCount)
	self.tabs:AddTab("Property", self.propList)
	self.propGrid={}

	
	for i,v in ipairs(self.targetProp) do
		local key,value= self:setListItems(self.propList,i,self.target,v)
		table.insert(self.propGrid, {key,value})
	end

	if self.targetType=="fixture" then
		self:createMaterialRow()
		self:createReactRow()
	end

	if self.targetType=="body" then
		self:createInteractRow()
	end

	self.propList:update()
	
end


function property:createUserDataTab()
	self.dataList=makeList(self.rowCount)
	self.tabs:AddTab("UserData", self.dataList)
	self.dataGrid={}

	for i,v in ipairs(self.targetData) do
		local key,value= self:setListItems(self.dataList,i,self.target,v,true)
		table.insert(self.dataGrid, {key,value})
	end
	self:createAddRow(#self.targetData+1)
	self.dataList:update()
end

function property:createWorldTab()
	self.worldList=makeList(self.rowCount)
	self.tabs:AddTab("  world  ", self.worldList)
	self.worldGrid={}
	self.worldData={
		{prop="meter",value= love.physics.getMeter()},
		{prop="Gravity",value={editor.world:getGravity()}},
		{prop="linearDamping",value=editor.linearDamping},
		{prop="angularDamping",value=editor.angularDamping},
		{prop="SleepingAllowed",value=editor.world:isSleepingAllowed()}

	}
	for i,v in ipairs(self.worldData) do
		local key,value= self:setListItems(self.worldList,i,editor.world,v)
		table.insert(self.worldGrid, {key,value})
	end
	self.worldList:update()
end

function property:createAddRow(pos)
	local name = ui.Create("textinput")
	local value = ui.Create("textinput")
	name:SetText("*new")
	name.OnFocusGained=function()
		name:SetText("")
	end
	
	name.OnEnter=function(obj)
		local k=name:GetText()
		local v=value:GetText()
		editor.helper.setProperty(self.target,k,v)
		self:remove()
		self:create(editor.selector.selection[1])
		obj.focus=false
	end
	value:SetText("none")
	value.OnFocusGained=function()
		value:SetText("")
	end
	
	value.OnEnter=function(obj)
		local k=name:GetText()
		local v=value:GetText()
		editor.helper.setProperty(self.target,k,v)
		self:remove()
		self:create(editor.selector.selection[1])
		obj.focus=false
	end
	self.dataList:AddItem(name,pos,1)
	self.dataList:AddItem(value,pos,2)
	
end

local interacts={
	a={key=1,key2=2,key3=3},
	b={key=1,key2=2,key3=3},
}

function property:createInteractRow()
	local name = ui.Create("button")
	local value = ui.Create("multichoice")
	name:SetText("reaction")
	
	
	value:SetText("Add a Reaction")
	for k,v in pairs(interacts) do
		value:AddChoice(k)
	end
	
	value.OnChoiceSelected = function(object, choice)
	   
	end
	self.propList:AddItem(name,#self.propGrid+1,1)
	self.propList:AddItem(value,#self.propGrid+1,2)
end


function property:createMaterialRow()
	local name = ui.Create("button")
	local value = ui.Create("multichoice")
	name:SetText("material")

	local mat= editor.helper.getProperty(self.target,"material")

	if mat then
		value:SetText(mat)
	else
		value:SetText("select")
	end
	
	for k,v in pairs(editor.createMode.materials) do
		value:AddChoice(k)
	end
	
	value.OnChoiceSelected = function(object, choice)
	    editor.createMode:setMaterial(self.target,choice)
	    self:remove()
		self:create(editor.selector.selection[1])
	end

	self.propList:AddItem(name,#self.propGrid+1,1)
	self.propList:AddItem(value,#self.propGrid+1,2)
end


function property:createReactRow()
	local name = ui.Create("button")
	local value = ui.Create("multichoice")
	name:SetText("reaction")
	
	
	value:SetText("Add a Reaction")
	for k,v in pairs(interacts) do
		value:AddChoice(k)
	end
	
	value.OnChoiceSelected = function(object, choice)
	    print(choice .. " was selected.")
	end
	self.propList:AddItem(name,#self.propGrid+1,1)
	self.propList:AddItem(value,#self.propGrid+1,2)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return property
end