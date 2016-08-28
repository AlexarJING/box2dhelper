local grid = {}

local gridSize=64
local screenQuad
local gridCanvas


local code=[[
	extern number offx;
	extern number offy;
	extern number gridSize;
	extern number screenW;
	extern number screenH;
	vec4 effect( vec4 color, Image texture, vec2 tc, vec2 sc ){
		if (abs(mod(floor(sc.x-screenW/2)+offx,gridSize))<=1 || 
			abs(mod(floor(sc.y-screenH/2)+offy,gridSize))<=1 ){
			vec4 c=Texel(texture,tc);
			if (c.a==0.0) {
				return vec4(0,0,1,0.5);
			}
			else{
				return color*c;
			}	
		}
		else {
			return color*Texel(texture,tc);
		}
	}

]]


local shader = love.graphics.newShader(code)
local editor

function grid.new(e)
	grid.canvas = love.graphics.newCanvas()
	editor = e
	return grid
end


function grid.predraw()
	shader:send("offx",editor.cam.x*editor.cam.scale)
	shader:send("offy",editor.cam.y*editor.cam.scale)
	shader:send("screenW",editor.W)
	shader:send("screenH",editor.H)
	shader:send("gridSize",64*editor.cam.scale)
	love.graphics.setCanvas(grid.canvas)
	love.graphics.clear()
	love.graphics.setShader(shader)
end


function grid.postdraw()

	
	love.graphics.setShader()
	love.graphics.setCanvas()
	
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(grid.canvas)

end

return grid