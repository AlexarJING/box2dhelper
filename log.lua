local log={}
local editor
log.lines={}
log.maxLine=100
log.showLine=10
log.currentLine=1
log.x=10
log.visible=true

function log:push(text)
	table.insert(log.lines,1,os.date("%X").."->"..text)
	if #log.lines>log.maxLine then table.remove(log.lines, #log.lines) end
end


function log:clear()
	log.lines={}
end


function log:draw(x,y)
	if not self.visible then return end
	love.graphics.setColor(255, 255, 255, 255)
	for i=log.currentLine,log.currentLine+log.showLine do
		if log.lines[i] then
			local pos=i-log.currentLine
			love.graphics.print(log.lines[i], self.x, self.y-pos*15)
		end
	end
end

return function(parent) 
	editor=parent
	log.x=10
	log.y=h()
	return log
end