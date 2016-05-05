local info={}
local ui
local interface
local editor

function info:create()
	info.panel=ui.Create("panel")
	local panel=info.panel
	panel:SetSize(w(),30)
	panel:SetPos(0,h()-30)

	local t=ui.Create("text",panel)
	t:SetPos(100,10)
	t:SetText("current mode")

	local t=ui.Create("text",panel)
	t:SetPos(300,10)
	t:SetText("current selection")

	local t=ui.Create("text",panel)
	t:SetPos(500,10)
	t:SetText("screen x")

	local t=ui.Create("text",panel)
	t:SetPos(600,10)
	t:SetText("screen y")

	local t=ui.Create("text",panel)
	t:SetPos(700,10)
	t:SetText("world x")

	local t=ui.Create("text",panel)
	t:SetPos(800,10)
	t:SetText("world y")

	local t=ui.Create("text",panel)
	t:SetPos(900,10)
	t:SetText("scale")

	local t=ui.Create("text",panel)
	t:SetPos(1000,10)
	t:SetText("Gx")

	local t=ui.Create("text",panel)
	t:SetPos(1100,10)
	t:SetText("Gy")

	local t=ui.Create("text",panel)
	t:SetPos(1200,10)
	t:SetText("bodyCount")

	local t=ui.Create("text",panel)
	t:SetPos(1300,10)
	t:SetText("FPS")
end




return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return info
end