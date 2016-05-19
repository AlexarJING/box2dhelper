local view={}
local editor
local ui
local interface



function view:create()
	local menu = ui.Create("menu")
	view.menu=menu
	self.options={}
	menu:AddDivider()
	self.options.body=menu:AddOption("body", false, 
		function(obj) editor.helper.visible.body=obj.toggle end,true)
	menu:AddDivider()
	self.options.texture=menu:AddOption("texture", false, 
		function(obj) editor.helper.visible.texture=obj.toggle end,true)
	menu:AddDivider()
	self.options.fixture=menu:AddOption("fixture", false, 
		function(obj) editor.helper.visible.fixture=obj.toggle end,true)
	menu:AddDivider()
	self.options.joint=menu:AddOption("joint", false,
		function(obj) editor.helper.visible.joint=obj.toggle end,true)
	menu:AddDivider()
	self.options.contact=menu:AddOption("contact", false, function(obj)
		editor.helper.visible.contact=obj.toggle
	end,true)
	menu:AddDivider()
	self.options.bloom=menu:AddOption("global bloom", false, 
		function(obj)
			interface:setView("bloom",obj.toggle)
			--interface.visible.bloom=obj.toggle
		end,true)
	menu:AddDivider()
	menu:AddOption("texture only", false, 
		function() 
			interface:setView("body",false)
			interface:setView("texture",true)
			interface:setView("fixture",false)
			interface:setView("joint",false)
			interface:setView("contact",false)
		end)
	menu:AddDivider()
	menu:AddOption("fixture only", false, 
		function() 
			interface:setView("body",false)
			interface:setView("texture",false)
			interface:setView("fixture",true)
			interface:setView("joint",false)
			interface:setView("contact",false)
		end)
	menu:AddDivider()
	
	menu:AddOption("all", false, 
		function() 
			interface:setView("body",true)
			interface:setView("texture",true)
			interface:setView("fixture",true)
			interface:setView("joint",true)
			interface:setView("contact",true)
		end)
	menu:AddDivider()
	menu:SetVisible(false)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return view
end