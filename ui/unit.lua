local unit={}
local editor
local ui
local interface



function unit:create()
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


function unit:createSave()
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

function unit:update()
	if #love.filesystem.getDirectoryItems("units")~=self.unitCount then
		if self.unitFrame then self.unitFrame:Remove() end
		self:createUnitFrame()
	end
end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return unit
end