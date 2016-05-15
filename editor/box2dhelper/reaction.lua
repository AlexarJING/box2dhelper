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

local unitAngle=function(angle) return math.asin(math.sin(angle)) end
local clamp = function (angleFrom,angleTo) 
	local angle=angleTo-angleFrom
	if angle>math.pi then return angle-2*math.pi end
	if angle<-math.pi then return angle+2*math.pi end
	return angle
end


function func.turnToMouse(body,arg)
	local x,y=body:getPosition()
	local tx,ty,tr,ts=love.graphics.getCoordinateInfo()
	local mx,my = -tx+ (love.mouse.getX()-w()/2)/ts,-ty+(love.mouse.getY()-h()/2)/ts
	local angle=body:getAngle()
	local rot=math.getRot(x,y,mx,my)-Pi/2
	body:applyTorque(arg.value*math.sign( clamp(angle,rot)))
	body:setAngularDamping(10)
end

function func.balancer(body)
	local vx,vy=body:getLinearVelocity()
	--if vy<1 then return end
	local angle=body:getAngle()
	local mass = body:getMass()
	body:setAngularDamping(99)
	body:applyAngularImpulse(-angle*59999*mass)
end

function func.roll(body)
	local power=helper.getProperty(body,"rollPower") or 5000
	body:applyTorque(power)
end

function func.rollback(body)
	local power=helper.getProperty(body,"rollBackPower") or -5000
	body:applyTorque(power)
end

function func.jump(body)
	local body2
	for i,contact in ipairs(body:getContactList()) do
		local fixA,fixB=contact:getFixtures()
		local bodyA,bodyB=fixA:getBody(),fixB:getBody()
		if bodyA==body then
			body2=bodyB
		elseif bodyB==body then
			body2=bodyA
		end
	end
	if not body2 then return end
	--if body2:getType()~="static" then return end

	local power=helper.getProperty(body,"jumpPower") or 5000
	local leftkey=helper.getProperty(body,"jumpLeftKey") or "left"
	local rightkey=helper.getProperty(body,"jumpRightKey") or "right"

	local angle=body:getAngle()
	local mass=body:getMass( )
	local mass2=body2:getMass()
	if leftkey and rightkey then
		if love.keyboard.isDown(leftkey) then
			angle=angle-Pi/6
		end
		if love.keyboard.isDown(rightkey) then
			angle=angle+Pi/6
		end
	end
	body:setAngle(angle)
	body:applyLinearImpulse(power*math.sin(angle)*mass,-power*math.cos(angle)*mass)
	body2:applyLinearImpulse(-power*math.sin(angle)*mass2,power*math.cos(angle)*mass2)
end



function func.jet(body)
	local power=helper.getProperty(body,"jetPower") or 5000
	local jetFire=helper.getProperty(body,"jetFire") or true
	local angle=body:getAngle()-Pi/2
	body:applyForce(power*math.sin(angle),-power*math.cos(angle))
	if not jetFire then return end
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
		--fixture:setCategory(1)
		--fixture:setMask(1)
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
	local bfixture=body:getFixtureList()[1]
	--fixture:setGroupIndex(-1)
	local power=helper.getProperty(body,"firePower")
	local bullet=helper.getProperty(body,"fireBullet")  or reactMode.defaultBullet()
	local boom=helper.createWorld(helper.world,bullet,body:getX(),body:getY())[1].body
	local fixture=boom:getFixtureList()[1]
	helper.setProperty(fixture,"bullet",true)
	helper.setProperty(fixture,"lancher",bfixture)
	local angle=body:getAngle()-Pi/2

	boom:applyLinearImpulse(-power*math.sin(angle),power*math.cos(angle))
	--boom:getFixtureList()[1]:setGroupIndex(-1)
end

reactMode.reactType={
	mouseDown={},
	mouseClick={
		fire=func.fire
	},
	keyDown={
		jet=func.jet,
		roll=func.roll,
		rollback=func.rollback,
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


reactMode.defaultBullet=function() 
	local world = love.physics.newWorld(0,0)
	local body = love.physics.newBody(world,0,0,"dynamic")
	local shape = love.physics.newCircleShape(30)
	local fixture = love.physics.newFixture(body, shape)
	body:setUserData({prop="anticount",value=10})
	fixture:setUserData({{prop="explosion",value=1000}})
	return helper.getWorldData({body})
end

reactMode.reactions={
	fire={
		{prop="fire",value=1},
		{prop="firePower",value=500}
	},
	jet={
		{prop="jet",value="w"},
		{prop="jetPower",value=3000},
		{porp="jetFire",value=true}
	},
	roll={
		{prop="roll",value="d"},
		{prop="rollPower",value=5000},
	},
	rollback={
		{prop="roll",value="a"},
		{prop="rollPower",value=-5000},
	},
	jump={
		{prop="jump",value="space"},
		{prop="jumpPower",value=3000},
		{prop="jumpLeftKey",value="q"},
		{prop="jumpRightKey",value="e"}
	},
	turnToMouse={
		{prop="turnToMouse",value=5000},
	},
	balancer={
		{prop="balancer",value=true}
	}
}


return function(parent)
	helper=parent
	parent.reactMode=reactMode
end