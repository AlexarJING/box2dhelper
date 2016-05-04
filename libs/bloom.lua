-- source: https://love2d.org/forums/viewtopic.php?f=4&t=3733#p38666
-- Modified to work with löve 0.9.1
local math, love = math, love

local function FindSmallestPO2(num)
   return 2 ^ math.ceil(math.log(num)/math.log(2))
end

local function ScaleToPO2(xsize, ysize)
   return FindSmallestPO2(xsize), FindSmallestPO2(ysize)
end

-- i've found xsize and ysize of 1/2 - 1/4 the screen resolution to be nice
-- smaller values make the bloom more apparent and give much better performance, but can make it look bad if too small
return
	function(xsize, ysize) 
	  
	   local function newShader(code)
	      local success, result = pcall(love.graphics.newShader, code)
	      if success then
	         return result
	      else
	         print("Error compiling shader!\n"..result)
	      end
	   end
	   
	   local bloom = {}
	   
	   local shaders = {}
	   local shaders_src = {
	      blur_vert = [[
	         extern number canvas_h = 256.0;
	         
	         const number offset_1 = 1.3846153846;
	         const number offset_2 = 3.2307692308;
	         
	         const number weight_0 = 0.2270270270;
	         const number weight_1 = 0.3162162162;
	         const number weight_2 = 0.0702702703;
	         
	         vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
	         {
	            vec4 texcolor = Texel(texture, texture_coords);
	            vec3 tc = texcolor.rgb * weight_0;
	            
	            tc += Texel(texture, texture_coords + vec2(0.0, offset_1)/canvas_h).rgb * weight_1;
	            tc += Texel(texture, texture_coords - vec2(0.0, offset_1)/canvas_h).rgb * weight_1;
	            
	            tc += Texel(texture, texture_coords + vec2(0.0, offset_2)/canvas_h).rgb * weight_2;
	            tc += Texel(texture, texture_coords - vec2(0.0, offset_2)/canvas_h).rgb * weight_2;
	            
	            return color * vec4(tc, 1.0);
	         }
	      ]],
	      blur_horiz = [[
	         extern number canvas_w = 256.0;

	         const number offset_1 = 1.3846153846;
	         const number offset_2 = 3.2307692308;
	         
	         const number weight_0 = 0.2270270270;
	         const number weight_1 = 0.3162162162;
	         const number weight_2 = 0.0702702703;

	         vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
	         {
	            vec4 texcolor = Texel(texture, texture_coords);
	            vec3 tc = texcolor.rgb * weight_0;
	            
	            tc += Texel(texture, texture_coords + vec2(offset_1, 0.0)/canvas_w).rgb * weight_1;
	            tc += Texel(texture, texture_coords - vec2(offset_1, 0.0)/canvas_w).rgb * weight_1;
	            
	            tc += Texel(texture, texture_coords + vec2(offset_2, 0.0)/canvas_w).rgb * weight_2;
	            tc += Texel(texture, texture_coords - vec2(offset_2, 0.0)/canvas_w).rgb * weight_2;
	            
	            return color * vec4(tc, 1.0);
	         }
	      ]],
	      bloom = [[
	         extern number threshold = 1.0;
	         
	         float luminance(vec3 color)
	         {
	            // numbers make 'true grey' on most monitors, apparently
	            return (0.212671 * color.r) + (0.715160 * color.g) + (0.072169 * color.b);
	         }
	         
	         vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
	         {
	            vec4 texcolor = Texel(texture, texture_coords);
	            
	            vec3 extract = smoothstep(threshold * 0.7, threshold, luminance(texcolor.rgb)) * texcolor.rgb;
	            return vec4(extract, 1.0);
	         }
	      ]],
	      
	      combine = [[
	         extern Image bloomtex;
	         
	         extern number basesaturation = 1.0;
	         extern number bloomsaturation = 1.0;
	         
	         extern number baseintensity = 1.0;
	         extern number bloomintensity = 1.0;
	         
	         vec3 AdjustSaturation(vec3 color, number saturation)
	         {
	             vec3 grey = vec3(dot(color, vec3(0.212671, 0.715160, 0.072169)));
	             return mix(grey, color, saturation);
	         }
	      
	         vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
	         {
	            vec4 basecolor = Texel(texture, texture_coords);
	            vec4 bloomcolor = Texel(bloomtex, texture_coords);
	            
	            bloomcolor.rgb = AdjustSaturation(bloomcolor.rgb, bloomsaturation) * bloomintensity;
	            basecolor.rgb = AdjustSaturation(basecolor.rgb, basesaturation) * baseintensity;
	            
	            basecolor.rgb *= (1.0 - clamp(bloomcolor.rgb, 0.0, 1.0));
	            
	            bloomcolor.a = 0.0;
	            
	            return clamp(basecolor + bloomcolor, 0.0, 1.0);
	         }
	      ]]
	   }
	   
	   for k,v in pairs(shaders_src) do
	      local shader = newShader(v)
	      if shader then
	         shaders[k] = shader
	      else
	          print("poop")
	         return
	      end
	   end
	   
	   if not shaders.blur_vert or not shaders.blur_horiz or not shaders.bloom or not shaders.combine then
	       print( "didn't get all the shaders" )
	      return
	   end

	   
	   local intensity_base, intensity_bloom = 1, 1
	   local saturation_base, saturation_bloom = 1, 1
	   local threshold_bloom = 0.5
	   
	   local debugdraw = false
	   
	   function bloom:refresh(xs, ys)
	      xs, ys = math.floor(xs+0.5), math.floor(ys+0.5)
	      
	      local renderingtoscene = false

	      self.xsize, self.ysize = xs, ys
	      
	      self.po2xsize, self.po2ysize = ScaleToPO2(self.xsize, self.ysize) -- scales x and y to next power of 2 if npot is false
	      
	      self.xres, self.yres = love.graphics.getWidth(), love.graphics.getHeight()
	      self.po2xres, self.po2yres = ScaleToPO2(self.xres, self.yres)

	   
	      self.quad = love.graphics.newQuad(0, 0, self.xsize, self.ysize, self.po2xsize, self.po2ysize)
	      self.scenequad = love.graphics.newQuad(0, 0, self.xres, self.yres, self.po2xres, self.po2yres)
	   
	      self.canvas = {
	         bloom = love.graphics.newCanvas(self.po2xsize, self.po2ysize),
	         blur_horiz = love.graphics.newCanvas(self.po2xsize, self.po2ysize),
	         blur_vert = love.graphics.newCanvas(self.po2xsize, self.po2ysize),
	         scene = love.graphics.newCanvas(self.po2xres, self.po2yres),
	         bloomscene = love.graphics.newCanvas(self.po2xres, self.po2yres),
	      }
	            
	      for k,v in pairs(self.canvas) do
	         love.graphics.setCanvas(v)
	         love.graphics.clear()
	         love.graphics.setCanvas()
	      end
	      
	      shaders.blur_horiz:send("canvas_w", self.po2xsize)
	      shaders.blur_vert:send("canvas_h", self.po2ysize)
	      self:setThreshold(self:getThreshold())
	      self:setIntensity(self:getIntensity())
	      self:setSaturation(self:getSaturation())
	      
	      if renderingtoscene then
	         love.graphics.setCanvas(self.canvas.scene)
	      end
	      
	      collectgarbage("collect")
	   end
	   
	   function bloom:debugDraw(shoulddebugdraw)
	      debugdraw = not not shoulddebugdraw
	   end
	   
	   function bloom:setIntensity(ibase, ibloom)
	      intensity_base = ibase
	      intensity_bloom = ibloom
	      
	      shaders.combine:send("baseintensity", ibase)
	      shaders.combine:send("bloomintensity", ibloom)
	   end
	   function bloom:getIntensity()
	      return intensity_base, intensity_bloom
	   end
	   
	   function bloom:setSaturation(sbase, sbloom)
	      saturation_base = sbase
	      saturation_bloom = sbloom
	      
	      shaders.combine:send("basesaturation", sbase)
	      shaders.combine:send("bloomsaturation", sbloom)
	   end
	   function bloom:getSaturation()
	      return saturation_base, saturation_bloom
	   end
	   
	   function bloom:setThreshold(threshold)
	      threshold_bloom = threshold
	      
	      shaders.bloom:send("threshold", threshold)
	   end
	   function bloom:getThreshold()
	      return threshold_bloom
	   end
	   
	   
	   -- call right before drawing the stuff you want bloomed
	   function bloom:predraw()
	      for k,v in pairs(self.canvas) do
	         love.graphics.setCanvas(v)
	         love.graphics.clear()
	         love.graphics.setCanvas()
	      end
	      love.graphics.setCanvas(self.canvas.scene)
	      
	      self.drawing = true
	   end
	   
	   function bloom:enabledrawtobloom()
	      love.graphics.setCanvas(self.canvas.bloomscene)
	   end
	   
	   -- call after drawing the stuff you want bloomed
	   function bloom:postdraw()         
	      love.graphics.setColor(255, 255, 255)
	      local blendmode = love.graphics.getBlendMode()
	      love.graphics.setBlendMode("alpha","premultiplied")
	      
	      love.graphics.push()
	      love.graphics.scale(self.po2xsize/self.po2xres, self.po2ysize/self.po2yres)
	      
	      -- apply bloom extract shader
	      love.graphics.setCanvas(self.canvas.bloom)
	      love.graphics.setShader(shaders.bloom)
	      love.graphics.draw(self.canvas.bloomscene, self.scenequad, 0, 0)
	      
	      love.graphics.pop()
	               
	      -- apply horizontal blur shader to extracted bloom
	      love.graphics.setCanvas(self.canvas.blur_horiz)
	      love.graphics.setShader(shaders.blur_horiz)
	      love.graphics.draw(self.canvas.bloom, self.quad, 0, 0)
	      
	      -- apply vertical blur shader to blurred bloom
	      love.graphics.setCanvas(self.canvas.blur_vert)
	      love.graphics.setShader(shaders.blur_vert)
	      love.graphics.draw(self.canvas.blur_horiz, self.quad, 0, 0)
	      
	      -- render final scene combined with bloom canvas
	      love.graphics.setCanvas()
	      shaders.combine:send("bloomtex", self.canvas.blur_vert)
	      love.graphics.setShader(shaders.combine)
	      love.graphics.draw(self.canvas.scene, self.scenequad, 0, 0)
	      
	      love.graphics.setShader()
	      
	      if debugdraw then
	         -- love.graphics.setColor(255, 255, 255, 128)
	         love.graphics.draw(self.canvas.bloom, 0, 0)
	         love.graphics.draw(self.canvas.blur_horiz, self.po2xsize+4, 0)
	         love.graphics.draw(self.canvas.blur_vert, self.po2xsize*2+8, 0)
	         -- love.graphics.draw(self.canvas.blur_vert, 0, 0, 0, self.po2xres/self.po2xsize, self.po2yres/self.po2ysize)
	      end
	      
	      love.graphics.setBlendMode(blendmode)
	      
	      self.drawing = false
	   end
	   
	   function bloom:isDrawing()
	      return not not self.drawing
	   end
	   
	   bloom:refresh(xsize, ysize)
	   
	   bloom:setIntensity(1, 1)
	   bloom:setSaturation(1, 1)
	   bloom:setThreshold(0.35)
	   
	   return bloom
	end