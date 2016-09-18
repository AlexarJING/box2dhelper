local editor
local ui
local interface
local keyconf={}


function keyconf:create()
	if self.frame then self.frame:Remove() end
	local frame =ui.Create("frame")
	self.frame=frame
	frame:SetName("按键设定")
	frame:SetSize(740,640)
	frame:CenterWithinArea(0,0,w(),h())


	self.lists = {}
	self.keyconf = editor.keyconf or require "editor/keyconf"
	self.keys = {}
	for action,key in pairs(self.keyconf) do
		table.insert(self.keys, {action=action,key=key})
	end

	local index = 0
	for i = 1, 3 do
		local list = ui.Create("grid",self.frame)
		list:SetPos(10+(i-1)*250, 30)
		list:SetCellWidth(100)
		list:SetCellHeight(20)
		list:SetRows(20)
		list:SetColumns(2)
		list:SetItemAutoSize(true)
		table.insert(self.lists, list)
		for i = 1, 20 do
			index= index+1
			if not self.keys[index] then break end
			local key = ui.Create("textinput")
			key:SetText(self.keys[index].key)
			key:SetEditable(false)

			local action = ui.Create("button")
			action.posIndex = index
			action:SetText(self.keys[index].action)
			action.OnClick = function(obj)
				key:SetEditable(true)
				local _keyreleased = love.keyreleased
				love.keyreleased = function(keyinput)
					local pre = ""
					if love.keyboard.isDown("lctrl") then 
						pre = "ctrl+"
					elseif love.keyboard.isDown("lalt") then
						pre = "alt+"
					end
					keyinput = pre..keyinput
					local check = false
					for i,v in ipairs(self.keys) do
						if v.key==keyinput then
							check = true
							break
						end
					end
					if not check and keyinput~="escape" then
						editor.keyconf[action:GetText()] = keyinput
						editor:keyBound()
						self:create()
					end
					love.keyreleased=_keyreleased
					key:SetEditable(false)
				end
			end
			list:AddItem(action,i,1)
			list:AddItem(key,i,2)	
		end
	end

end



return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return keyconf
end