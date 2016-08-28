local trace = {}
local rate = 0.1


function trace.new(r)
	trace.current = love.graphics.newCanvas()
	trace.accum = love.graphics.newCanvas()
	rate = r or rate
	return trace
end


function trace.predraw()
	love.graphics.setCanvas(trace.current)
	love.graphics.clear(0,0,0,0)
	love.graphics.setBlendMode("alpha")

	love.graphics.setColor(255, 255, 255, 255*(1-rate))
	love.graphics.draw(trace.accum,x,y)
end


function trace.postdraw()
	

	
	--love.graphics.setShader()
	love.graphics.setCanvas()
	
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(trace.accum)
	love.graphics.setCanvas(trace.accum)
	
	love.graphics.setBlendMode("replace")
	
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(trace.current)
	
	love.graphics.setBlendMode("alpha")
	love.graphics.setCanvas()
end

return trace