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
	b:SetText("系统")
	b.OnClick=function(button)
		local x,y = button:GetPos()
		interface.fileMenu.menu:SetPos(x,y+30)
		interface.fileMenu.menu:SetVisible(true)
	end
	list:AddItem(b)

	local b= ui.Create("button")
	b:SetText("编辑")
	b.OnClick=function(button)
		local x,y = button:GetPos()
		interface.editMenu.menu:SetPos(x,y+30)
		interface.editMenu.menu:SetVisible(true)
	end
	list:AddItem(b)

	local b= ui.Create("button")
	b:SetText("模式")
	b.OnClick=function(button)
		local x,y = button:GetPos()
		interface.modeMenu.menu:SetPos(x,y+30)
		interface.modeMenu.menu:SetVisible(true)
	end
	list:AddItem(b)

	local b= ui.Create("button")
	b:SetText("布局")
	b.OnClick=function(button)
		local x,y = button:GetPos()
		interface.layoutMenu.menu:SetPos(x,y+30)
		interface.layoutMenu.menu:SetVisible(true)
	end
	list:AddItem(b)

	local b= ui.Create("button")
	b:SetText("可视")
	b.OnClick=function(button)
		local x,y = button:GetPos()
		interface.viewMenu.menu:SetPos(x,y+30)
		interface.viewMenu.menu:SetVisible(true)
	end
	list:AddItem(b)

	local b= ui.Create("button")
	b:SetText("赞助")
	b.OnClick=function(button)
		interface.donate:create()
	end
	list:AddItem(b)

	local t=ui.Create("text")
	t:SetText("当前项目: "..editor.currentProject..";             当前场景: "..editor.currentScene..";")
	t:SetPos(700,10)
	--list:AddItem(t)
	self.projInfo=t
end

function system:updateProj()
	self.projInfo:SetText("当前项目: "..editor.currentProject..";             当前场景: "..editor.currentScene..";")
	interface.scene:create()
end


function system:update()


end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return system
end