local helper
local dataMode={}
dataMode.propBuffer={}

local getDist = function(x1,y1,x2,y2) return math.sqrt((x1-x2)^2+(y1-y2)^2) end
local getRot  = function (x1,y1,x2,y2) 
	if x1==x2 and y1==y2 then return 0 end 
	local angle=math.atan((x1-x2)/(y1-y2))
	if y1-y2<0 then angle=angle-math.pi end
	if angle>0 then angle=angle-2*math.pi end
	if angle==0 then return 0 end
	return -angle
end
local axisRot = function(x,y,rot) return math.cos(rot)*x-math.sin(rot)*y,math.cos(rot)*y+math.sin(rot)*x  end
local polygonTrans= function(x,y,rot,size,v)
	local tab={}
	for i=1,#v/2 do
		tab[2*i-1],tab[2*i]=axisRot(v[2*i-1],v[2*i],rot)
		tab[2*i-1]=tab[2*i-1]*size+x
		tab[2*i]=tab[2*i]*size+y
	end
	return tab
end
local clamp= function (a,low,high)
	if low>high then 
		return math.max(high,math.min(a,low))
	else
		return math.max(low,math.min(a,high))
	end
end

local function getUserData(obj)
	local raw=obj:getUserData()
	if raw==nil then return end
	if type(raw)=="table" then
		return table.save(raw,_,true)
	end
end

local function setUserData(obj,raw)
	if raw==nil then return end
	obj:setUserData(loadstring(raw)())
end

function dataMode.setProperty(obj,key,value)
	if not obj:getUserData() then
		obj:setUserData({})
	end
	if not dataMode.propBuffer[obj] then
		dataMode.propBuffer[obj]={}
	end

	if not key then return end
	if not dataMode.propBuffer[obj][key] then
		local data=obj:getUserData()
		
		for i,v in ipairs(data) do
			if v.prop==key then
				v.value=value
				dataMode.propBuffer[obj][key]=v
				return
			end
		end


		local prop={prop=key,value=value}
		table.insert(data, prop)
		dataMode.propBuffer[obj][key]=prop
	else
		dataMode.propBuffer[obj][key].value=value
	end
end


function dataMode.getProperty(obj,key)
	if not dataMode.propBuffer[obj] then
		dataMode.propBuffer[obj]={}
	end

	if not dataMode.propBuffer[obj][key] then
		local data=obj:getUserData()
		if not data then obj:setUserData({});return end
		for i,v in ipairs(data) do
			if v.prop==key then
				dataMode.propBuffer[obj][key]={prop=key,value=v.value}
				return v.value
			end
		end
		return nil
	end

	return dataMode.propBuffer[obj][key].value
end

function dataMode.removeProperty(obj,key)
	if not dataMode.propBuffer[obj] then
		dataMode.propBuffer[obj]={}
	end

	if dataMode.propBuffer[obj][key] then	
		dataMode.propBuffer[obj][key]=nil
	end

	local data=obj:getUserData()
	for i,v in ipairs(data) do
		if v.prop==key then
			table.remove(data, i)
			return
		end
	end
end


function dataMode.createWorld(world,data,offx,offy,editor)
	offx=offx or 0
	offy=offy or 0
	
	if data.world then
		dataMode.setStatus(world,"world",data.world)
		love.physics.setMeter(data.world.meter)
	end

	local group={}
	for i,v in ipairs(data.obj) do
		local obj={}
		table.insert(group, obj)
		obj.body = love.physics.newBody(world)
		---set prop
		dataMode.setStatus(obj.body,"body",v.body)
		
		local bx,by= obj.body:getPosition() ---set offside
		obj.body:setPosition(bx+offx,by+offy)

		setUserData(obj.body,v.body.userdata)


		for i,v in ipairs(obj.body:getUserData()) do
			if v.prop=="texturePath" then 
				local image = love.graphics.newImage(v.value)
				for i,data in ipairs(obj.body:getUserData()) do
					if data.prop=="texture" then data.value=image end
					break
				end
				break
			end
		end

		obj.fixtures={}
		for i,param in ipairs(v.fixtures) do
			local shell={}
			local Type=param.shape.Type
			if Type== "circle" then
				local cx,cy = unpack(param.shape.Point)
				shell.shape = love.physics.newCircleShape(cx, cy, param.shape.Radius)
			elseif Type== "edge" then
				shell.shape = love.physics.newEdgeShape(unpack(param.shape.Points))
			elseif Type== "chain" then
				shell.shape = love.physics.newChainShape(false, param.shape.Points)
			elseif Type== "polygon" then
				shell.shape = love.physics.newPolygonShape(param.shape.Points)
			end
			
			shell.fixture = love.physics.newFixture(obj.body, shell.shape)

			dataMode.setStatus(shell.fixture,"fixture",param.fixture)

			setUserData(shell.fixture,param.fixture.userdata)
			table.insert(obj.fixtures, shell)
			obj.body:resetMassData()
		end
	end

	local joints={}
	for i,joint in ipairs(data.joint) do
		local j
		local a1,a2=joint.Anchors[1]+offx, joint.Anchors[2]+offy
		local a3,a4=joint.Anchors[3]+offx,joint.Anchors[4]+offy
		if joint.Type=="distance" then
			j = love.physics.newDistanceJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body, 
				a1, a2, a3,a4,
				joint.CollideConnected)
			
		elseif joint.Type=="prismatic" then
			local x1,y1 = group[joint.Bodies[1]].body:getPosition()
			local x2,y2 = group[joint.Bodies[2]].body:getPosition()
			local angle= getRot(x1,y1,x2,y2)
			j = love.physics.newPrismaticJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body,
				a1, a2,
				math.sin(angle), 
				-math.cos(angle),
				joint.CollideConnected)
			
		elseif joint.Type=="pulley" then
			j = love.physics.newPulleyJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body, 
				joint.GroundAnchors[1]+offx, joint.GroundAnchors[2]+offy, 
				joint.GroundAnchors[3]+offx,joint.GroundAnchors[4]+offy,
				a1, a2, a3,a4,
				joint.Ratio,joint.CollideConnected)
		elseif joint.Type=="revolute" then
			j = love.physics.newRevoluteJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body,  
				a1, a2,
				joint.CollideConnected)
			
		elseif joint.Type=="rope" then
			j = love.physics.newRopeJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body,
				a1, a2, a3,a4, 
				joint.MaxLength, joint.CollideConnected)
		elseif joint.Type=="weld" then
			j = love.physics.newWeldJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body, 
				a1, a2, a3,a4,
				joint.CollideConnected)
			
		elseif joint.Type=="wheel" then
			local angle= getRot(
				a1, a2,
			group[joint.Bodies[2]].body:getX(), 
			group[joint.Bodies[2]].body:getY()
			 )
			j = love.physics.newWheelJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body,
				a1, a2,
				math.sin(angle), 
				-math.cos(angle),
				joint.CollideConnected)
		
		elseif joint.Type=="gear" then
			local j1=joints[joint.Joints[1]]
			local j2=joints[joint.Joints[2]]
			j  = love.physics.newGearJoint(j1, j2, joint.Ratio, joint.CollideConnected)
		end

		dataMode.setStatus(j,"joint",joint)
		j:setUserData(joint.userdata)
		table.insert(joints, j)
	end

	if world~=helper.world then
		local beginContact = world:getCallbacks()
		if not beginContact then
			helper.collMode.setCallbacks(world)
		end
		helper.reactMode.reg(world)
	end
	return group
end


local function getBodyIndex(list,body)
	
	for i,tbody in ipairs(list) do
		if tbody==body then
			return i
		end
	end
	
end

local function getJointIndex(list,joint)
	
	for i,tjoint in ipairs(list) do
		if tjoint==joint then
			return i
		end
	end
	
end


function dataMode.getWorldData(world,offx,offy,arg) --存储时
	offx =offx or 0
	offy =offy or 0
	local group={} --contains all the data

	local bodyList --如果不是world 那么就是body list
	if type(world)=="userdata" then
		if world~=helper.world then
			helper.todo={}
			helper.delay={}
			dataMode.propBuffer={}
		end
		helper.world=world
		bodyList=world:getBodyList()
		
		local beginContact= world:getCallbacks()
		if not beginContact then
			helper.collMode.setCallbacks(world)
		end
		helper.reactMode.reg(world)

		local status=dataMode.getStatus(world,"world")
		status.meter=arg.meter
		status.linearDamping=arg.linearDamping
		status.angularDamping=arg.angularDamping
		group.world=status
	else
		bodyList=world
	end
	
	group.obj={}


	for i,body in ipairs(bodyList) do
		local obj={}
		local data={}
		
		table.insert(group.obj, obj)
		local status=dataMode.getStatus(body,"body")
		status.X=status.X-offx
		status.Y=status.Y-offy
		status.userdata=getUserData(body)
		obj.body=status
		obj.fixtures={}
		data.fixtures={}
		for i,fixture in ipairs(body:getFixtureList()) do
			local fixtureData=dataMode.getStatus(fixture,"fixture")
			fixtureData.userdata=getUserData(fixture)
			table.insert(obj.fixtures, {
			shape=dataMode.getStatus(fixture:getShape(),"shape"),
			fixture=fixtureData})
		end
		
	end

	local jointList={}
	group.joint={}
	for i,body in ipairs(bodyList) do	
		for i,joint in ipairs(body:getJointList()) do	
			if joint:getType()~="gear" and joint:getBodies()==body then --the first body==self body
				local status=dataMode.getStatus(joint,"joint")
				status.Bodies={getBodyIndex(bodyList,status.Bodies[1]),
								getBodyIndex(bodyList,status.Bodies[2])}
				table.insert(group.joint, status)
				table.insert(jointList, joint)	
			end
		end
	end
	
	for i,body in ipairs(bodyList) do	
		for i,joint in ipairs(body:getJointList()) do	
			if joint:getType()=="gear" then ---齿轮关节
				local status=dataMode.getStatus(joint,"joint")
				status.Joints={getJointIndex(jointList,status.Joints[1]),
								getJointIndex(jointList,status.Joints[2])}
				table.insert(group.joint, status)
			end
		end
	end
	return group
end


function dataMode.setStatus(obj,objType,data)
	for i,prop in ipairs(dataMode.properties[objType]) do
		local func=obj["set"..prop]
		local value=data[prop]
		if func and value then
			if type(value)=="table" then
				func(obj,unpack(data[prop]))
			else
				func(obj,data[prop])
			end
		end
	end
end

function dataMode.getStatus(obj,type)
	local status={}
	for i,prop in ipairs(dataMode.properties[type]) do
		local func=obj["get"..prop] or obj["is"..prop] or obj["has"..prop]
		if func then
			--local value,value2=func(obj,1)
			local res,value,value2=pcall(func,obj,1)
			if value2 then
				value={func(obj,1)}
			end
			status[prop]=value
		end

	end
	return status
end






dataMode.properties={
		world={
		"Gravity",
		"SleepingAllowed"
	},
		body={
	"X","Y","Angle",
	"AngularDamping",
	"LinearDamping",
	"GravityScale",
	"Type",
	"Bullet",
	"FixedRotation",
	"SleepingAllowed",
	},
		fixture={
	"Restitution",
	"Density",
	"Friction",
	"Category",
	"GroupIndex",
	"Mask",
	"Sensor",
	},
		shape={
	"Point",
	"Points",
	"Type",
	"Radius"
	},
		joint={
	"Bodies",
	"Anchors",
	"Joints",
	"GroundAnchors",
	"LowerLimit",
	"UpperLimit",
	"CollideConnected",
	"Type",
	"UserData",
	"DampingRatio",
	"Frequency",
	"Length",
	"MaxForce",
	"MaxTorque",
	"Joints",
	"Ratio",
	"AngularOffset",
	"LinearOffset",
	"Target",
	"MaxMotorForce",
	"MotorSpeed",
	"Constant",
	"MaxLengths",
	"MaxMotorTorque",
	"MotorSpeed",
	"LimitsEnabled", --has
	"MotorEnabled",
	"MaxLength",
	"SpringDampingRatio",
	"SpringFrequency",
	"AngularOffset",
	"LinearOffset",
	"Ratio"
	}
}

return function(parent) helper=parent;helper.dataMode=dataMode end