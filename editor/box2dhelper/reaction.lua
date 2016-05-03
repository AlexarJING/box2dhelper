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

function func.turnToMouse(body)
	local x,y=body:getPosition()
	local tx,ty,tr,ts=love.graphics.getCoordinateInfo()
	local mx,my = -tx+ (love.mouse.getX()-w()/2)/ts,-ty+(love.mouse.getY()-h()/2)/ts
	local angle=body:getAngle()
	local rot=math.getRot(x,y,mx,my)
	body:setAngle(rot-Pi/2)
end


function func.roll(body)
	local power=50000
	for i,v in ipairs(body:getUserData()) do
		if v.prop=="power" then power=v.value end
	end
	body:applyTorque(power)
end

function func.jet(body)
	local power=50000
	for i,v in ipairs(body:getUserData()) do
		if v.prop=="power" then power=v.value end
	end
	local angle=body:getAngle()
	body:applyForce(power*math.sin(angle),-power*math.cos(angle))
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
	local power=100
	local bullet
	for i,v in ipairs(body:getUserData()) do
		if v.prop=="power" then power=v.value end
		if v.prop=="bullet" then bullet=v.value end
	end	

	local boom=helper.createWorld(helper.world,bullet,body:getX(),body:getY())[1].body

	local angle=body:getAngle()-Pi/2
	print(angle)
	boom:applyLinearImpulse(-power*math.sin(angle),power*math.cos(angle))
	boom:getFixtureList()[1]:setGroupIndex(-1)
end

reactMode.reactType={
	mouseDown={},
	mouseClick={
		fire=func.fire
	},
	keyDown={jet=func.jet,roll=func.roll},
	keyPress={
	},
	always={
		anticount=func.anticount,
		turnToMouse=func.turnToMouse
	}
}

return function(parent)
	helper=parent
	parent.reactMode=reactMode
end