local edit={}
local editor
local ui
local interface



function edit:create()
	local menu = ui.Create("menu")
	edit.menu=menu
	menu:AddOption("撤销", false, function() editor.system:undo() end)
	menu:AddOption("重做", false, function() editor.system:redo() end)
	menu:AddOption("复制", false, function() editor.bodyMode:copy() end)
	menu:AddOption("粘贴", false, function() editor.bodyMode:paste() end)
	menu:AddOption("保存单位", false, function() editor.unitManage:save() end)

	menu:AddDivider()

	menu:AddOption("全选", false, function() editor.selector:selectAll() end)
	menu:AddOption("空选", false, function() editor.selector:clearSelection() end)
	menu:AddOption("反选", false, function() editor.selector:inverseSelection() end)
	
	menu:AddDivider()

	menu:AddOption("清除场景", false, function() editor.system:clear() end)
	menu:AddOption("删除刚体", false, function() editor.bodyMode:removeBody() end)
	menu:AddOption("删除连接", false, function() editor.bodyMode:removeJoint() end)

	menu:AddDivider()

	menu:AddOption("合并刚体", false, function()editor.bodyMode:combine() end)
	menu:AddOption("拆分刚体", false, function() editor.bodyMode:divide()end)
	menu:AddOption("切换刚体类型", false, function() editor.bodyMode:toggleBodyType() end)
	menu:AddDivider()

	menu:AddOption("水平对齐", false, function() editor.bodyMode:aline(true) end)
	menu:AddOption("竖直对齐", false, function() editor.bodyMode:aline(false) end)
	menu:AddDivider()
	
	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return edit
end