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
	local str = "|操作| %-10s |模式| %-5s |选中| %-10s |屏幕坐标X| %-5d |屏幕坐标Y| %-5d "..
				"|场景坐标X| %-5d |场景坐标Y| %-5d |屏幕缩放| %-5.2f |重力X| %-5.2f |重力Y| %-5.2f "..
				"|刚体计数| %-5d |当前帧率| %-5d"
	self.text:SetText(string.format(str, action,mode,selection,
		screenX,screenY,worldX,worldY,scale,gx,gy,bodyCount,fps))
end

return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return info
end