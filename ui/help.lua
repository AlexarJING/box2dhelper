local editor
local ui
local interface
local help={}

local helpText= require "editor/helpText2"
local font = love.graphics.newFont("font/cn.ttf", 20)

function help:create()
	if self.frame then self.frame:Remove() end
	local frame =ui.Create("frame")
	self.frame=frame
	frame:SetName("help")
	frame:SetSize(500,600)
	frame:CenterWithinArea(0,0,w(),h())

	local list = ui.Create("list", frame)
	list:SetPos(5, 30)
	list:SetSize(490, 565)
	list:SetPadding(5)
	list:SetSpacing(5)

	local text = ui.Create("text",frame)
	text:SetPos(10,30)
	text:SetText(helpText)

	list:AddItem(text)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return help
end