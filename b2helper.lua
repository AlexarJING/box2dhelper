local helper={}


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


function helper.draw(world)
	love.graphics.setLineJoin( "none")
	for i,body in ipairs(world:getBodyList()) do
		local color
		if not body:isAwake() then
			color={100, 100, 100, 255}
		else
			color={100, 200, 255, 255}
		end
		local bodyX=body:getX()
		local bodyY=body:getY()
		local bodyAngle=body:getAngle()
		for i,fixture in ipairs(body:getFixtureList()) do
			local shape=fixture:getShape()
			local shapeType = shape:type()
			local shapeR=shape:getRadius()
			if shapeType=="CircleShape" then
				color[4]=255
				love.graphics.setColor(color)
				love.graphics.circle("line", bodyX, bodyY, shapeR)
				love.graphics.line(bodyX,bodyY,bodyX+math.cos(bodyAngle)*shapeR,bodyY+math.sin(bodyAngle)*shapeR)
				color[4]=50
				love.graphics.setColor(color)
				love.graphics.circle("fill", bodyX, bodyY, shapeR)
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
		love.graphics.setColor(255, 100, 100, 150)
		for i,joint in ipairs(body:getJointList()) do
			local jointType=joint:type()
			if jointType=="DistanceJoint" then
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
			elseif jointType=="WeldJoint" then
				local bodyA,bodyB = joint:getBodies()
				local aX,aY = bodyA:getPosition()
				local bX,bY = bodyB:getPosition()
				local abDirection = getRot (bX,bY,aX,aY)
				local dist = getDist(aX,aY,bX,bY)
				local verts={-5,-5,5,-5,5,dist+5,-5,dist+5}
				verts=polygonTrans(aX,aY,abDirection,1,verts)
				love.graphics.polygon("line", verts)
			elseif jointType=="PrismaticJoint" then
				local bodyA,bodyB = joint:getBodies()
				local aX,aY,bX,bY=joint:getAnchors()
				local bX,bY = bodyB:getPosition()
				local abDirection = getRot (bodyA:getX(),bodyA:getY(),bX,bY)
				local dist = getDist(aX,aY,bX,bY)
				local lower, upper = joint:getLimits( )
				lower= lower<-100 and 100 or lower
				upper= upper>100 and 100 or upper
				if lower~=-100 then
					love.graphics.line(polygonTrans(aX,aY,abDirection,1,{-10,lower-10,10,lower-10}))
				end

				if upper~=100 then
					love.graphics.line(polygonTrans(aX,aY,abDirection,1,{-10,upper+10,10,upper+10}))
				end
				love.graphics.circle("line", bX,bY,8)
				love.graphics.line(polygonTrans(aX,aY,abDirection,1,{-10,lower-10,-10,upper+10}))
				love.graphics.line(polygonTrans(aX,aY,abDirection,1,{10,lower-10,10,upper+10}))
				love.graphics.line(bodyA:getX(),bodyA:getY(),bX,bY)
			
			elseif jointType=="RevoluteJoint" then
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
			
			elseif jointType=="RopeJoint" then
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
			elseif jointType=="PulleyJoint" then
				local aX,aY,bX,bY=joint:getAnchors()
				local aGX,aGY,bGX,bGY = joint:getGroundAnchors()
				love.graphics.circle("line", aX, aY, 3)
				love.graphics.circle("line", bX, bY, 3)
				love.graphics.circle("line", aGX, aGY, 3)
				love.graphics.circle("line", bGX, bGY, 3)
				love.graphics.line(aX, aY, aGX,aGY,bGX,bGY,bX,bY)
			elseif jointType=="WheelJoint" then
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
				love.graphics.circle("line", bX, bY, 3)
				love.graphics.circle("line", aX, aY, 3)	
				love.graphics.line(polygonTrans(aX,aY,abDirection,1,{-10,0,-10,realDist}))
				love.graphics.line(polygonTrans(aX,aY,abDirection,1,{10,0 ,10,realDist}))
			end


		end
	end
end


function helper.save(world)
	local group={}
	group.obj=helper.getObjInfo(world)
	group.joint=helper.getJointInfo(world)
	return table.save(group)
end


function helper.load(world,data)
	data= loadstring(data)()
	helper.createObj(world,data)
end

function helper.createObj(world,data)
	local group={}
	for i,v in ipairs(data.obj) do
		local obj={}
		table.insert(group, obj)
		obj.body = love.physics.newBody(world)
		for prop,value in pairs(v.body) do
			if obj.body["set"..prop] then
				obj.body["set"..prop](obj.body,value)
			elseif obj.body["is"..prop] then
				obj.body["is"..prop](obj.body,value)
			end
		end

		obj.fixtures={}
		for i,param in ipairs(v.fixtures) do
			local shell={}
			local type=param.shape.type
			if type== "CircleShape" then
				shell.shape = love.physics.newCircleShape(0, 0, param.shape.Radius)
			elseif type== "EdgeShape" then
				shell.shape = love.physics.newEdgeShape(unpack(param.shape.Points))
			elseif type== "ChainShape" then
				shell.shape = love.physics.newChainShape(false, param.shape.Points)
			elseif type== "PolygonShape" then
				shell.shape = love.physics.newPolygonShape(param.shape.Points)
			end
			shell.fixture = love.physics.newFixture(obj.body, shell.shape)
			shell.fixture:setSensor(param.fixture.Sensor)
			shell.fixture:setDensity(param.fixture.Density)
			shell.fixture:setRestitution(param.fixture.Restitution)
			table.insert(obj.fixtures, shell)
		end
		if #v.fixtures==1 then
			obj.fixture = obj.fixtures[1].fixture
			obj.shape = obj.fixtures[1].shape
		end
	end

	for i,joint in ipairs(data.joint) do
		--if joint.type~="MouseJoint" then 
		--	print(joint.bodies[1],group[joint.bodies[1]].body:getFixtureList()[1]:getShape():type(),
		--		joint.bodies[2],group[joint.bodies[2]].body:getFixtureList()[1]:getShape():type()) 
		--end
		if joint.type=="DistanceJoint" then
			local j = love.physics.newDistanceJoint(
				group[joint.bodies[1]].body, 
				group[joint.bodies[2]].body, 
				joint.anchors[1], joint.anchors[2], joint.anchors[3],joint.anchors[4],
				joint.CollideConnected)
			j:setDampingRatio(joint.DampingRatio)
			j:setFrequency(joint.Frequency)
		elseif joint.type=="PrismaticJoint" then
			local angle= getRot(joint.anchors[1], joint.anchors[2], joint.anchors[3], joint.anchors[4])
			local j = love.physics.newPrismaticJoint(
				group[joint.bodies[1]].body, 
				group[joint.bodies[2]].body,
				joint.anchors[1], joint.anchors[2], joint.anchors[3], joint.anchors[4],
				math.cos(angle), 
				math.sin(angle),
				joint.CollideConnected)
			j:setLimits(unpack(joint.Limits))
			j:setMaxMotorForce(joint.MaxMotorForce)
			j:setMotorSpeed(joint.MotorSpeed)
		elseif joint.type=="PulleyJoint" then
			local j = love.physics.newPulleyJoint(
				group[joint.bodies[1]].body, 
				group[joint.bodies[2]].body, 
				joint.GroundAnchors[1], joint.GroundAnchors[2], joint.GroundAnchors[3],joint.GroundAnchors[4],
				joint.anchors[1], joint.anchors[2], joint.anchors[3],joint.anchors[4],
				joint.Ratio,joint.CollideConnected)
		elseif joint.type=="RevoluteJoint" then
			local j = love.physics.newRevoluteJoint(
				group[joint.bodies[1]].body, 
				group[joint.bodies[2]].body,  
				joint.anchors[1], joint.anchors[2],
				joint.CollideConnected)
			j:setLimits(unpack(joint.Limits))
			j:setMaxMotorTorque(joint.MaxMotorTorque)
			j:setMotorSpeed(joint.MotorSpeed)
		elseif joint.type=="RopeJoint" then
			local j = love.physics.newRopeJoint(
				group[joint.bodies[1]].body, 
				group[joint.bodies[2]].body,
				joint.anchors[1], joint.anchors[2], joint.anchors[3],joint.anchors[4], 
				joint.MaxLength, joint.CollideConnected)
		elseif joint.type=="WeldJoint" then
			local j = love.physics.newWeldJoint(
				group[joint.bodies[1]].body, 
				group[joint.bodies[2]].body, 
				joint.anchors[1], joint.anchors[2], joint.anchors[3],joint.anchors[4],
				joint.CollideConnected)
			j:setDampingRatio(joint.DampingRatio)
			j:setFrequency(joint.Frequency)
		elseif joint.type=="WheelJoint" then
			local angle= getRot(
				joint.anchors[1], joint.anchors[2],
			group[joint.bodies[1]].body:getX(), 
			group[joint.bodies[1]].body:getY()
			 )
			local j = love.physics.newWheelJoint(
				group[joint.bodies[1]].body, 
				group[joint.bodies[2]].body,
				joint.anchors[1], joint.anchors[2],
				math.sin(angle), 
				math.cos(angle),
				joint.CollideConnected)
			j:setSpringDampingRatio(joint.SpringDampingRatio)
			j:setSpringFrequency(joint.SpringFrequency)
			j:setMaxMotorTorque(joint.MaxMotorTorque)
			j:setMotorSpeed(joint.MotorSpeed)
		end
	end
end


function helper.getObjInfo(world)
	local tab={}
	local index=0
	for i,body in ipairs(world:getBodyList()) do
		local obj={}
		table.insert(tab, obj)
		index=index+1
		body:setUserData(index)
		--print(index,body:getFixtureList()[1]:getShape():type())
		local status=helper.getStatus(body,"body")
		obj.body=status
		obj.fixtures={}
		for i,fixture in ipairs(body:getFixtureList()) do
			table.insert(obj.fixtures, {
			shape=helper.getStatus(fixture:getShape(),"shape"),
			fixture=helper.getStatus(fixture,"fixture")})
		end
		
	end
	return tab
end

function helper.getJointInfo(world)
	local tab={}
	local index=0
	for i,body in ipairs(world:getBodyList()) do	
		for i,joint in ipairs(body:getJointList()) do
			local check = joint:getUserData()
			if tab[check]==nil then 
				index=index+1
				local status={}
				table.insert(tab, status)
				joint:setUserData(index)
				status.type=joint:type()
				status.CollideConnected =joint:getCollideConnected( )
				if status.type~="MouseJoint" then
					local bodyA,bodyB = joint:getBodies()
					status.bodies={bodyA:getUserData(),bodyB:getUserData()}
					status.anchors={joint:getAnchors()}
				end
				
				if status.type=="DistanceJoint" then
					status.DampingRatio=joint:getDampingRatio()
					status.Frequency = joint:getFrequency()	
				elseif status.type=="WeldJoint" then
					status.DampingRatio=joint:getDampingRatio()
					status.Frequency = joint:getFrequency()	
				elseif status.type=="PrismaticJoint" then
					status.Limits={joint:getLimits( )}
					status.MaxMotorForce=joint:getMaxMotorForce()
					status.MotorSpeed = joint:getMotorSpeed()
				
				elseif status.type=="RevoluteJoint" then
					status.Limits={joint:getLimits( )}
					status.MaxMotorTorque=joint:getMaxMotorTorque()
					status.MotorSpeed = joint:getMotorSpeed()
				
				elseif status.type=="RopeJoint" then
					status.MaxLength = joint:getMaxLength()
				elseif status.type=="PulleyJoint" then
					status.GroundAnchors = {joint:getGroundAnchors()}
					status.Ratio = joint:getRatio() 
				elseif status.type=="WheelJoint" then
					status.SpringDampingRatio=joint:getSpringDampingRatio()
					status.SpringFrequency = joint:getSpringFrequency()	
					status.MaxMotorTorque=joint:getMaxMotorTorque()
					status.MotorSpeed = joint:getMotorSpeed()
				end
			end
		end
	end
	return tab
end
helper.getList={
		body={
	"X","Y","Angle",
	"AngularDamping","LinearDamping",
	"Type"
	},
		fixture={
	"Restitution",
	"Density",
	},
}

helper.isList={
	body={
"Bullet","FixedRotation"
},
	fixture={
"Sensor"	
}
}



function helper.getStatus(obj,type)
	local status={}
	if type=="shape" then
		status.type= obj:type()		
		if status.type=="CircleShape" then
			status.Radius=obj:getRadius()
		else
			status.Points={obj:getPoints()}
		end
		return status
	end
	for i,v in ipairs(helper.getList[type]) do
		status[v]=obj["get"..v](obj)
	end
	for i,v in ipairs(helper.isList[type]) do
		status[v]=obj["is"..v](obj)
	end
	return status
end

function table.save(tab,name)
	name=name or "test"
	local output="local "..name.."=\n"
	local function ergodic(target,time)
		time=time+1
		output=output.."{\n"
		for k,v in pairs(target) do
			output=output .. string.rep("\t",time)
			if type(v)=="table" then
				if type(k)=="number" then
					output=output.."["..k.."]".."="
				elseif type(k)=="string" then
					output=output.."[\""..k.."\"]="
				end 
				ergodic(v,time)
				output=output .. string.rep("\t",time)
				output=output.."},\n"
			elseif type(v)=="string" then
				if type(k)=="number" then
					output=output.."["..k.."]".."=\""..v.."\",\n"
				elseif type(k)=="string" then
					output=output.."[\""..k.."\"]=\""..v.."\",\n"
				end 
			elseif type(v)=="number" or type(v)=="boolean" then
				if type(k)=="number" then
					output=output.."["..k.."]".."="..tostring(v)..",\n"
				elseif type(k)=="string" then
					output=output.."[\""..k.."\"]="..tostring(v)..",\n"
				end 
			end
		end
	end
	ergodic(tab,0)
	output=output.."}\nreturn "..name
	return output 
end

return helper