local metaball = {}

local code = [[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) {
   	vec4 pixel = Texel(texture, texture_coords);
    return pixel;
  }  
]]
local shader = love.graphics.newShader(code)
function metaball.new()

end

function metaball.predraw()
	--love.graphics.setBlendMode("")
	love.graphics.setShader(shader)
end

function metaball.postdraw()
	love.graphics.setShader()
	love.graphics.setBlendMode("alpha")
end


return metaball