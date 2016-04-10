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

local defaultStyle= {
		dynamic={100, 200, 255, 255},
		static={100, 100, 100, 255},
		kinematic={100, 255, 200, 255},
		sensor={0,0,-255,0},
		joint={255, 100, 100, 150},
		body={255, 0, 255, 50}
	}

local function getUserData(obj)
	local raw=obj:getUserData()
	if raw==nil then return end
	if type(raw)=="table" then
		return {type(raw),table.save(raw)}
	elseif type(raw)=="function" then
		return {type(raw),string.dump(raw)}
	else
		return {type(raw),tostring(raw)}
	end
end

local function setUserData(obj,raw)
	if raw==nil then return end
	if raw[1]=="table" then
		obj:setUserData(loadstring(raw[2])())
	elseif raw[1]=="number" then
		obj:setUserData(tonumber(raw[2]))
	elseif raw[1]=="function" then
		obj:setUserData(loadstring(raw[3]))
	elseif raw[1]=="boolean" then
		if raw[2]=="false" then
			obj:setUserData(false)
		else
			obj:setUserData(true)
		end
	elseif raw==nil then
		obj:setUserData(nil)
	else
		obj:setUserData(tostring(raw[2]))
	end
end

function helper.draw(world,colorStyle)
	colorStyle=colorStyle or defaultStyle

	if type(world)=="userdata" then
		bodyList=world:getBodyList()
	else
		bodyList=world
	end

	love.graphics.setLineJoin( "none")
	for i,body in ipairs(bodyList) do
		local color
		
		local bodyX=body:getX()
		local bodyY=body:getY()
		love.graphics.setColor(colorStyle.body)
		love.graphics.circle("fill", bodyX, bodyY, 4)
		local bodyAngle=body:getAngle()
		local bodyType= body:getType()
		for i,fixture in ipairs(body:getFixtureList()) do
			local shape=fixture:getShape()
			local shapeType = shape:type()
			local shapeR=shape:getRadius()
			local isSensor = fixture:isSensor()
			if  bodyType=="dynamic" then
				color=colorStyle.dynamic
			elseif bodyType=="static" then
				color=colorStyle.static
			elseif bodyType=="kinematic" then
				color=colorStyle.kinematic
			end


			if isSensor then		
				for i=1,4 do
					color[i]=color[i]-colorStyle.sensor[i]
				end
			end


			if shapeType=="CircleShape" then
				color[4]=255
				local offx,offy= shape:getPoint()
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
		love.graphics.setColor(colorStyle.joint)
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
				local aX,aY= bodyA:getPosition()
				local bX,bY = bodyB:getPosition()
				local jX,jY = joint:getAnchors()
				local abDirection = getRot (bX,bY,aX,aY)
				--local dist = getDist(aX,aY,bX,bY)
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
				love.graphics.circle("line", bX, bY, 8)
				love.graphics.line(polygonTrans(aX,aY,abDirection,1,{-10,0,-10,realDist}))
				love.graphics.line(polygonTrans(aX,aY,abDirection,1,{10,0 ,10,realDist}))
				love.graphics.line(polygonTrans(aX,aY,abDirection,1,{10,0 ,-10,0}))
			end
		end
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

function helper.createWorld(world,data,offx,offy)
	offx=offx or 0
	offy=offy or 0
	local group={}
	for i,v in ipairs(data.obj) do
		local obj={}
		table.insert(group, obj)
		obj.body = love.physics.newBody(world)
		---set prop
		for prop,value in pairs(v.body) do
			if obj.body["set"..prop] then
				obj.body["set"..prop](obj.body,value)
			end
		end

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

			for prop,value in pairs(param.fixture) do
				if shell.fixture["set"..prop] then
					if type(value)=="table" then
						shell.fixture["set"..prop](shell.fixture,unpack(value))
					else
						shell.fixture["set"..prop](shell.fixture,value)
					end
					
				end
			end
			
			setUserData(shell.fixture,param.fixture.userdata)
			table.insert(obj.fixtures, shell)
		end
		if #v.fixtures==1 then
			obj.fixture = obj.fixtures[1].fixture
			obj.shape = obj.fixtures[1].shape
		end
	end

	for i,joint in ipairs(data.joint) do
		local j
		if joint.Type=="distance" then
			j = love.physics.newDistanceJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body, 
				joint.Anchors[1], joint.Anchors[2], joint.Anchors[3],joint.Anchors[4],
				joint.CollideConnected)
			j:setDampingRatio(joint.DampingRatio)
			j:setFrequency(joint.Frequency)
		elseif joint.Type=="prismatic" then
			local angle= getRot(joint.Anchors[1], joint.Anchors[2], joint.Anchors[3], joint.Anchors[4])
			j = love.physics.newPrismaticJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body,
				joint.Anchors[1], joint.Anchors[2], joint.Anchors[3], joint.Anchors[4],
				math.cos(angle), 
				math.sin(angle),
				joint.CollideConnected)
			j:setLimits(unpack(joint.Limits))
			j:setMaxMotorForce(joint.MaxMotorForce)
			j:setMotorSpeed(joint.MotorSpeed)
		elseif joint.Type=="pulley" then
			j = love.physics.newPulleyJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body, 
				joint.GroundAnchors[1], joint.GroundAnchors[2], joint.GroundAnchors[3],joint.GroundAnchors[4],
				joint.Anchors[1], joint.Anchors[2], joint.Anchors[3],joint.Anchors[4],
				joint.Ratio,joint.CollideConnected)
		elseif joint.Type=="revolute" then
			j = love.physics.newRevoluteJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body,  
				joint.Anchors[1], joint.Anchors[2],
				joint.CollideConnected)
			j:setLimits(unpack(joint.Limits))
			j:setMaxMotorTorque(joint.MaxMotorTorque)
			j:setMotorSpeed(joint.MotorSpeed)
		elseif joint.Type=="rope" then
			j = love.physics.newRopeJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body,
				joint.Anchors[1], joint.Anchors[2], joint.Anchors[3],joint.Anchors[4], 
				joint.MaxLength, joint.CollideConnected)
		elseif joint.Type=="weld" then
			j = love.physics.newWeldJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body, 
				joint.Anchors[1], joint.Anchors[2], joint.Anchors[3],joint.Anchors[4],
				joint.CollideConnected)
			j:setDampingRatio(joint.DampingRatio)
			j:setFrequency(joint.Frequency)
		elseif joint.Type=="wheel" then
			local angle= getRot(
				joint.Anchors[1], joint.Anchors[2],
			group[joint.Bodies[1]].body:getX(), 
			group[joint.Bodies[1]].body:getY()
			 )
			j = love.physics.newWheelJoint(
				group[joint.Bodies[1]].body, 
				group[joint.Bodies[2]].body,
				joint.Anchors[1], joint.Anchors[2],
				math.sin(angle), 
				math.cos(angle),
				joint.CollideConnected)
			j:setSpringDampingRatio(joint.SpringDampingRatio)
			j:setSpringFrequency(joint.SpringFrequency)
			j:setMaxMotorTorque(joint.MaxMotorTorque)
			j:setMotorSpeed(joint.MotorSpeed)
		end

		j:setUserData(joint.userdata)
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


function helper.getWorldData(world,offx,offy)
	offx =offx or 0
	offy =offy or 0
	local bodyList --如果不是world 那么就是body list
	if type(world)=="userdata" then
		bodyList=world:getBodyList()
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

	group.joint={}

	for i,body in ipairs(bodyList) do	
		for i,joint in ipairs(body:getJointList()) do	
			if joint:getBodies()==body then --the first body==self body
				local status=helper.getStatus(joint,"joint")
				status.Bodies={getBodyIndex(bodyList,status.Bodies[1]),
								getBodyIndex(bodyList,status.Bodies[2])}
				table.insert(group.joint, status)
			end
		end
	end
	
	return group

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

function table.save(tab,name,ifCopyFunction)
	name=name or "test"
	tableList=tablelist or {{name="root",tab=tab}} --to protect loop
	local output="local "..name.."=\n"
	local function ergodic(target,time)
		time=time+1
		output=output.."{\n"
		for k,v in pairs(target) do
			output=output .. string.rep("\t",time)
			local name
			if type(k)=="number" then
				name="["..k.."]"
			elseif type(k)=="string" then
				name="[\""..k.."\"]"
			end 
			if type(v)=="table" then
				output=output .. name .."="
				local checkRepeat
				for _,p in ipairs(tableList) do
					if v==p.tab then
						checkRepeat=true;break
					end
				end
				if checkRepeat then
					output=output.. name .."=table^"..p.name..",\n"
				else
					table.insert(tableList,{name=name,tab=v})
					ergodic(v,time)
					output=output .. string.rep("\t",time)
					output=output.."},\n"
				end
			elseif type(v)=="string" then
				if string.find(v,"\n") then
					output=output.. name .."=[["..v.."]],\n"
				else
					output=output.. name .."=\""..v.."\",\n"
				end
				
			elseif type(v)=="number" or type(v)=="boolean" then
					output=output..name.."="..tostring(v)..",\n"
			elseif type(v)=="function" and ifCopyFunction then
				output=output .. name .."=".."loadstring(\""..string.dump(v).."\")"..",\n"			
			end
		end
	end
	ergodic(tab,0)
	output=output.."}\nreturn "..name
	return output 
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
	"Category",
	"Restitution",
	"Density",
	"FilterData",
	"Friction",
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
	"GroundAnchors",
	"Limits",
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

	}
}


return helper