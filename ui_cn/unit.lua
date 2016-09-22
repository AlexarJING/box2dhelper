local unit={}
local editor
local ui
local interface



function unit:create()
	if self.frame then 
		interface.layout.unit={self.frame:GetPos()}
		interface.visible.unit=self.frame:GetVisible()
		self.frame:Remove() 
	end
	local files = love.filesystem.getDirectoryItems(editor.currentProject.."/units")
	local frame =ui.Create("frame")
	self.frame=frame
	local count=#files
	self.unitCount=count
	local max=9
	frame:SetVisible(interface.visible.unit)
	frame:SetName("单位")
	frame:SetSize(100,30*max+28)
	frame:ShowCloseButton(false)
	frame:SetPos(interface.layout.unit and interface.layout.unit[1] or 70 ,
				interface.layout.unit and interface.layout.unit[2] or  40)
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
				love.filesystem.remove( editor.currentProject.."/units/"..b:GetText() )
				frame:Remove()
				self:create()
				editor.units:showPreview(false)
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


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return unit
end