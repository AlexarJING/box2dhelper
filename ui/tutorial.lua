local editor
local ui
local interface
local tutorial={}

local tutorialText= require "editor/tutorialText"
local font = love.graphics.newFont("font/cn.ttf", 20)

function tutorial:create()
	if self.frame then self.frame:Remove() end
	local frame =ui.Create("frame")
	self.frame=frame
	frame:SetName("tutorial")
	frame:SetSize(1000,700)
	frame:CenterWithinArea(0,0,w(),h())

	local list = ui.Create("list", frame)
	list:SetPos(5, 30)
	list:SetSize(990, 660)
	list:SetPadding(5)
	list:SetSpacing(5)

	local text = ui.Create("text",frame)
	text:SetFont(font)
	text:SetPos(10,30)
	text:SetText(tutorialText)

	list:AddItem(text)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return tutorial
end