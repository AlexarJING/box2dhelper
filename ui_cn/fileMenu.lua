local file={}
local editor
local ui
local interface


function file:create()
	local menu = ui.Create("menu")
	file.menu=menu
	menu:AddOption("新建项目", false, function() editor.system:newProject() end)
	menu:AddOption("保存项目", false, function() editor.system:saveProject() end)
	menu:AddOption("读取项目", false, function() editor.system:loadProject()end)
	menu:AddOption("项目另存", false, 
		function() 
			editor.system:saveAsProject() 
		end)
	menu:AddDivider()

	menu:AddOption("新建场景", false, function() editor.system:newScene()end)
	menu:AddOption("保存场景", false, function() editor.system:saveScene()end)
	menu:AddOption("场景另存", false, 
		function() 
			editor.currentScene="default"
			editor.system:saveScene() 
		end)
	menu:AddDivider()

	menu:AddOption("按键配置", false, function() interface.keyconfig:create() end)
	menu:AddOption("帮助文档", false, function() 
		interface.help:create() 
	end)
	menu:AddOption("教程案例", false, function() interface.tutorial:create() end)
	menu:AddOption("关于软件", false, function() interface.about:create() end)
	menu:AddDivider()

	menu:AddOption("退出系统", false, function() love.event.quit() end)
	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return file
end