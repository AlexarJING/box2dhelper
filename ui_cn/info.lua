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
	self.text=t
	t:SetPos(10,10)
	t:SetText("current action")
end

function info:update()

	local action=editor.system.undoStack[editor.system.undoIndex] and 
		editor.system.undoStack[editor.system.undoIndex].event or "null"
	local mode = editor.state
	local selection
	if editor.selector.selection then 
		selection=#editor.selector.selection ..editor.selector.selection[1]:type()
	else
		selection="null" 
	end
	
	local screenX = love.mouse.getX()
	local screenY = love.mouse.getY()
	local worldX = editor.mouseX
	local worldY = editor.mouseY
	local scale = editor.cam.scale
	local gx , gy = editor.world:getGravity()
	local bodyCount = #editor.world:getBodyList()
	local fps  = love.timer.getFPS()
	local str = "|action| %-10s |mode| %-5s |selection| %-10s |screenX| %-5d |screenY| %-5d "..
				"|worldX| %-5d |worldY| %-5d |Scale| %-5.2f |gravtiyX| %-5.2f |gravityY| %-5.2f "..
				"|bodyCount| %-5d |FPS| %-5d"
	self.text:SetText(string.format(str, action,mode,selection,
		screenX,screenY,worldX,worldY,scale,gx,gy,bodyCount,fps))
end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return info
end