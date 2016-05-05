local system={}
local editor
local ui
local interface

function system:create()
	self.list=ui.Create("list")
	local list = self.list
	list:SetPos(0, 0)
	list:SetSize(editor.W, 30)
	list:SetSpacing(0)
	list:SetPadding(0)
	list:SetDisplayType("horizontal")

	self.buttons={}
	local buttons=self.buttons
	
	local b= ui.Create("button")
	b:SetText("FILE")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function(button)
		--editor.system:saveToFile()
		local x,y = button:GetPos()
		
		menu:SetPos(x,y+30)
	end


	local b= ui.Create("button")
	b:SetText("load")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.system:loadFromFile()
	end

	local b= ui.Create("button")
	b:SetText("undo")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.system:undo()
	end

	local b= ui.Create("button")
	b:SetText("redo")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.system:redo()
	end

	local b= ui.Create("button")
	b:SetText("save unit")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.units:getSaveName()
	end

	local b= ui.Create("button")
	b:SetText("copy")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.bodyMode:copy()
	end

	local b= ui.Create("button")
	b:SetText("paste")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		editor.bodyMode:paste(0,0)
	end	
----------------------------------------------------
	self.toggleMode={}
	

	local modes=self.toggleMode
	
	local b= ui.Create("button")
	b:SetText("body")
	b:SetSize(70,10)
	b:SetToggleable(true)
	b.toggle=true

	list:AddItem(b)
	b.OnToggle=function(obj)
		editor:changeMode("body")
	end
	self.toggleMode.body=b

	local b= ui.Create("button")
	b:SetText("fixture")
	b:SetSize(70,10)
	b:SetToggleable(true)
	b.toggle=false

	list:AddItem(b)
	b.OnToggle=function(obj)
		editor:changeMode("fixture")
	end
	self.toggleMode.fixture=b

	local b= ui.Create("button")
	b:SetText("shape")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.OnToggle=function(obj)
		editor:changeMode("shape")
	end
	self.toggleMode.shape=b

	local b= ui.Create("button")
	b:SetText("joint")
	b:SetToggleable(true)
	b:SetSize(70,10)
	b.toggle=false
	list:AddItem(b)
	b.OnToggle=function(obj)
		editor:changeMode("joint")
	end
	self.toggleMode.joint=b

	local b= ui.Create("button")
	b:SetText("test")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.OnToggle=function(obj)
		editor:changeMode("test")
	end
	self.toggleMode.test=b


-----------------------------------------------
	local b= ui.Create("button")
	b:SetText("Hide All")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		for k,v in pairs(interface.visible) do
			interface.visible[k]=false
		end
		interface.visible.system=true
	end

	self.uiVisible={}

	local b= ui.Create("button")
	b:SetText("Grid")
	b:SetSize(70,10)
	b:SetToggleable(true)
	b.toggle=true
	list:AddItem(b)
	b.OnClick=function()
		editor.bg.visible=not editor.bg.visible
	end
	self.uiVisible.grid=b

	local b= ui.Create("button")
	b:SetText("log")
	b:SetSize(70,10)
	b:SetToggleable(true)
	b.toggle=true
	list:AddItem(b)
	b.OnClick=function()
		editor.log.visible= not editor.log.visible
	end
	self.uiVisible.log=b

	local b= ui.Create("button")
	b:SetText("Build UI")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.toggle=true
	b.OnClick=function()
		
	end
	self.uiVisible.build=b


	local b= ui.Create("button")
	b:SetText("Build UI")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.toggle=true
	b.OnClick=function()
		self.jointFrame:SetVisible(self.createFrame:GetVisible())
	end
	self.uiVisible.build=b


	local b= ui.Create("button")
	b:SetText("property UI")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.toggle=true
	b.OnClick=function()
		if self.propFrame then
			self.propFrame:SetVisible(not self.propFrame:GetVisible())
		else
			b.toggle=false
		end
	end
	self.uiVisible.property=b

	local b= ui.Create("button")
	b:SetText("unit UI")
	b:SetSize(70,10)
	list:AddItem(b)
	b:SetToggleable(true)
	b.toggle=true
	b.OnClick=function()
		self.unitFrame:SetVisible(not self.unitFrame:GetVisible())
	end
	self.uiVisible.unit=b

	

	local b= ui.Create("button")
	b:SetText("history")
	b:SetSize(70,10)
	b:SetToggleable(true)
	b.toggle=true
	list:AddItem(b)
	b.OnClick=function()
		self.historyFrame:SetVisible(not self.historyFrame:GetVisible())
	end
	self.uiVisible.history=b

	------------------------------
	local b= ui.Create("button")
	b:SetText("help")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		self:createHelpFrame()
	end

	local b= ui.Create("button")
	b:SetText("about")
	b:SetSize(70,10)
	list:AddItem(b)
	b.OnClick=function()
		self:createAboutFrame()
	end
end

function system:update()


end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return system
end