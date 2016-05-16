local bg={}
local editor

local gridSize=64
local screenQuad
local gridCanvas
local W
local H


local gridShaderCode=[[
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


local gridShader = love.graphics.newShader(gridShaderCode)


function bg:init()
	self.gridShader=gridShader
	
	self.visible=editor.interface.visible.bg

	return self
end



function bg:update()
	gridShader:send("offx",editor.cam.x*editor.cam.scale)
	gridShader:send("offy",editor.cam.y*editor.cam.scale)
	gridShader:send("screenW",editor.W)
	gridShader:send("screenH",editor.H)
	gridShader:send("gridSize",64*editor.cam.scale)
end


function bg:draw()
	--[[
	if not self.visible then return end
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(self.gridCanvas,self.screenQuad,
		editor.W/2,editor.H/2,0,editor.cam.scale,editor.cam.scale,
		editor.W/editor.cam.scale/2,editor.H/editor.cam.scale/2)

	editor.cam:draw(function()
	love.graphics.setColor(255, 0, 0, 255)
	love.graphics.line(-editor.W/2,0,editor.W/2,0)
	love.graphics.line(0, -editor.H/2, 0,editor.H/2)
	end)]]
	
end
return function(parent) 
	editor=parent
	bg.cam=editor.cam
	return bg
end
