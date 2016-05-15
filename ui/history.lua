local history={}
local ui
local interface
local editor

function history:update()
	local list=self.list
	list:Clear()
	for i,v in ipairs(editor.system.undoStack) do
		local b= ui.Create("button")
		b:SetText(v.event)
		list:AddItem(b)
		b.stackPos=i
		b.OnClick=function(obj)
			editor.system:returnTo(obj.stackPos)
		end
	end

end


function history:create()
	local frame =ui.Create("frame")
	self.frame=frame
	local stack=editor.system.undoStack
	local count=#stack

	self.count=count
	local max=9
	frame:SetName("history")
	frame:SetSize(100,30*max+28)
	frame:ShowCloseButton(false)
	frame:SetPos(interface.layout.history and interface.layout.history[1] or 180 ,
				interface.layout.history and interface.layout.history[2] or  40)

	local list = ui.Create("list",frame)
	list:SetDisplayType("vertical")
	list:SetPos(5, 30)
	list:SetSize(90, 29.5*max)
	list:SetSpacing(0)
	list:SetPadding(0)
	self.list=list
	self:update()
end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return history
end