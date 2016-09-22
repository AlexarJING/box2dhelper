function property:setListItems(parent,pos,data)
	local key = ui.Create("button")
	key:SetText(data.prop)

	local value
	if type(data.value)=="number" then
		value = ui.Create("textinput")
		value:SetText(string.format("%0.2f",data.value))
		value.OnEnter=function(obj)
			local text=value:GetText()
			local num=tonumber(text)
			if num then
				setProp(target,data.prop,num)
			else
				editor.log:push("need a number value")
				value:SetText("")
			end
			obj.focus=false
		end
		
	elseif type(data.value)=="table" then
		value = ui.Create("textinput")
		local str=""
		for i,v in ipairs(data.value) do
			if type(v)== "number" then
				str=str..string.format("%0.2f",v)..","
			else
				str=str..tostring(v)..","
			end
		end
		str = string.sub(str,1,-2)
		value:SetText(str)
		value.OnEnter=function(obj)
			local text=value:GetText()
			local tab= string.split(text,",")
			for i,v in ipairs(tab) do
				tab[i] = tonumber(v)
				if not tab[i] then 
					editor.log:push("need a number value")
					obj.focus=false
					return
				end
			end
			setProp(target,data.prop,unpack(tab))
			obj.focus=false
		end
		
	elseif type(data.value)=="boolean" then
		value = ui.Create("checkbox")
		value:SetChecked(data.value)
		value.OnChanged=function()
			if editor.state == "test" then return end 
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
	else
		value = ui.Create("textinput")
		value:SetText("nil")
		value:SetEditable(false)
	end

	key.valueObj = value
	value.keyObj = key
	parent:AddItem(key,pos,1)
	parent:AddItem(value,pos,2)

	return key,value
end


local function updateData(obj,value)
	if type(value)=="number" then
		obj:SetText(string.format("%0.2f",value))
	elseif type(value)=="table" then
		local str=""
		for i,v in ipairs(value) do
			if tonumber(v) then
				str=str..string.format("%0.2f",v)..","
			else
				str=str..tostring(v)..","
			end
		end
		str = string.sub(str,1,-2)
		obj:SetText(str)
	elseif type(value)=="boolean" then
		obj:SetChecked(value)
	elseif type(value)=="string" then
		obj:SetText(value)
	end	
end


local options = {
	{name = gridColor, value = editor.gridColor},
	{name = gridSize , value = editor.gridSize}
}