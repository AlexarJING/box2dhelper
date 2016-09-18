local layout={}
local editor
local ui
local interface



function layout:create()
	local menu = ui.Create("menu")
	layout.menu=menu
	self.options={}
	self.options.grid=menu:AddOption("网格标尺", false, 
		function(obj) interface:setVisible("grid",obj.toggle) end,true)
	self.options.log=menu:AddOption("日志", false,
		function(obj) interface:setVisible("log",obj.toggle) end,true)
	self.options.info=menu:AddOption("信息", false, 
		function(obj) interface:setVisible("info",obj.toggle) end,true)
	menu:AddDivider()
	self.options.build=menu:AddOption("建造", false, 
		function(obj) interface:setVisible("build",obj.toggle) end,true)
	self.options.joint=menu:AddOption("连接", false, 
		function(obj) interface:setVisible("joint",obj.toggle) end,true)
	menu:AddDivider()

	self.options.history=menu:AddOption("历史", false, 
		function(obj) interface:setVisible("histroy",obj.toggle) end,true)
	self.options.unit=menu:AddOption("单位", false, 
		function(obj) interface:setVisible("unit",obj.toggle)end,true)
	self.options.scene=menu:AddOption("场景", false, 
		function(obj) interface:setVisible("scene",obj.toggle)end,true)
	menu:AddDivider()
	self.options.property=menu:AddOption("属性", false, 
		function(obj) interface:setVisible("property",obj.toggle) end,true)
	menu:AddDivider()

	menu:AddOption("隐藏所有", false, function() 
			for k,v in pairs(interface.visible) do
				if k~="system" then
					interface:setVisible(k,false)
				end
			end
		end)
	menu:AddOption("显示所有", false, function() 
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