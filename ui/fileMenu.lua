local file={}
local editor
local ui
local interface



function file:create()
	local menu = ui.Create("menu")
	file.menu=menu
	menu:AddOption("New Project", false, function() end)
	menu:AddOption("Save Project", false, function() end)
	menu:AddOption("Load Project", false, function() end)
	menu:AddOption("Save Project As ", false, function() end)
	menu:AddDivider()

	menu:AddOption("New Scene", false, function() end)
	menu:AddOption("Save Scene", false, function() end)
	menu:AddOption("Load Scene", false, function() end)
	menu:AddOption("Save Scene As ", false, function() end)
	menu:AddDivider()

	menu:AddOption("Option", false, function() end)
	menu:AddOption("Help", false, function() end)
	menu:AddOption("About", false, function() end)
	menu:AddDivider()

	menu:AddOption("Quit", false, function() end)
	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return file
end