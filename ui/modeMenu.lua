local mode={}
local editor
local ui
local interface



function mode:create()
	local menu = ui.Create("menu")
	mode.menu=menu
	menu:AddDivider()
	menu:AddOption("Body Mode", false, function() end,true)
	menu:AddDivider()
	menu:AddOption("Fixture Mode", false, function() end)
	menu:AddDivider()
	menu:AddOption("Shape Mode", false, function() end)
	menu:AddDivider()
	menu:AddOption("Test Mode", false, function() end)


	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return mode
end