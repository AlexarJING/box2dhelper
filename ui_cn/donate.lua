local editor
local ui
local interface
local donate={}

local donateText=[[
					感谢您的支持！
					QQ: 1643386616
			Email:alexar@foxmail.com						 
]]

function donate:create()
	if self.frame then self.frame:Remove() end
	local frame =ui.Create("frame")
	self.frame=frame
	frame:SetName("支持及赞助")
	frame:SetSize(300,330)
	frame:CenterWithinArea(0,0,w(),h())
	local image = ui.Create("image",frame)
	image:SetPos(50,50)
	image:SetImage("icons/pay.png")
	image:SetScale(0.5,0.5)
	local text = ui.Create("text",frame)
	text:SetPos(30,260)
	text:SetSize(290,80)
	text:SetText(donateText)
	--love.system.openURL("http://pay.qq.com/")
end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return donate
end

