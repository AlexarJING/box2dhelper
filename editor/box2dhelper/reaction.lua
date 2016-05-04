local helper
local reactMode={}
local func={}
local reactBody={}
reactMode.reactionFunc=func
function reactMode.click(button)
	for i,v in ipairs(reactBody.mouseClick) do
		if v.value==button then
			v.func(v.body,v)
		end
	end
end

function reactMode.press(key)
	for i,v in ipairs(reactBody.keyPress) do
		if v.value==key then
			v.func(v.body,v)
		end
	end
end

function reactMode.update()
	for i,v in ipairs(reactBody.always) do
		v.func(v.body,v)
	end

	for i,v in ipairs(reactBody.mouseDown) do
		if love.mouse.isDown(v.value) then
			v.func(v.body,v)
		end
	end

	for i,v in ipairs(reactBody.keyDown) do
		if love.keyboard.isDown(v.value) then
			v.func(v.body,v)
		end
	end
end

function reactMode.reg(world)
	reactBody={
		mouseDown={},
		mouseClick={},
		keyDown={},
		keyPress={},
		mouseFollow={},
		always={}
	}
	for i,body in ipairs(world:getBodyList()) do
		local data=body:getUserData()
		for i,v in ipairs(data) do
			for t,react in pairs(reactMode.reactType) do
				if react[v.prop] then
					table.insert(reactBody[t], {body=body,value=v.value,func=react[v.prop]})
				end
			end
		end
	end
end

function reactMode.addBody(body)
	local data=body:getUserData()
	for i,v in ipairs(data) do
		for t,react in pairs(reactMode.reactType) do
			if react[v.prop] then
				table.insert(reactBody[t], {body=body,value=v.value,func=react[v.prop]})
			end
		end
	end
end

function func.turnToMouse(body)
	local x,y=body:getPosition()
	local tx,ty,tr,ts=love.graphics.getCoordinateInfo()
	local mx,my = -tx+ (love.mouse.getX()-w()/2)/ts,-ty+(love.mouse.getY()-h()/2)/ts
	local angle=body:getAngle()
	local rot=math.getRot(x,y,mx,my)
	body:setAngle(rot-Pi/2)
end

function func.balancer(body)
	
	local gx, gy = helper.world:getGravity()

	local vx,vy=body:getLinearVelocity()
	local mass=body:getMass()

	body:applyLinearImpulse(-vx*mass*1.5,0)
end

function func.roll(body)
	local power=5000
	for i,v in ipairs(body:getUserData()) do
		if v.prop=="power" then power=v.value end
	end
	body:applyTorque(power)
end

function func.jump(body)
	local body2
	for i,contact in ipairs(body:getContactList()) do
		local fixA,fixB=contact:getFixtures()
		local bodyA,bodyB=fixA:getBody(),fixB:getBody()
		if bodyA==body then
			body2=bodyB
		else
			body2=bodyA
		end
	end
	if not body2 then return end
	if body2:getType()~="static" then return end

	local power=5000
	for i,v in ipairs(body:getUserData()) do
		if v.prop=="power" then power=v.value end
	end
	local gx, gy = helper.world:getGravity( )
	local angle=math.getRot(gx,gy,0,0)
	local mass=body:getMass( )
	body:applyLinearImpulse(-power*math.sin(angle)*mass,-power*math.cos(angle)*mass)
end

function func.rollback(body)
	local power=-5000
	for i,v in ipairs(body:getUserData()) do
		if v.prop=="powerBack" then 
			power=-v.value 
		end
	end
	body:applyTorque(power)
end

function func.jet(body)
	local power=50000
	for i,v in ipairs(body:getUserData()) do
		if v.prop=="power" then power=v.value end
	end
	local angle=body:getAngle()-Pi/2
	body:applyForce(power*math.sin(angle),-power*math.cos(angle))

	for i=1,math.abs(power)/5000 do
		
		local body = love.physics.newBody(helper.world, body:getX(), body:getY(),"dynamic")
		body:setGravityScale(0)
		body:setLinearDamping(3)
		local shape = love.physics.newCircleShape(5+love.math.random()*10)
		local fixture = love.physics.newFixture(body, shape)
		fixture:setDensity(1)
		fixture:setFriction(5)
		fixture:setRestitution(0)

		body:applyForce(
			((0.5-love.math.random())*0.5+1)*(-power*math.sin(angle)/3),
			((0.5-love.math.random())*0.5+1)*(power*math.cos(angle)/3))
		body:applyTorque(power*math.sin(angle)/10)
		fixture:setCategory(1)
		fixture:setMask(1)
		body:setUserData({{prop="anticount",value= love.math.random()*3}})
		fixture:setUserData({})
		reactMode.addBody(body)
	end
end

function func.anticount(body,data)
	data.value=data.value-love.timer.getDelta()
	if data.value<0 then
		if not body:isDestroyed() then
			body:destroy()
		end
	end
end



function func.fire(body)
	local fixture=body:getFixtureList()[1]
	fixture:setGroupIndex(-1)
	local power=500
	local bullet
	for i,v in ipairs(body:getUserData()) do
		if v.prop=="power" then power=v.value end
		if v.prop=="bullet" then bullet=v.value end
	end	

	local boom=helper.createWorld(helper.world,bullet,body:getX(),body:getY())[1].body

	local angle=body:getAngle()-Pi/2

	boom:applyLinearImpulse(-power*math.sin(angle),power*math.cos(angle))
	boom:getFixtureList()[1]:setGroupIndex(-1)
end

reactMode.reactType={
	mouseDown={},
	mouseClick={
		fire=func.fire
	},
	keyDown={
		jet=func.jet,
		roll=func.roll,
		rollback=func.rollback
	},
	keyPress={
		jump=func.jump,
	},
	always={
		anticount=func.anticount,
		turnToMouse=func.turnToMouse,
		balancer=func.balancer,
	}
}

return function(parent)
	helper=parent
	parent.reactMode=reactMode
end