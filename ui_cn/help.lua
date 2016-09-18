local editor
local ui
local interface
local help={}

local helpText= require "editor/helpText"
local font = love.graphics.newFont("font/cn.ttf", 20)
local text

function help:create()
	local file = love.filesystem.newFile("help.txt","w")
	string.gsub(helpText, "\n", "\n\r")
	file:write(helpText)
	file:close()
	local path = love.filesystem.getSaveDirectory().."/help.txt"
	love.system.openURL(path)
end

--[[
function help:create()
	if self.frame then self.frame:Remove() end
	local frame =ui.Create("frame")
	self.frame=frame
	frame:SetName("help")
	frame:SetSize(1000,700)
	frame:CenterWithinArea(0,0,w(),h())

	local list = ui.Create("list", frame)
	list:SetPos(5, 30)
	list:SetSize(990, 660)
	list:SetPadding(5)
	list:SetSpacing(5)

	if not text then
		text = ui.Create("text")
		text:SetFont(font)
		text:SetPos(10,30)
		text:SetText(helpText)
	end
	list:AddItem(text)
end
]]

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return help
end