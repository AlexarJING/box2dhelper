local view={}
local editor
local ui
local interface



function view:create()
	local menu = ui.Create("menu")
	view.menu=menu
	self.options={}
	menu:AddDivider()
	self.options.body=menu:AddOption("刚体", false, 
		function(obj) interface:setView("body",obj.toggle) end,true)
	menu:AddDivider()
	self.options.texture=menu:AddOption("纹理", false, 
		function(obj) interface:setView("texture",obj.toggle) end,true)
	menu:AddDivider()
	self.options.fixture=menu:AddOption("部件", false,
		function(obj) interface:setView("fixture",obj.toggle) end,true)
	menu:AddDivider()
	self.options.joint=menu:AddOption("连接", false,
		function(obj) interface:setView("joint",obj.toggle) end,true)
	menu:AddDivider()
	self.options.contact=menu:AddOption("碰撞", false, function(obj)
		interface:setView("contact",obj.toggle)
	end,true)
	menu:AddDivider()
	self.options.bloom=menu:AddOption("泛光", false, 
		function(obj)
			interface:setView("bloom",obj.toggle)
		end,true)
	self.options.trace=menu:AddOption("尾迹", false, 
		function(obj)
			interface:setView("trace",obj.toggle)
		end,true)
	menu:AddDivider()
	menu:AddOption("只有纹理", false, 
		function() 
			interface:setView("body",false)
			interface:setView("texture",true)
			interface:setView("fixture",false)
			interface:setView("joint",false)
			interface:setView("contact",false)
		end)
	menu:AddDivider()
	menu:AddOption("只有部件", false, 
		function() 
			interface:setView("body",false)
			interface:setView("texture",false)
			interface:setView("fixture",true)
			interface:setView("joint",false)
			interface:setView("contact",false)
		end)
	menu:AddDivider()
	
	menu:AddOption("全部", false, 
		function() 
			interface:setView("body",true)
			interface:setView("texture",true)
			interface:setView("fixture",true)
			interface:setView("joint",true)
			interface:setView("contact",true)
		end)
	menu:AddDivider()
	menu:AddOption("色彩编辑", false, function() editor.interface.colorPick:create()end)
	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return view
end