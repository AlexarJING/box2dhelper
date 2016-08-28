local layout={}
local editor
local ui
local interface



function layout:create()
	local menu = ui.Create("menu")
	layout.menu=menu
	self.options={}
	self.options.grid=menu:AddOption("ruler grid", false, 
		function(obj) interface:setVisible("grid",obj.toggle) end,true)
	self.options.log=menu:AddOption("log", false,
		function(obj) interface:setVisible("log",obj.toggle) end,true)
	self.options.info=menu:AddOption("information", false, 
		function(obj) interface:setVisible("info",obj.toggle) end,true)
	menu:AddDivider()
	self.options.build=menu:AddOption("build frame", false, 
		function(obj) interface:setVisible("build",obj.toggle) end,true)
	self.options.joint=menu:AddOption("joint frame", false, 
		function(obj) interface:setVisible("joint",obj.toggle) end,true)
	menu:AddDivider()

	self.options.history=menu:AddOption("histroy frame", false, 
		function(obj) interface:setVisible("histroy",obj.toggle) end,true)
	self.options.unit=menu:AddOption("units frame", false, 
		function(obj) interface:setVisible("unit",obj.toggle)end,true)
	self.options.scene=menu:AddOption("scene frame", false, 
		function(obj) interface:setVisible("scene",obj.toggle)end,true)
	menu:AddDivider()
	self.options.property=menu:AddOption("property frame", false, 
		function(obj) interface:setVisible("property",obj.toggle) end,true)
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