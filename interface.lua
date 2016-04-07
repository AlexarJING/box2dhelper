local interface={}
local editor
local ui
function interface:init()
	ui=editor.LoveFrames
	--self.preview=require "preview"(editor)
	self:createBuildFrame()
	self:createJointFrame()
	self:createSystemFrame()
end

function interface:update(dt)
	ui.update(dt)
	if ui.util.GetHover() and love.mouse.isDown(1) then
		self.hover=true
	elseif not ui.util.GetHover() and not love.mouse.isDown(1) then
		self.hover=false
	end
    local hoverobject = ui.util.GetHoverObject()
    if hoverobject and hoverobject.type=="textinput" then
    	if hoverobject.focus then
    		self.hover=true
    	end
    end
end

function interface:draw()


end

function interface:isHover()
	return self.hover
end

------------------prop------------------



----------------build-------------------

local createShape={"circle","box","polygon","line","edge","freeline"}
function interface:createBuildFrame()
	self.createFrame= ui.Create("frame")
	local frame = self.createFrame
	frame:SetName("Shape")
	frame:SetSize(50, 250)
	frame:SetPos(10, 100)
	frame:ShowCloseButton(false)
	self.createList=ui.Create("list", frame)
	local list = self.createList
	list:SetPos(5, 30)
	list:SetSize(39, 215)
	list:SetSpacing(3)
	list:SetPadding(3)
	self.createButtons={}
	local createButtons=self.createButtons
	for i,v in ipairs(createShape) do
		local b= ui.Create("imagebutton")
		b:SetImage("icons/".. v ..".png")
		b:SetText("")
		b:SizeToImage()
		table.insert(self.createButtons, b)
		list:AddItem(b)
		b.OnClick=function(obj)
			editor.createMode:new(v)
		end
	end
end

local createJoint={"distance","rope","revolute","prismatic","weld","wheel","pully"}
function interface:createJointFrame()
	self.jointFrame= ui.Create("frame")
	local frame = self.jointFrame
	frame:SetName("Joint")
	frame:SetSize(50, 290)
	frame:SetPos(10, 380)
	frame:ShowCloseButton(false)
	self.jointList=ui.Create("list", frame)
	local list = self.jointList
	list:SetPos(5, 30)
	list:SetSize(39, 250)
	list:SetSpacing(3)
	list:SetPadding(3)
	self.jointButtons={}
	local jointButtons=self.jointButtons
	for i,v in ipairs(createJoint) do
		local b= ui.Create("imagebutton")
		b:SetImage("icons/".. v ..".png")
		b:SetText("")
		b:SizeToImage()
		table.insert(self.jointButtons, b)
		list:AddItem(b)
		b.OnClick=function()
			editor.createMode[v](editor.createMode)
		end
	end

end

--save,load, undo, redo,
--mode toggle edit/test/vert
--show/hide shape/joint/prop/unit/history/miniMap/world/grid

function interface:createSystemFrame()
	self.sysFrame= ui.Create("frame")
	local frame = self.sysFrame
	frame:SetName("System")
	frame:SetSize(300, 75)
	frame:SetPos(10, 10)
	frame:ShowCloseButton(false)
	self.sysList=ui.Create("list", frame)
	local list = self.sysList
	list:SetPos(5, 30)
	list:SetSize(300, 40)
	list:SetSpacing(5)
	list:SetPadding(3)
	list:SetDisplayType("horizontal")

	self.sysButtons={}
	local sysButtons=self.sysButtons
	
	local b= ui.Create("imagebutton")
	b:SetImage("icons/circle.png")
	b:SetText("")
	b:SizeToImage()
	list:AddItem(b)
	b.OnClick=function()
		print("save")
	end
	sysButtons.save=b
	local b= ui.Create("imagebutton")
	b:SetImage("icons/circle.png")
	b:SetText("")
	b:SizeToImage()
	list:AddItem(b)
	b.OnClick=function()
		print("load")
	end
	sysButtons.save=b
	local b= ui.Create("imagebutton")
	b:SetImage("icons/circle.png")
	b:SetText("")
	b:SizeToImage()
	list:AddItem(b)
	b.OnClick=function()
		print("undo")
	end
	sysButtons.save=b
	local b= ui.Create("imagebutton")
	b:SetImage("icons/circle.png")
	b:SetText("")
	b:SizeToImage()
	list:AddItem(b)
	b.OnClick=function()
		print("redo")
	end
	sysButtons.save=b
	local b= ui.Create("imagebutton")
	b:SetImage("icons/circle.png")
	b:SetText("")
	b:SizeToImage()
	list:AddItem(b)
	b.OnClick=function()
		print("ui toggle")
	end
	sysButtons.save=b
	local b= ui.Create("imagebutton")
	b:SetImage("icons/circle.png")
	b:SetText("")
	b:SizeToImage()
	list:AddItem(b)
	b.OnClick=function()
		print("")
	end
	sysButtons.save=b
end

function interface:createUnitFrame(files)


end

function interface:createLoadFrame(files)

end

function interface:createSaveFrame()


end


return function(parent) 
	editor=parent
	return interface
end