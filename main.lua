if arg[#arg] == "-debug" then require("mobdebug").start() end 
require "libs.util"
local Delaunay=require "libs/delaunay"
local Point    = Delaunay.Point
local points = {}
local imageData = love.image.newImageData( "chicken.png")
local rate=10
function sample( x, y, r, g, b, a )
   if x%rate==0 and y%rate==0 then
   		if a~=0 then table.insert(points,Point(x,y)) end
   end
   return r,g,b,a
end
 
imageData:mapPixel(sample)
local image = love.graphics.newImage(imageData)

local triangles = Delaunay.triangulate(points)

local editor=require "editor/editor"

function love.load()
	editor:init()
end

function love.update(dt)
	editor:update(dt)
end

function love.draw()
	editor:draw()
	local Point    = Delaunay.Point
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(image)
	love.graphics.setColor(255, 255, 0, 255)
	for i, triangle in ipairs(triangles) do
		if triangle:getCircumRadius ()<30 then
			love.graphics.line(triangle.p1.x,triangle.p1.y,triangle.p2.x,triangle.p2.y)
			love.graphics.line(triangle.p2.x,triangle.p2.y,triangle.p3.x,triangle.p3.y)
			love.graphics.line(triangle.p1.x,triangle.p1.y,triangle.p3.x,triangle.p3.y)
		end
	end
end

function love.mousepressed(x, y, button)
	editor:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	editor:mousereleased(x, y, button)
end

function love.keypressed(key, scancode, isrepeat )
	editor:keypressed(key, isrepeat)
end

function love.keyreleased(key)
	editor:keyreleased(key)
end

function love.textinput(text)
	editor:textinput(text)
end

function love.wheelmoved(x, y)
    editor:wheelmoved(x, y)
end