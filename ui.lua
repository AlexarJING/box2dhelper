function editor:updateRelativeFrame()
	if not self.selection or self.oPop~=self.selection[1][1] then
		self:popRelativeFrame()
	end

end

function editor:unpdatePopValue()
	if not self.popGrid then return end
	if not self.selection or self.oPop~=self.selection[1][1] then
		return
	end
	local tmp=helper.getStatus(self.popTarget,self.popTags[self.popTagIndex])

	self.popData={}
	local data=self.popData
	
	for i,v in ipairs(helper.properties[self.popTags[self.popTagIndex]]) do
		if tmp[v]~=nil then table.insert(data,{prop=v,value=tmp[v]}) end
	end

	for i,v in ipairs(self.popData) do

		local value=self.popGrid[i][2]
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
local createShape={
	"circle","box","polygon","line","freeLine","edge",
	
}

local createJoint={
	"distance","rope","revolute","prismatic","weld","wheel","pully"
}

function editor:popCreateFrame()
	self.createFrame= ui.Create("frame")
	local frame = self.createFrame
	frame:SetName("Creator")
	frame:SetSize(100, 440)
	frame:SetPos(10, 100)
	frame:ShowCloseButton(false)
	self.popList=ui.Create("list", frame)
	local list = self.popList
	list:SetPos(5, 30)
	list:SetSize(85, 400)
	list:SetSpacing(3)
	local title = ui.Create("text")
	title:SetText("      shape")
	list:AddItem(title)
	self.createList={}
	local createList=self.createList
	for i,v in ipairs(createShape) do
		local b= ui.Create("button")
		b:SetText(v)
		b:SetToggleable(true)
		table.insert(self.createList, b)
		list:AddItem(b)
		b.OnClick=function(obj)
			for i,v in ipairs(createList) do
				if v~=self then
					v.toggle=false
				end
				
			end	
			self.createTag=obj:GetText()
			self.uiCreate=true
			self.createOX=nil
			if self.createTag=="circle" then
				self.needPoints=true
				--self:getPoints()
			elseif self.createTag=="line" then
				self.needPoints=true
				--self:getPoints()
			elseif self.createTag=="edge" then
				self.needVerts=true
				--self:getVerts()
			elseif self.createTag=="polygon" then
				self.needVerts=true
				--self:getVerts()
			elseif self.createTag=="freeLine" then
				self.needLines=true
				--self:freeDraw()
			elseif self.createTag=="box" then
				self.needPoints=true
				--self:getPoints()
			end
			
		end
	end

	local title = ui.Create("text")
	title:SetText("       joint")
	list:AddItem(title)

	for i,v in ipairs(createJoint) do
		local b= ui.Create("button")
		b:SetText(v)
		table.insert(self.createList, b)
		list:AddItem(b)
		b.OnClick=function(obj)
			self[obj:GetText()](self)
		end
	end

end


function editor:popRelativeFrame() --弹出选中的第一个body,fixture,joint
	if self.popFrame then
		self.popList:Remove()
		self.popFrame:Remove() 
	end

	if not self.selection then 
		self.oPop=nil
		return 
	end
	local tag=self.popTags[self.popTagIndex]
	local index=self.popItemIndex
	local obj=self.selection[1][1]
	self.oPop=obj
	local target
	if tag=="body" then
		self.popItem=nil
		target=self.selection[1][1].body
	elseif tag=="shape" then
		self.popItem=self.selection[1][1].body:getFixtureList()
		target=self.popItem[index] and self.popItem[index]:getShape() or self.popItem[1]:getShape()
	elseif tag=="fixture" then
		self.popItem=self.selection[1][1].body:getFixtureList()
		target=self.popItem[index] or self.popItem[1]
	elseif tag=="joint" then
		self.popItem=self.selection[1][1].body:getJointList()
		target=self.popItem[index] or self.popItem[1]
	end	

	if not target then
		self.popItem=nil
		self.popItemIndex=1
		self.popTagIndex=1
		tag="body"
		target=self.selection[1][1].body
	end
	self.popTarget=target

	local tmp=helper.getStatus(target,tag)

	self.popData={}
	local data=self.popData
	
	for i,v in ipairs(helper.properties[tag]) do
		if tmp[v]~=nil then table.insert(data,{prop=v,value=tmp[v]}) end
	end


	self.popFrame= ui.Create("frame")
	local frame = self.popFrame
	frame:SetName(tag)
	frame:SetSize(250, 35+#data*30)
	frame:SetPos(w()*0.8, 300)
	frame:ShowCloseButton(false)
	self.popList=ui.Create("grid", frame)
	local list = self.popList
	list:SetPos(5, 30)
	list:SetSize(240, #data*20)
	list:SetCellWidth(110)
	list:SetCellHeight(20)
	list:SetRows(#data)
	list:SetColumns(2)
	list:SetItemAutoSize(true)

	self.popGrid={}
	for i,v in ipairs(data) do
		local key = ui.Create("button")
		key:SetText(v.prop)
		local value
		if type(v.value)=="number" then
			value = ui.Create("textinput")
			value:SetText(tostring(v.value))
			value.OnEnter=function()
				local text=value:GetText()
				local num=tonumber(text)
				if num then
					target["set"..v.prop](target,num)
					self.action="change property"
				end
			end
			--value.OnFocusLost=value.OnEnter
		elseif type(v.value)=="table" then
			value = ui.Create("textinput")
			local str=""
			for i,v in ipairs(v.value) do
				str=str..tostring(v)..","
			end
			value:SetText(str)
			value.OnEnter=function()
				local text=value:GetText()
				local tab= string.split(text,",")
				target["set"..v.prop](target,unpack(tab)) 
				self.action="change property"
			end
			--value.OnFocusLost=value.OnEnter
		elseif type(v.value)=="boolean" then
			value = ui.Create("checkbox")
			value:SetChecked(v.value)
			value.OnChanged=function()
				target["set"..v.prop](target,value:GetChecked()) 
				self.action="change propert"
			end
			
		elseif type(v.value)=="string" then
			value = ui.Create("textinput")
			value:SetText(tostring(v.value))
			value.OnEnter=function()
				local text=value:GetText()
				target["set"..v.prop](target,text) 
				self.action="change property"
			end
			--value.OnFocusLost=value.OnEnter
		end
		if not target["set"..v.prop] then 
			if value.SetEditable then
				value:SetEditable(false)
			else
				value:SetEnabled(false)
			end
		end
		list:AddItem(key,i,1)
		list:AddItem(value,i,2)
		table.insert(self.popGrid, {key,value})
	end


end


function editor:switchPopTag()
	self.popTagIndex=self.popTagIndex+1
	self.popTag=self.popTags[self.popTagIndex] or self.popTags[1]
	self:popRelativeFrame()
end

function editor:switchPopItemIndex()
	if not self.popItem then return end
	self.popItemIndex=self.popItemIndex+1
	if not self.popItem[self.popItemIndex] then self.popItemIndex=1 end
	self:popRelativeFrame()
end