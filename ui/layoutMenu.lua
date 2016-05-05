local layout={}
local editor
local ui
local interface



function layout:create()
	local menu = ui.Create("menu")
	layout.menu=menu
	menu:AddOption("ruler grid", false, function() end,true)
	menu:AddOption("log", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("build frame", false, function() end,true)
	menu:AddOption("joint frame", false, function() end,true)
	menu:AddDivider()

	menu:AddOption("histroy frame", false, function() end,true)
	menu:AddOption("units frame", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("property frame", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("hide all", false, function() end,true)

	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return layout
end