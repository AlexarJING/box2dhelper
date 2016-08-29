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
			editor.system:saveAsProject() 
		end)
	menu:AddDivider()

	menu:AddOption("New Scene", false, function() editor.system:newScene()end)
	menu:AddOption("Save Scene", false, function() editor.system:saveScene()end)
	menu:AddOption("Save Scene As ", false, 
		function() 
			editor.currentScene="default"
			editor.system:saveScene() 
		end)
	menu:AddDivider()

	menu:AddOption("Key Config", false, function() interface.keyconfig:create() end)
	menu:AddOption("Help", false, function() 
		interface.help:create() 
	end)
	menu:AddOption("Tutorial", false, function() interface.tutorial:create() end)
	menu:AddOption("About", false, function() interface.about:create() end)
	menu:AddDivider()

	menu:AddOption("Quit", false, function() love.event.quit() end)
	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return file
end