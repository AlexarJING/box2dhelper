local editor
local ui
local interface
local build={}
local createShape={"circle","box","polygon","line","edge","freeline"}
local advanced = {"softcircle","softbox","softpolygon","softrope","explosion","water"}

function build:create()
	self.frame= ui.Create("frame")
	local frame = self.frame
	frame:SetName("建造")
	frame:SetSize(50, 250)
	frame:SetPos(10, 40)
	frame:ShowCloseButton(false)

	self.list=ui.Create("list", frame)
	local list = self.list
	list:SetPos(5, 30)
	list:SetSize(39, 215)
	list:SetSpacing(3)
	list:SetPadding(3)
	self.buttons={}
	local buttons=self.buttons
	for i,v in ipairs(createShape) do
		local b= ui.Create("imagebutton")
		b:SetImage("icons/".. v ..".png")
		b:SetText("")
		b:SizeToImage()
		table.insert(self.buttons, b)
		list:AddItem(b)
		b.OnClick=function(obj)
			if love.keyboard.isDown("lshift") then
				editor.createMode:new(advanced[i])
			else
				editor.createMode:new(v)
			end
			
		end
	end
end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return build
end
