local helper={}
local gearAngle={}
local preserve={}
helper.todo={}
helper.delay={}
helper.world=nil

local function addDelay(func,delay,...)
	table.insert(helper.delay, {func,os.time()+delay,...})
end

local function updateDelay()
	for i=#helper.delay,1,-1 do
		local tab=helper.delay[i]
		local func=tab[1]
		local expect=tab[2]
		if os.time()>=expect then
			table.remove(tab, 1)
			table.remove(tab, 1)
			func(unpack(tab))
			table.remove(helper.delay, i)
		end
	end
end

local function updateTodo()
	for i,v in ipairs(helper.todo) do
		local func=v[1]
		table.remove(v,1)
		func(unpack(v))
	end
	helper.todo={}
end
local function addPreserve(obj)
	if not preserve[obj] then  preserve[obj]=obj end --reg data
end
local function updatePreserve()
	for k,v in pairs(preserve) do
		if v:isDestroyed() then
			preserve[k]=nil --kill data
		end
	end
end

local function CreateGear(segments)
	segments = segments or 40
	local vertices = {}
	table.insert(vertices, {0, 0})
	for i=0, segments do
		local angle = (i / segments) * math.pi * 2
		local x = math.cos(angle)+(i%2)*math.cos(angle)*0.7
		local y = math.sin(angle)+(i%2)*math.sin(angle)*0.7
		table.insert(vertices, {x, y})
	end
	return love.graphics.newMesh(vertices, "fan")
end


local gearShape = CreateGear(20)

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

local defaultStyle= {
		dynamic={100, 200, 255, 255},
		static={100, 100, 100, 255},
		kinematic={100, 255, 200, 255},
		sensor={0,0,-255,0},
		joint={255, 100, 100, 150},
		body={255, 0, 255, 50},
		contact={0,255,255,255}
	}

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

function helper.drawBody(body,colorStyle)
	local color
	local bodyX=body:getX()
	local bodyY=body:getY()
	love.graphics.setColor(colorStyle.body)
	love.graphics.circle("fill", bodyX, bodyY, 4)
	local bodyType= body:getType()	
	-------------------------------------for shapes-----------------------
	for i,fixture in ipairs(body:getFixtureList()) do
		local color
		if  bodyType=="dynamic" then
			color=colorStyle.dynamic
		elseif bodyType=="static" then
			color=colorStyle.static
		elseif bodyType=="kinematic" then
			color=colorStyle.kinematic
		end
		local color={unpack(color)}
		if  fixture:isSensor() then		
			for i=1,4 do
				color[i]=color[i]-colorStyle.sensor[i]
			end
		end
	
		helper.drawFixture(fixture,color)
	end
end

function helper.drawFixture(fixture,color)
	local body = fixture:getBody()
	local bodyX=body:getX()
	local bodyY=body:getY()
	local bodyAngle=body:getAngle()
	local shape=fixture:getShape()
	local shapeType = shape:type()
	local shapeR=shape:getRadius()
	
	if shapeType=="CircleShape" then
		color[4]=255
		local fx,fy=shape:getPoint()
		local offx,offy= axisRot(fx,fy,bodyAngle)
		love.graphics.setColor(color)
		love.graphics.circle("line", bodyX+offx, bodyY+offy, shapeR)
		love.graphics.line(bodyX+offx,bodyY+offy,
			bodyX+math.cos(bodyAngle)*shapeR+offx,bodyY+math.sin(bodyAngle)*shapeR+offy)
		color[4]=50
		love.graphics.setColor(color)
		love.graphics.circle("fill", bodyX+offx, bodyY+offy, shapeR)
	elseif shapeType=="ChainShape" or shapeType=="EdgeShape" then
		color[4]=255
		love.graphics.setColor(color)
		love.graphics.line(body:getWorldPoints(shape:getPoints()))
	else
		color[4]=255
		love.graphics.setColor(color)
		love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
		color[4]=50
		love.graphics.setColor(color)
		love.graphics.polygon("fill", body:getWorldPoints(shape:getPoints()))
	end

end


function helper.drawJoint(joint,color)
	love.graphics.setColor(color)
	local jointType=joint:getType()
	if jointType=="distance" then
		local aX,aY,bX,bY=joint:getAnchors()
		local normDist = joint:getLength()
		local dir=1
		local verts={0,0}
		local vertsCount=math.floor(normDist/10)
		local realDist = getDist(aX,aY,bX,bY)
		local abDirection = getRot (bX,bY,aX,aY)
		for i=1,vertsCount do
			dir=-dir
			table.insert(verts, 10*dir)
			table.insert(verts, i*10*realDist/normDist)
		end
		table.insert(verts, 0)
		table.insert(verts, realDist)
		verts=polygonTrans(aX,aY,abDirection,1,verts)
		love.graphics.line(verts)
		love.graphics.line(aX,aY,bX,bY)
		love.graphics.circle("line", aX, aY, 3)
		love.graphics.circle("line", bX, bY, 3)	
	elseif jointType=="weld" then
		local bodyA,bodyB = joint:getBodies()
		local aX,aY = bodyA:getPosition()
		local bX,bY = bodyB:getPosition()
		local abDirection = getRot (bX,bY,aX,aY)
		local dist = getDist(aX,aY,bX,bY)
		local verts={-5,-5,5,-5,5,dist+5,-5,dist+5}
		verts=polygonTrans(aX,aY,abDirection,1,verts)
		love.graphics.polygon("line", verts)
	elseif jointType=="prismatic" then
		local bodyA,bodyB = joint:getBodies()
		local aX,aY= bodyA:getPosition()
		local bX,bY = bodyB:getPosition()
		local jX,jY = joint:getAnchors()
		local abDirection = getRot (bX,bY,aX,aY)
		local lower, upper = joint:getLimits( )
		lower= lower<-100 and 100 or lower
		upper= upper>100 and 100 or upper
		if lower~=-100 then
			love.graphics.line(polygonTrans(jX,jY,abDirection,1,{-10,lower-10,10,lower-10}))
		end

		if upper~=100 then
			love.graphics.line(polygonTrans(jX,jY,abDirection,1,{-10,upper+10,10,upper+10}))
		end
		love.graphics.circle("line", bX,bY,8)
		love.graphics.line(polygonTrans(jX,jY,abDirection,1,{-10,lower-10,-10,upper+10}))
		love.graphics.line(polygonTrans(jX,jY,abDirection,1,{10,lower-10,10,upper+10}))
		love.graphics.line(aX,aY,bX,bY)
		love.graphics.line(jX, jY, aX, aY)
		love.graphics.line(jX, jY, bX, bY)
	elseif jointType=="revolute" then
		local jX,jY=joint:getAnchors()
		local jAngle=joint:getJointAngle( )
		love.graphics.circle("line", jX, jY, 10)
		love.graphics.line(jX-math.cos(jAngle)*10,jY-math.sin(jAngle)*10,
			jX+math.cos(jAngle)*10,jY+math.sin(jAngle)*10)

		local bodyA,bodyB = joint:getBodies()
		local aX,aY = bodyA:getPosition()
		local bX,bY = bodyB:getPosition()
		love.graphics.line(aX,aY,jX,jY)
		love.graphics.line(bX,bY,jX,jY)
	
	elseif jointType=="rope" then
		local aX,aY,bX,bY=joint:getAnchors()
		local normDist = joint:getMaxLength()
		local dir=1
		local verts={0,0}
		local vertsCount=math.floor(normDist/10)
		local realDist = getDist(aX,aY,bX,bY)
		local abDirection = getRot (bX,bY,aX,aY)
		local width=5*(normDist-realDist)*dir/realDist
		width = width>5 and 5 or width
		for i=1,vertsCount do
			dir=-dir
			table.insert(verts, width*dir)
			table.insert(verts, i*10*realDist/normDist)
		end
		table.insert(verts, 0)
		table.insert(verts, realDist)
		verts=polygonTrans(aX,aY,abDirection,1,verts)
		love.graphics.line(verts)
		love.graphics.line(aX,aY,bX,bY)
		love.graphics.circle("line", aX, aY, 3)
		love.graphics.circle("line", bX, bY, 3)		
	elseif jointType=="pulley" then
		local aX,aY,bX,bY=joint:getAnchors()
		local aGX,aGY,bGX,bGY = joint:getGroundAnchors()
		love.graphics.circle("line", aX, aY, 3)
		love.graphics.circle("line", bX, bY, 3)
		love.graphics.circle("line", aGX, aGY, 3)
		love.graphics.circle("line", bGX, bGY, 3)
		love.graphics.line(aX, aY, aGX,aGY,bGX,bGY,bX,bY)
	elseif jointType=="wheel" then
		local jX,jY=joint:getAnchors()
		local bodyA,bodyB = joint:getBodies()
		local aX,aY = bodyA:getPosition()
		local bX,bY = bodyB:getPosition()
		local realDist = getDist(bX,bY,aX,aY)
		local abDirection = getRot (jX,jY,aX,aY)
		local normDist = realDist+math.abs(joint:getJointTranslation( ))
		local dir=1
		local verts={0,0}
		local vertsCount=math.floor(normDist/10)
		
		for i=1,vertsCount do
			dir=-dir
			table.insert(verts, 10*dir)
			table.insert(verts, i*10*realDist/normDist)
		end
		table.insert(verts, 0)
		table.insert(verts, realDist)
		verts=polygonTrans(aX,aY,abDirection,1,verts)
		love.graphics.line(verts)
		love.graphics.circle("line", bX, bY, 8)
		love.graphics.line(polygonTrans(aX,aY,abDirection,1,{-10,0,-10,realDist}))
		love.graphics.line(polygonTrans(aX,aY,abDirection,1,{10,0 ,10,realDist}))
		love.graphics.line(polygonTrans(aX,aY,abDirection,1,{10,0 ,-10,0}))
	elseif jointType=="gear" then
		local j1,j2=joint:getJoints()
		local x1,y1=j1:getAnchors()
		local x2,y2=j2:getAnchors()
		local reactF=joint:getReactionForce(1)
		local reactT=joint:getReactionTorque(1)
		if not gearAngle[joint] then gearAngle[joint]=0 end
		gearAngle[joint]=gearAngle[joint]+reactF/100+reactT/100
		love.graphics.line(x1, y1, ((x1+x2)/2)-5,((y1+y2)/2)-5)
		love.graphics.line(x2, y2, ((x1+x2)/2)+5,((y1+y2)/2)+5)
		love.graphics.draw(gearShape, ((x1+x2)/2)-5,((y1+y2)/2)-5,gearAngle[joint],5,5)
		love.graphics.draw(gearShape, ((x1+x2)/2)+5,((y1+y2)/2)+5,-gearAngle[joint],5,5)
	end
end

function helper.drawContact(contact,color)
	love.graphics.setColor(color)
	local x1, y1, x2, y2 = contact:getPositions( )
	if x1 then love.graphics.circle("fill", x1, y1, 3) end
	if x2 then love.graphics.circle("fill", x2, y2, 3) end
end

function helper.draw(world,colorStyle,offx,offy)
	if world==helper.world then
		updateTodo()
		updateDelay()
	end
	if offx then
		love.graphics.translate(offx, offy)
	end
	updatePreserve()
	colorStyle=colorStyle or defaultStyle
	local bodyList
	local jointList
	local contactList
	if type(world)=="userdata" then
		bodyList=world:getBodyList()
		jointList=world:getJointList()
		contactList=world:getContactList()
	else
		bodyList=world
	end

	love.graphics.setLineJoin( "none")
	for i,body in ipairs(bodyList) do
		addPreserve(body)
		helper.drawBody(body,colorStyle)
		
		if not jointList then
			jointList={}
			for i,joint in ipairs(body:getJointList()) do
				addPreserve(joint)
				if not table.getIndex(jointList,joint) then
					table.insert(jointList, joint)
				end
			end
		end

		if not contactList then
			contactList={}
			for i,contact in ipairs(body:getContactList()) do
				addPreserve(contact)
				if not table.getIndex(contactList,contact) then
					table.insert(contactList, contact)
				end
			end
		end
	end

	if jointList then
		for i,joint in ipairs(jointList) do
			addPreserve(joint)
			helper.drawJoint(joint,colorStyle.joint)
		end
	end

	if contactList then
		for i,contact in ipairs(contactList) do
			addPreserve(contact)
			helper.drawContact(contact,colorStyle.contact)
		end
	end	

	if offx then
		love.graphics.translate(-offx, -offy)
	end
end


function helper.save(world,asTable)
	local group=helper.getWorldData(world)
	if asTable then
		return group
	else
		return table.save(group)
	end
	
end



function helper.load(world,data,asTable)
	if not asTable then data= loadstring(data)() end
	return helper.createWorld(world,data)
end

helper.collisionFunc=require "editor.collisionFunc"(helper)

helper.collisionType={
	begin={
		makeFrag=helper.collisionFunc.spark,
		reverse=helper.collisionFunc.reverse,
		explosion=helper.collisionFunc.explosion,
		},
	over={
		oneWay=helper.collisionFunc.oneWayEnd,
	},
	pre={
		oneWay=helper.collisionFunc.oneWayPre,
	},
	post={
		crashable=helper.collisionFunc.crash,
		embed=helper.collisionFunc.embed
	}	
}


local function findReaction(callbackType,a,b,...)
	local data=a:getUserData()
	if data then
		for i,v in ipairs(data) do
			if helper.collisionType[callbackType][v.prop]  then
				helper.collisionType[callbackType][v.prop](v.value,a,b,...)
			end
		end
	end
	local data=b:getUserData()
	if data then
		for i,v in ipairs(data) do
			if helper.collisionType[callbackType][v.prop]  then
				helper.collisionType[callbackType][v.prop](v.value,b,a,...)
			end
		end
	end
end


local function beginC(...)
	findReaction("begin",...)
end

local function endC(...)
	findReaction("over",...)
end

local function preC(...)
	findReaction("pre",...)
end

local function postC(...)
	findReaction("post",...)
end

local function setCallbacks(world)
	world:setCallbacks(beginC,endC,preC,postC)
end


function helper.createWorld(world,data,offx,offy)
	offx=offx or 0
	offy=offy or 0
	
	local group={}
	for i,v in ipairs(data.obj) do
		local obj={}
		table.insert(group, obj)
		obj.body = love.physics.newBody(world)
		---set prop
		helper.setStatus(obj.body,"body",v.body)
		
		local bx,by= obj.body:getPosition() ---set offside
		obj.body:setPosition(bx+offx,by+offy)

		setUserData(obj.body,v.body.userdata)

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

			helper.setStatus(shell.fixture,"fixture",param.fixture)

			setUserData(shell.fixture,param.fixture.userdata)
			table.insert(obj.fixtures, shell)
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

		helper.setStatus(j,"joint",joint)
		j:setUserData(joint.userdata)
		table.insert(joints, j)
	end

	if world~=helper.world then
		setCallbacks(world)
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









function helper.getWorldData(world,offx,offy)
	offx =offx or 0
	offy =offy or 0
	local bodyList --如果不是world 那么就是body list
	if type(world)=="userdata" then
		if world~=helper.world then
			helper.todo={}
			helper.delay={}
		end
		helper.world=world
		bodyList=world:getBodyList()
		local beginContact, endContact, preSolve, postSolve = world:getCallbacks()
		if not beginContact then
			setCallbacks(world)
		end
	else
		bodyList=world
	end
	local group={}
	group.obj={}


	for i,body in ipairs(bodyList) do
		local obj={}
		local data={}
		
		table.insert(group.obj, obj)
		local status=helper.getStatus(body,"body")
		status.X=status.X-offx
		status.Y=status.Y-offy
		status.userdata=getUserData(body)
		obj.body=status
		obj.fixtures={}
		data.fixtures={}
		for i,fixture in ipairs(body:getFixtureList()) do
			local fixtureData=helper.getStatus(fixture,"fixture")
			fixtureData.userdata=getUserData(fixture)
			table.insert(obj.fixtures, {
			shape=helper.getStatus(fixture:getShape(),"shape"),
			fixture=fixtureData})
		end
		
	end

	local jointList={}
	group.joint={}
	for i,body in ipairs(bodyList) do	
		for i,joint in ipairs(body:getJointList()) do	
			if joint:getType()~="gear" and joint:getBodies()==body then --the first body==self body
				local status=helper.getStatus(joint,"joint")
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
				local status=helper.getStatus(joint,"joint")
				status.Joints={getJointIndex(jointList,status.Joints[1]),
								getJointIndex(jointList,status.Joints[2])}
				table.insert(group.joint, status)
			end
		end
	end

	return group
end


function helper.setStatus(obj,objType,data)
	for i,prop in ipairs(helper.properties[objType]) do
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

function helper.getStatus(obj,type)
	local status={}
	for i,prop in ipairs(helper.properties[type]) do
		local func=obj["get"..prop] or obj["is"..prop] or obj["has"..prop]
		if func then
			local value,value2=func(obj,1)
			if value2 then
				value={func(obj,1)}
			end
			status[prop]=value
		end

	end
	return status
end






helper.properties={
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


return helper