local edit={}
local editor
local ui
local interface



function edit:create()
	local menu = ui.Create("menu")
	edit.menu=menu
	menu:AddOption("undo", false, function() editor.system:undo() end)
	menu:AddOption("redo", false, function() editor.system:redo() end)
	menu:AddOption("copy", false, function() editor.bodyMode:copy() end)
	menu:AddOption("past", false, function() editor.bodyMode:paste() end)
	menu:AddOption("save unit", false, function() editor.units:save() end)

	menu:AddDivider()

	menu:AddOption("Select All", false, function() editor.selector:selectAll() end)
	menu:AddOption("Select None", false, function() editor.selector:clearSelection() end)
	menu:AddOption("Select Inverse", false, function() editor.selector:inverseSelection() end)
	
	menu:AddDivider()

	menu:AddOption("clear scene", false, function() editor.system:clear() end)
	menu:AddOption("remove body", false, function() editor.bodyMode:removeBody() end)
	menu:AddOption("remove joint", false, function() editor.bodyMode:removeJoint() end)

	menu:AddDivider()

	menu:AddOption("combine body", false, function()editor.bodyMode:combine() end)
	menu:AddOption("divide body", false, function() editor.bodyMode:divide()end)
	menu:AddOption("toggle type", false, function() editor.bodyMode:toggleBodyType() end)
	menu:AddDivider()

	menu:AddOption("aline horizontal", false, function() editor.bodyMode:aline(true) end)
	menu:AddOption("aline verticle", false, function() editor.bodyMode:aline(false) end)

	
	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return edit
end