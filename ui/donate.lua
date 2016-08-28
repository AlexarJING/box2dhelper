local editor
local ui
local interface
local donate={}

local font = love.graphics.newFont(15)
local donateText=[[

	YOUR KINDNESS IS PRECIATED
								 
]]

function donate:create()
	if self.frame then self.frame:Remove() end
	local frame =ui.Create("frame")
	self.frame=frame
	frame:SetName("donate me")
	frame:SetSize(300,100)
	frame:CenterWithinArea(0,0,w(),h())
	local text = ui.Create("text",frame)
	text:SetPos(10,30)
	text:SetFont(font)
	text:SetText(donateText)
	love.system.openURL("http://pay.qq.com/")
end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return donate
end

