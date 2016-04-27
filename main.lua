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

for i=#triangles,1,-1 do
	if triangles[i]:getCircumRadius ()>10 then
		table.remove(triangles, i)
	end
end


local edges={}
for i,t in ipairs(triangles) do
	table.insert(edges,t.e1)
	table.insert(edges,t.e2)
	table.insert(edges,t.e3)
end

for i,t in ipairs(triangles) do
	
	for j,e in ipairs(edges) do
		if t.e1:same(e) and e~=t.e1 then
			table.remove(edges, j)	
			break
		end
	end
	
	for j,e in ipairs(edges) do
		if t.e2:same(e) and e~=t.e2 then
			table.remove(edges, j)
			break
		end
	end

	for j,e in ipairs(edges) do
		if t.e3:same(e) and e~=t.e3 then
			table.remove(edges, j)	
			break
		end
	end
end

local target={edges[1].p1.x,edges[1].p1.y,edges[1].p2.x,edges[1].p2.y}
table.remove(edges, 1)
while #edges~=0 do
	local test
	for i,e in ipairs(edges) do
		if e.p1.x==target[#target-1] and e.p1.y==target[#target] then
			table.insert(target, e.p2.x)
			table.insert(target, e.p2.y)
			table.remove(edges, i)
			print(#edges)
			test=true
			break
		end

		if e.p2.x==target[#target-1] and e.p2.y==target[#target] then
			table.insert(target, e.p1.x)
			table.insert(target, e.p1.y)
			table.remove(edges, i)
			print(#edges)
			test=true
			break
		end
	end
	if not test then break end
end


local editor=require "editor/editor"

function love.load()
	editor:init()
end

function love.update(dt)
	editor:update(dt)
end

function love.draw()
	editor:draw()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(image)
	love.graphics.setColor(255, 255, 0, 255)
	love.graphics.setLineWidth(1)
	for i, triangle in ipairs(triangles) do
		--if triangle:getCircumRadius ()<30 then
			love.graphics.line(triangle.p1.x,triangle.p1.y,triangle.p2.x,triangle.p2.y)
			love.graphics.line(triangle.p2.x,triangle.p2.y,triangle.p3.x,triangle.p3.y)
			love.graphics.line(triangle.p1.x,triangle.p1.y,triangle.p3.x,triangle.p3.y)
		--end
	end
	love.graphics.setColor(0, 255, 255, 255)
	love.graphics.setLineWidth(5)
	
	for i,e in ipairs(edges) do
		--love.graphics.line(e.p1.x,e.p1.y,e.p2.x,e.p2.y)
	end
	love.graphics.line(target)
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