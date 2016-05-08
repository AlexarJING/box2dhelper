local layout={}
local editor
local ui
local interface



function layout:create()
	local menu = ui.Create("menu")
	layout.menu=menu
	self.options={}
	self.options.bg=menu:AddOption("ruler grid", false, 
		function(obj) interface.visible.bg=obj.toggle;editor.interface:resetVisible() end,true)
	self.options.log=menu:AddOption("log", false,
		function(obj) interface.visible.log=obj.toggle;editor.interface:resetVisible() end,true)
	self.options.info=menu:AddOption("information", false, 
		function(obj) interface.visible.info=obj.toggle;editor.interface:resetVisible() end,true)
	menu:AddDivider()
	self.options.build=menu:AddOption("build frame", false, 
		function(obj) interface.visible.build=obj.toggle;editor.interface:resetVisible() end,true)
	self.options.joint=menu:AddOption("joint frame", false, 
		function(obj) interface.visible.joint=obj.toggle;editor.interface:resetVisible() end,true)
	menu:AddDivider()

	self.options.history=menu:AddOption("histroy frame", false, 
		function(obj) interface.visible.history=obj.toggle;editor.interface:resetVisible() end,true)
	self.options.unit=menu:AddOption("units frame", false, 
		function(obj) interface.visible.unit=obj.toggle;editor.interface:resetVisible()end,true)
	self.options.scene=menu:AddOption("scene frame", false, 
		function(obj) interface.visible.scene=obj.toggle;editor.interface:resetVisible()end,true)
	menu:AddDivider()
	self.options.property=menu:AddOption("property frame", false, 
		function(obj) interface.visible.property=obj.toggle;editor.interface:resetVisible() end,true)
	menu:AddDivider()

	menu:AddOption("hide all", false, function() 
			for k,v in pairs(interface.visible) do
				if k~="system" then
					interface:setVisible(k,false)
				end
			end
		end)
	menu:AddOption("show all", false, function() 
			for k,v in pairs(interface.visible) do
				if k~="system" then
					interface:setVisible(k,true)
				end
			end
		end)
	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return layout
end