local editor
local ui
local interface
local help={}

local helpText= require "editor/helpText"
local font = love.graphics.newFont("font/cn.ttf", 20)

function help:create()

	local frame =ui.Create("frame")
	self.frame=frame

	local count=#helpText
	frame:SetName("帮助文档")
	frame:SetSize(1000,700)
	frame:CenterWithinArea(0,0,w(),h())
	local list = ui.Create("list",frame)
	list:SetDisplayType("vertical")
	list:SetPos(5, 30)
	list:SetSize(190, 665)
	list:SetSpacing(3)
	list:SetPadding(3)
	for i,v in ipairs(helpText) do
		local b= ui.Create("button")
		b:SetText(v.title)
		list:AddItem(b)
		b.OnClick=function() --copy to editor.selector.copied	
			self:setText(i)
		end
	end
	self:createRead(0)

end


function help:createRead()
	
	local frame = self.frame
	local list = ui.Create("list", frame)
	list:SetPos(200, 30)
	list:SetSize(790, 665)
	list:SetPadding(5)
	list:SetSpacing(5)

	
	local text = ui.Create("text")
	text:SetPos(10,30)
	text:SetText(helpText[0].content)
	self.content = text
	list:AddItem(text)
end

function help:setText(paragragh)
	self.content:SetText(helpText[paragragh].content)
end


return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return help
end