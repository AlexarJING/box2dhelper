local system={}
local editor
local ui
local interface

function system:create()
	self.list=ui.Create("list")
	local list = self.list
	list:SetPos(0, 0)
	list:SetSize(editor.W, 30)
	list:SetSpacing(0)
	list:SetPadding(0)
	list:SetDisplayType("horizontal")


	
	local b= ui.Create("button")
	b:SetText("FILE")
	b:SetSize(70,10)
	b.OnClick=function(button)
		local x,y = button:GetPos()
		interface.fileMenu.menu:SetPos(x,y+30)
		interface.fileMenu.menu:SetVisible(true)
	end
	list:AddItem(b)

	local b= ui.Create("button")
	b:SetText("Edit")
	b:SetSize(70,10)
	b.OnClick=function(button)
		local x,y = button:GetPos()
		interface.editMenu.menu:SetPos(x,y+30)
		interface.editMenu.menu:SetVisible(true)
	end
	list:AddItem(b)

end

function system:update()


end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return system
end