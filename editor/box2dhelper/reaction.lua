local helper
local reactMode={}
local func={}
local reactBody={}
reactMode.reactionFunc=func
function reactMode.click(button)
	for i,v in ipairs(reactBody.press) do
		if v.value==button then
			v.func(v.body,v)
		end
	end
end

function reactMode.press(key)
	for i,v in ipairs(reactBody.press) do
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





function func.jet(body)
	local power=5000
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
reactMode.reactType={
	mouseDown={},
	mouseClick={},
	keyDown={jet=func.jet,},
	keyPress={},
	mouseFollow={},
	always={
		anticount=func.anticount
	}
}

return function(parent)
	helper=parent
	parent.reactMode=reactMode
end