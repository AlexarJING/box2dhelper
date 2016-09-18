local mode={}
local editor
local ui
local interface



function mode:create()
	local menu = ui.Create("menu")
	mode.menu=menu
	menu.isSingleChoice=true
	self.choice={}
	menu:AddDivider()
	self.choice.body=menu:AddOption("刚体模式", false, function() editor:changeMode("body") end,true)
	menu:AddDivider()
	self.choice.fixture=menu:AddOption("部件模式", false, function() editor:changeMode("fixture")end)
	menu:AddDivider()
	self.choice.shape=menu:AddOption("形状模式", false, function() editor:changeMode("shape")end)
	menu:AddDivider()
	self.choice.joint=menu:AddOption("连接模式", false, function() editor:changeMode("joint")end)
	menu:AddDivider()
	self.choice.test=menu:AddOption("测试模式", false, function() editor:changeMode("test")end)


	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return mode
end