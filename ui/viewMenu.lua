local view={}
local editor
local ui
local interface



function view:create()
	local menu = ui.Create("menu")
	view.menu=menu
	menu:AddDivider()
	menu:AddOption("body", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("texture", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("fixture", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("joint", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("contact", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("texture only", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("bloom", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("all", false, function() end,true)
	menu:AddDivider()
	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return view
end