local edit={}
local editor
local ui
local interface



function edit:create()
	local menu = ui.Create("menu")
	edit.menu=menu
	menu:AddOption("undo", false, function() end)
	menu:AddOption("redo", false, function() end)
	menu:AddOption("copy", false, function() end)
	menu:AddOption("past", false, function() end)

	menu:AddDivider()

	menu:AddOption("Select All", false, function() end)
	menu:AddOption("Select None", false, function() end)
	menu:AddOption("Select Inverse", false, function() end)
	
	menu:AddDivider()

	menu:AddOption("clear scene", false, function() end)
	menu:AddOption("remove body", false, function() end)
	menu:AddOption("remove joint", false, function() end)

	menu:AddDivider()

	menu:AddOption("combine body", false, function() end)
	menu:AddOption("divide body", false, function() end)
	menu:AddOption("toggle type", false, function() end)
	menu:AddDivider()

	menu:AddOption("aline horizontal", false, function() end)
	menu:AddOption("aline verticle", false, function() end)

	
	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return edit
end