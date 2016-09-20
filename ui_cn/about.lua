local editor
local ui
local interface
local about={}

local aboutText=[[
					Alexar's Physics Editor						
						版本 0.0.2
						程序: Alexar
					All Right Reserved. 2016
]]

function about:create()
	if self.frame then self.frame:Remove() end
	local frame =ui.Create("frame")
	self.frame=frame
	frame:SetName("关于本软件")
	frame:SetSize(300,100)
	frame:CenterWithinArea(0,0,w(),h())
	local text = ui.Create("text",frame)
	text:SetPos(10,30)
	text:SetText(aboutText)
end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return about
end

