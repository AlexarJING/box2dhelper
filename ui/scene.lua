local scene={}
local editor
local ui
local interface



function scene:create()
	if self.frame then 
		interface.layout.scene={self.frame:GetPos()}
		interface.visible.scene=self.frame:GetVisible()
		self.frame:Remove() 
	end
	local files = love.filesystem.getDirectoryItems(editor.currentProject.."/scenes")
	local frame =ui.Create("frame")
	self.frame=frame
	local count=#files
	self.sceneCount=count
	local max=9
	frame:SetVisible(interface.visible.scene)
	frame:ShowCloseButton(false)
	frame:SetName("scenes")
	frame:SetSize(100,30*max+28)
	frame:SetPos(interface.layout.scene and interface.layout.scene[1] or 290 ,
				interface.layout.scene and interface.layout.scene[2] or  40)
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
				love.filesystem.remove( editor.currentProject.."/scenes/"..b:GetText() )
				frame:Remove()
				self:create()
			else
				editor.system:loadScene(b:GetText())
			end
		end
	end
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return scene
end