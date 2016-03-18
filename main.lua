---box2d lib debugdraw
love.window.setTitle("box2d help lib demo")
io.stdout:setvbuf("no")

local helper=require "b2helper"
-------------world----------------------
local world = love.physics.newWorld(0, 9.8*64, true)
love.physics.setMeter(64)
local body = love.physics.newBody(world, 0, 0, "static")
local shape = love.physics.newChainShape(false, 10,10,10, 590,790,590,790,10)
local fixture = love.physics.newFixture(body, shape)
-----------------------------------------------
for i=1,200 do
	local circle  = love.physics.newBody(world, 300, 300, "dynamic")
	local shape = love.physics.newCircleShape(0, 0, 10)
	local fixture = love.physics.newFixture(circle, shape,100)

end
--------------------------------------------------
local example={}

---------------------wheel---------------------------------

local box  = love.physics.newBody(world, 100, 500, "dynamic")
local shape = love.physics.newRectangleShape(50, 50)
local fixture = love.physics.newFixture(box, shape, 1)

local circle  = love.physics.newBody(world, 100, 550, "dynamic")
local shape = love.physics.newCircleShape(0, 0, 20)
local fixture = love.physics.newFixture(circle, shape)

local joint = love.physics.newWheelJoint(box,circle,100,550,0, 1,false)
local box2  = love.physics.newBody(world, 200, 500, "dynamic")
local shape = love.physics.newRectangleShape(50, 50)
local fixture = love.physics.newFixture(box2, shape, 1)

local circle  = love.physics.newBody(world, 200, 550, "dynamic")
local shape = love.physics.newCircleShape(0, 0, 20)
local fixture = love.physics.newFixture(circle, shape)

local joint = love.physics.newWheelJoint(box2,circle,200,550,0, 1,false)


local joint = love.physics.newWeldJoint(box, box2, 100, 500, false)

---------------------------------distance--------------------------

local box  = love.physics.newBody(world, 200, 100, "static")
local shape = love.physics.newRectangleShape(100, 100)
local fixture = love.physics.newFixture(box, shape, 1)

local circle  = love.physics.newBody(world, 300, 200, "dynamic")
local shape = love.physics.newCircleShape( 0, 0, 50)
local fixture = love.physics.newFixture(circle, shape, 1)

local joint = love.physics.newDistanceJoint(box,circle,200,100,300,200)
joint:setFrequency(1)

---------------------------weld-------------------------------

local box  = love.physics.newBody(world, 300, 100, "dynamic")
local shape = love.physics.newRectangleShape(100, 100)
local fixture = love.physics.newFixture(box, shape, 1)

local circle  = love.physics.newBody(world, 300, 150, "dynamic")
local shape = love.physics.newCircleShape( 0, 0, 50)
local fixture = love.physics.newFixture(circle, shape, 1)
local joint = love.physics.newWeldJoint(box, circle, 300, 100,false)
---------------------------rope-----------------------------
local box  = love.physics.newBody(world, 400, 100, "static")
local shape = love.physics.newRectangleShape(100, 100)
local fixture = love.physics.newFixture(box, shape, 1)

local circle  = love.physics.newBody(world, 400, 200, "dynamic")
local shape = love.physics.newCircleShape( 0, 0, 50)
local fixture = love.physics.newFixture(circle, shape, 1)

local joint = love.physics.newRopeJoint(box,circle,400,100,400,200,200)

--------------------------revolute-----------------------------
local box  = love.physics.newBody(world, 600, 500, "static")
local shape = love.physics.newRectangleShape(50, 50)
local fixture = love.physics.newFixture(box, shape, 1)

local circle  = love.physics.newBody(world, 600, 500, "dynamic")
local shape = love.physics.newCircleShape( 0, 0, 50)
local fixture = love.physics.newFixture(circle, shape, 1)

local joint = love.physics.newRevoluteJoint(box,circle,600,500,false)
joint:setMotorEnabled(true)
joint:setMotorSpeed(10000)
joint:setMaxMotorTorque(10000)


-------------------------prismatic----------------------

local box  = love.physics.newBody(world, 500, 200, "static")
local shape = love.physics.newRectangleShape(50, 50)
local fixture = love.physics.newFixture(box, shape, 1)

local circle  = love.physics.newBody(world, 650, 200, "dynamic")
local shape = love.physics.newCircleShape( 0, 0, 50)
local fixture = love.physics.newFixture(circle, shape, 1)

local joint  = love.physics.newPrismaticJoint(box, circle, 650, 200, 1, 0, false)
joint:setLimits(-50,50)
-----------------------pulley---------------------------

local box  = love.physics.newBody(world, 500, 400, "dynamic")
local shape = love.physics.newRectangleShape(50, 50)
local fixture = love.physics.newFixture(box, shape, 1)

local box2  = love.physics.newBody(world, 650, 400, "dynamic")
local shape = love.physics.newRectangleShape(50, 50)
local fixture = love.physics.newFixture(box2, shape, 1)

local joint = love.physics.newPulleyJoint(box, box2, 500, 300, 650, 300, 500, 400, 650, 400, 1, true)

---------------------mouse-------------------------------
local body = love.physics.newBody(world, 0, 0, "dynamic")
local shape = love.physics.newCircleShape(0, 0, 10)
local fixture = love.physics.newFixture(body, shape, 100)
joint = love.physics.newMouseJoint(body, 0, 0)
--pause=true

function love.update(dt)
	joint:setTarget(love.mouse.getPosition())
	if not pause then world:update(dt) end
end


function love.draw()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print("press 1 to save the world; press 2 to clear the world; press 3 to rebuild the world from saved data",10,10)
	helper.draw(world)
end

function love.keypressed(key)
	if key=="1" then 
		pause=true
		data=helper.save(world)
	elseif key=="2" then
		world:destroy()
		world = love.physics.newWorld(0, 9.8*64, true)
		local body = love.physics.newBody(world, 0, 0, "dynamic")
		local shape = love.physics.newCircleShape(0, 0, 10)
		local fixture = love.physics.newFixture(body, shape, 100)
		joint = love.physics.newMouseJoint(body, 0, 0)
	elseif key=="3" then
		pause=false
		helper.load(world,data)
	end
end