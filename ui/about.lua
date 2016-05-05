local editor
local ui
local interface
local about={}

local font = love.graphics.newFont(15)
local aboutText=[[

			Box2D Editor for Love
				
				  version 0.0.1

				program: Alexar

			All Right Reserved. 2016
]]

function about:create()
	if self.frame then self.frame:Remove() end
	local frame =ui.Create("frame")
	self.frame=frame
	frame:SetName("about")
	frame:SetSize(300,200)
	frame:CenterWithinArea(0,0,w(),h())
	local text = ui.Create("text",frame)
	text:SetPos(10,30)
	text:SetFont(font)
	text:SetText(aboutText)
end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return about
end

