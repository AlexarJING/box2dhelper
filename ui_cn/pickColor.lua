local editor
local ui
local interface
local colorPicker={}

--[[
drawMode.defaultStyle= {
		dynamic={100, 200, 255, 255},
		static={100, 100, 100, 255},
		kinematic={100, 255, 200, 255},
		sensor={0,0,-255,0},
		joint={255, 100, 100, 150},
		body={255, 0, 255, 50},
		contact={0,255,255,255}
	}]]

function colorPicker:create()
	if self.frame then self.frame:Remove() end
	local frame =ui.Create("frame")
	self.frame=frame
	frame:SetName("colorPicker")
	frame:SetSize(330,350)
	frame:CenterWithinArea(0,0,w(),h())

	local list = ui.Create("grid",self.frame)

	list:SetPos(5,30)
	list:SetCellWidth(150)
	list:SetCellHeight(35)
	list:SetRows(7)
	list:SetColumns(2)
	list:SetItemAutoSize(true)

	local colors = editor.helper.drawMode.defaultStyle

	local index = 0
	for name,color in pairs(colors) do
		local colorName = ui.Create("button")
		colorName:SetText(name)
		index = index + 1
		

		local colorInput = ui.Create("textinput")
		local str=""
		for i,v in ipairs(color) do
			str=str..tostring(v)..","
		end
		str = string.sub(str,1,-2)
		colorInput:SetText(str)
		if name == "sensor" then
			local c={} 
			for i,v in ipairs(color) do
				c[i] = colors.dynamic[i]-v
			end
			colorInput.color = c
		else
			colorInput.color = color
		end
		colorInput.OnEnter = function(obj)
			local c = obj:GetText()
			local tab= string.split(c,",")
			for i,v in ipairs(tab) do
				tab[i] = tonumber(v)
			end
			local name = colorName:GetText()
			editor.helper.drawMode.defaultStyle[name] = tab
			list:Remove()
			self:reset()
		end
		

		list:AddItem(colorName,index,1)
		list:AddItem(colorInput,index,2)	
	end
	
end

function colorPicker:reset()
	local list = ui.Create("grid",self.frame)
	list:SetPos(5,30)
	list:SetCellWidth(150)
	list:SetCellHeight(35)
	list:SetRows(7)
	list:SetColumns(2)
	list:SetItemAutoSize(true)
	self.list = list
	
	local colors = editor.helper.drawMode.defaultStyle

	local index = 0
	for name,color in pairs(colors) do
		local colorName = ui.Create("button")
		colorName:SetText(name)
		index = index + 1
		

		local colorInput = ui.Create("textinput")
		local str=""
		for i,v in ipairs(color) do
			str=str..tostring(v)..","
		end
		str = string.sub(str,1,-2)
		colorInput:SetText(str)
		if name == "sensor" then
			local c={} 
			for i,v in ipairs(color) do
				c[i] = colors.dynamic[i]-v
			end
			colorInput.color = c
		else
			colorInput.color = color
		end
		colorInput.OnEnter = function(obj)
			local c = obj:GetText()
			local tab= string.split(c,",")
			for i,v in ipairs(tab) do
				tab[i] = tonumber(v)
			end
			local name = colorName:GetText()
			editor.helper.drawMode.defaultStyle[name] = tab
			list:Remove()
			self:reset()
		end
		

		list:AddItem(colorName,index,1)
		list:AddItem(colorInput,index,2)	
	end


end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return colorPicker
end