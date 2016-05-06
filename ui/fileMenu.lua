local file={}
local editor
local ui
local interface



function file:create()
	local menu = ui.Create("menu")
	file.menu=menu
	menu:AddOption("New Project", false, function() editor.system:newProject() end)
	menu:AddOption("Save Project", false, function() editor.system:saveProject() end)
	menu:AddOption("Load Project", false, function() editor.system:loadProject()end)
	menu:AddOption("Save Project As ", false, 
		function() 
			editor.currentProject="default";
			editor.system:saveProject() 
		end)
	menu:AddDivider()

	menu:AddOption("New Scene", false, function() editor.system:newScene()end)
	menu:AddOption("Save Scene", false, function() editor.system:saveScene()end)
	menu:AddOption("Load Scene", false, function() editor.system:loadScene()end)
	menu:AddOption("Save Scene As ", false, 
		function() 
			editor.currentProject="default"
			editor.system:saveScene() 
		end)
	menu:AddDivider()

	menu:AddOption("Option", false, function() end)
	menu:AddOption("Help", false, function() interface.help:create() end)
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