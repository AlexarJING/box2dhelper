local joint={}
local ui
local editor
local interface

local createJoint={"distance","rope","revolute","prismatic","weld","wheel","pully"}
function joint:create()
	self.frame= ui.Create("frame")
	local frame = self.frame
	frame:SetName("Joint")
	frame:SetSize(50, 290)
	frame:SetPos(10, 315)
	frame:ShowCloseButton(false)
	self.list=ui.Create("list", frame)
	local list = self.list
	list:SetPos(5, 30)
	list:SetSize(39, 250)
	list:SetSpacing(3)
	list:SetPadding(3)
	self.buttons={}
	local buttons=self.buttons
	for i,v in ipairs(createJoint) do
		local b= ui.Create("imagebutton")
		b:SetImage("icons/".. v ..".png")
		b:SetText("")
		b:SizeToImage()
		table.insert(self.buttons, b)
		list:AddItem(b)
		b.OnClick=function()
			editor.createMode[v](editor.createMode)
		end
	end

end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return joint
end