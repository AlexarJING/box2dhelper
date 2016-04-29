local helper
local collMode={}
local func={}

collMode.collisionFunc=func




local function findReaction(callbackType,a,b,...)
	local data=a:getUserData()

	if data then
		for i,v in ipairs(data) do
			if collMode.collisionType[callbackType][v.prop]  then
				collMode.collisionType[callbackType][v.prop](v.value,a,b,...)
			end
		end
	end
	local data=b:getUserData()
	if data then
		for i,v in ipairs(data) do
			if collMode.collisionType[callbackType][v.prop]  then
				collMode.collisionType[callbackType][v.prop](v.value,b,a,...)
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

function collMode.setCallbacks(world)
	world:setCallbacks(beginC,endC,preC,postC)
end





func.explosion=function(boomV,a,b,coll)	
	coll:setEnabled(false)
	boomV=10000
	local frags={}
	local func=function(a,b,coll)
		if a:isDestroyed() then return end
		local x,y=a:getBody():getPosition()
		local r = a:getShape():getRadius()
		for i=1,r do
			local body = love.physics.newBody(helper.world, x, y,"dynamic")
			local shape = love.physics.newCircleShape(3)
			local fixture = love.physics.newFixture(body, shape,10)
			fixture:setDensity(99)
			fixture:setFriction(99)
			fixture:setRestitution(0.5)
			local angle= love.math.random()*math.pi*2
			body:setLinearVelocity(math.sin(angle)*boomV,math.cos(angle)*boomV)
			body:setLinearDamping(3)
			body:setUserData({{prop="anticount",value=4}})
			fixture:setGroupIndex(-2)
			fixture:setUserData({
				{prop="destoryOnHit",value=0}
				})
			
			table.insert(frags, body)
		end
		a:getBody():destroy()
	end
	table.insert(helper.system.todo,{func,a,b,coll})

end

func.spark=function(a,b,coll)
	local func=function(threshold,a,b,coll)
		if a:isDestroyed() or b:isDestroyed() or coll:isDestroyed() then return end
		threshold =300
		local bodyA,bodyB=a:getBody(),b:getBody()
		local matA,hardA,matB,hardB
		local tab=a:getUserData()
		if not tab then return end
		for i,v in ipairs(tab) do
			if v.prop=="material" then matA=v.value end
			if v.prop=="hardness" then hardA=v.value end
		end
		tab=b:getUserData()
		if not tab then return end
		for i,v in ipairs(tab) do
			if v.prop=="material" then matB=v.value end
			if v.prop=="hardness" then hardB=v.value end
		end
		if hardA<=hardB then
			local vxA,vyA=bodyA:getLinearVelocity()
			local vxB,vyB=bodyB:getLinearVelocity()
			local relativeX,relativeY=vxB-vxA,vyB-vyA
			local relativeAB = getDist(0,0,relativeX,relativeY)
			local fAB = a:getFriction()*b:getFriction()
			local intensity =fAB*relativeAB
			local x, y = coll:getPositions( )
			
			if intensity<threshold then return end
			
			for i=1,relativeAB/300 do
				local body = love.physics.newBody(helper.world, x, y,"dynamic")
				body:setGravityScale(1)
				body:setLinearDamping(3)
				local shape = love.physics.newCircleShape(8)
				local fixture = love.physics.newFixture(body, shape)
				fixture:setDensity(0.01)
				fixture:setFriction(5)
				fixture:setRestitution(0)
				body:setLinearVelocity(-relativeX+1.2*relativeX*love.math.random(),
					-relativeY+1.2*relativeY*love.math.random())
				fixture:setMask(2)
				local func2=function()
					if not body:isDestroyed() then
						body:destroy()
					end
				end
				helper.system.addDelay(func2,3)
			end
		end
	end
	table.insert(helper.system.todo,{func,a,b,coll})
end
	
func.reverse=function(toggle,a,b,coll)
	local func=function(a,b,coll)
		if a:isDestroyed() then return end
		local body=a:getBody()
		local jointList=body:getJointList()
		for i,joint in ipairs(jointList) do
			if joint:getType()=="revolute" or joint:getType()=="prismatic" then
				joint:setMotorSpeed(-joint:getMotorSpeed())
			end
		end
	end
	table.insert(helper.system.todo,{func,a,b,coll})
end


func.embed=function(threshold,a,b,coll,np,tp)
	if not threshold then return end
	if np<threshold then return end
	local func=function(a,b,coll,npA,tpA)
		if a:isDestroyed() or b:isDestroyed() or coll:isDestroyed() then return end
		if np<threshold then return end
		coll:setEnabled(false)
		local body1,body2=a:getBody(),b:getBody()
		local x,y=coll:getPositions()
		love.physics.newWeldJoint(body1, body2, x, y, false)
		for i,v in ipairs(a:getUserData()) do
			if v.prop=="embed" then 
				v.value=false
				return
			end 
		end
	end
	table.insert(helper.system.todo,{func,a,b,coll})
end
	
func.crash=function(threshold,a,b,coll,np,tp)
	threshold=100
	local func=function(a,b,coll,npA,tpA)
		if a:isDestroyed() or b:isDestroyed() or coll:isDestroyed() then return end
		if np<threshold then return end
		local bodyA,bodyB=a:getBody(),b:getBody()
		local matA,hardA,matB,hardB
		local tab=a:getUserData()
		if not tab then return end
		
		local nx,ny= coll:getNormal()
		local x, y = coll:getPositions( )
		TestX,TestY=x,y
		local angle
		if a==coll:getFixtures() then
			angle=math.getRot(0,0,nx,ny)-math.pi
		else
			angle=math.getRot(0,0,nx,ny)
		end
		local rayLen=np
		local rayAnlges={}
		local shapeType=a:getShape():getType()
		local body=a:getBody()
		local function circle2polygon(a)
			local x,y=a:getShape():getPoint()
			local r = a:getShape():getRadius()
			local verts={}
			for i=1,8 do
				table.insert(verts, x+r*math.sin(i*math.pi/4))
				table.insert(verts, y+r*math.cos(i*math.pi/4))
			end
			local shape = love.physics.newPolygonShape(verts)
			local body=a:getBody()
			a:destroy()
			return love.physics.newFixture(body, shape)
		end
		if shapeType=="circle" then
			a=circle2polygon(a)
		end
		local verts={}
		local hitPoints={}
		TestVerts=verts
		local count=np/20>5 and 6 or np/20
		count= count<1 and 1 or count
		for i=1,count do
			local rayAngle=angle-math.pi/3+love.math.random()*Pi*2/3
			local rayX,rayY=x+math.sin(rayAngle)*rayLen,y-math.cos(rayAngle)*rayLen
			table.insert(rayAnlges, rayAnlge)
			local xn, yn, fraction = a:rayCast(rayX,rayY, x, y, 1 )
			table.insert(hitPoints,{x=rayX,y=rayY})
			if xn then
				local hitx, hity = rayX + (x - rayX) * fraction, rayY + (y - rayY) * fraction
				table.insert(verts, {x=hitx,y=hity,isRay=true})
			end
		end

		local bodyPoints={body:getWorldPoints( a:getShape():getPoints() )}
		for i=1,#bodyPoints-1,2 do
			table.insert(verts, 
				{x=bodyPoints[i],y=bodyPoints[i+1],isRay=false})
		end
		
		for i,v in ipairs(verts) do
			v.angle=math.getRot(v.x,v.y,x,y)+angle+math.pi/2
			if v.angle<0 then v.angle=v.angle+2*math.pi end
		end

		table.sort( verts, function(a,b) return a.angle<b.angle end)

		local lastVertX,lastVertY=verts[1].x,verts[1].y
		local lastAngle=verts[1].angle
		local fragVerts={}
		local function makeFrag()
			if #fragVerts<2 then return end
			if #fragVerts>8 then  fragVerts={unpack(fragVerts, 1, 8)} end
			table.insert(fragVerts,x)
			table.insert(fragVerts,y)
			table.insert(fragVerts,lastVertX)
			table.insert(fragVerts,lastVertY)
			local body = love.physics.newBody(helper.world, x, y, "dynamic")
			local shape
			local test,re =pcall(love.physics.newPolygonShape,math.polygonTrans(-x,-y,0,1,fragVerts))
			if test then
				shape=re
			
				local fixture = love.physics.newFixture(body, shape)
				local l, t, r, b = fixture:getBoundingBox()
				if (r-l)*(b-t)>1000 then
						fixture:setUserData({
					{prop="crashable",value=true},
					{prop="material",value="rock"},
					{prop="hardness",value=3},
					 })
				end
			end
			
			lastVertX,lastVertY=fragVerts[#fragVerts-5],fragVerts[#fragVerts-4]
			fragVerts={}
		end

		for i,v in ipairs(verts) do
			table.insert(fragVerts,v.x)
			table.insert(fragVerts,v.y)
			if v.isRay==true and v.angle-lastAngle>0.05  then
				makeFrag()
			end
			lastAngle=v.angle
		end
		makeFrag()
		a:getBody():destroy()
	end
	table.insert(helper.system.todo,{func,a,b,coll})
end

function func.oneWayPre(enabled,a,b,coll)
	for i,v in ipairs(a:getUserData()) do
		if v.prop=="oneWayState" then 
			coll:setEnabled(v.value)
			return
		end 
	end
	local bodyA=a:getBody()
	local bodyB=b:getBody()
	local x1,y1,x2,y2= coll:getPositions()
	local avx1, avy1 = bodyA:getLinearVelocityFromWorldPoint( x1, y1 )
	local bvx1, bvy1 = bodyB:getLinearVelocityFromWorldPoint( x1, y1 )
	local rvx1,rvy1 = bodyA:getLocalVector(bvx1-avx1,bvy1-avy1)

	if x2 then
		local avx2, avy2 = bodyA:getLinearVelocityFromWorldPoint( x2, y2 )
	 	local bvx2, bvy2 = bodyB:getLinearVelocityFromWorldPoint( x2, y2 )
		local rvx2,rvy2 = bodyA:getLocalVector(bvx2-avx2,bvy2-avy2)
	end

	coll:setEnabled(false)
	if rvy1>0 or (x2 and rvy2>0) then
		coll:setEnabled(true)
		table.insert(a:getUserData(), {prop="oneWayState",value=true})
	else
		table.insert(a:getUserData(), {prop="oneWayState",value=false})
	end
	
end

function func.oneWayEnd(enabled,a,b,coll)
	coll:setEnabled(true)
	for i,v in ipairs(a:getUserData()) do
		if v.prop=="oneWayState" then 
			table.remove(a:getUserData(), i)
			return 
		end 
	end
end

function func.buoyancy(density,a,b,coll)  --in pre
	local bodyA,bodyB=a:getBody(),b:getBody()
	coll:setEnabled(false)
	if bodyB:getType()~="dynamic" then return end
	local bVerts
	local shapeA,shapeB=a:getShape(),b:getShape()
	if shapeB:getType()=="circle" then
		local x,y=shapeB:getPoint()
		local r = shapeB:getRadius()
		local count= r/3 > 8 and r/3 or 8
		bVerts={}
		for i=1,count do
			table.insert(bVerts, x+r*math.sin(i*math.pi*2/count))
			table.insert(bVerts, y+r*math.cos(i*math.pi*2/count))
		end
	else
		bVerts={bodyB:getWorldPoints(shapeB:getPoints())}
	end

	local aVerts={bodyA:getWorldPoints(shapeA:getPoints())}
	local intersection = math.polygonClip(bVerts,aVerts)
	if not intersection then return end
	local cx,cy,area = math.getPolygonArea(intersection)
	if not area then return end

	local displacedMass = area*density/love.physics.getMeter( )
	bodyB:applyForce(0,-displacedMass*9.8,cx,cy)
	local vx,vy= bodyB:getLinearVelocity()
	bodyB:applyForce(-vx/10,-vy/10)
	local vr = bodyB:getAngularVelocity()
	bodyB:applyTorque(-vr*5000)

	local dragMod = 0.25
    local liftMod = 0.25
    local maxDrag = 20
    local maxLift = 5

    for i=1, #intersection-1,2 do
    	local p1x,p1y=intersection[i],intersection[i+1]
    	local ii = i+2>#intersection and 1 or i+2
    	local p2x,p2y=intersection[ii],intersection[ii+1]
    	local pmx,pmy = (p1x+p2x)/2,(p1y+p2y)/2

 		local vax,vay=bodyA:getLinearVelocityFromWorldPoint(pmx,pmy)
 		local vbx,vby=bodyB:getLinearVelocityFromWorldPoint(pmx,pmy)

 		local vrx,vry=vbx-vax,vby-vay
 		local vr=math.vec2.normalize(vrx,vry)

 		local ex,ey=p2x-p1x,p2y-p1y
 		local elen=math.vec2.normalize(ex,ey)
 		local enx,eny=math.vec2.cross(-1,0,ex,ey),0
 		local dragDot=math.vec2.dot(enx,eny,vrx,vry)

 		if dragDot>=0 then
 			local dragMag=dragDot * dragMod * elen * density * vr * vr/ love.physics.getMeter()^3;
 			if dragMag>0 then
 				dragMag = math.min( dragMag, maxDrag )
 			elseif dragMag<0 then
 				dragMag = math.max( dragMag, -maxDrag )
 			end
 			local dragForceX,dragForceY=-dragMag*vrx,-dragMag*vry


 			local liftDot=math.vec2.dot(ex,ey,vrx,vry)
 			local liftMag =dragDot *liftDot* liftMod * elen * density * vr * vr/ love.physics.getMeter()^3
 			liftMag = math.min(liftMag,maxLift)
 			if liftMag>0 then
 				liftMag = math.min( liftMag, maxLift )
 			elseif liftMag<0 then
 				liftMag = math.max( liftMag, -maxLift )
 			end
 			local lx,ly= math.vec2.cross(1,0,vrx,vry),0
 			local liftForceX,liftForceY=-liftMag*lx,-liftMag*ly
			bodyB:applyForce(liftForceX,liftForceY,pmx,pmy)

 		end
    end
end



function func.magnet(power,a,b,coll)
	coll:setEnabled(false)
	local tab=b:getUserData()
	local magB --B的磁场
	if not tab then return end
	for i,v in ipairs(tab) do
		if v.prop=="material" then matB=v.value end
		if v.prop=="magnetField" then magB=v.value end
	end
	local parent = a:getBody():getFixtureList()[#a:getBody():getFixtureList()]

	if (not matB=="steel") and (matB=="magnet") then return end
	local bodyA,bodyB=a:getBody(),b:getBody()
	local shapeA,shapeB=a:getShape(),b:getShape()
	local xA,yA= bodyA:getWorldPoint(shapeA:getPoint())
	local xB,yB
	--local r = shapeA:getRadius()
	if matB=="steel" and magB==nil then
		xB,yB= bodyB:getPosition()
		local distance = math.getDistance(xA,yA,xB,yB)
		local distX,distY=xA-xB,yA-yB
		local power=math.abs(power)/(1+distance)
		local angle=math.getRot(xB,yB,xA,yA)

		bodyA:applyForce(-power*math.sin(angle), power*math.cos(angle))
		bodyB:applyForce(power*math.sin(angle), -power*math.cos(angle))
	end
	if magB then
		xB,yB= bodyB:getWorldPoint(shapeB:getPoint())
		local distance = math.getDistance(xA,yA,xB,yB)
		local distX,distY=xA-xB,yA-yB
		if math.sign(magB)~=math.sign(power) then
			power=math.abs(power)/(1+distance)
		else
			power=-math.abs(power)/(1+distance)
		end
		local angle=math.getRot(xB,yB,xA,yA)
		bodyA:applyForce(-power*math.sin(angle), power*math.cos(angle),xA,yA)
		bodyB:applyForce(power*math.sin(angle), -power*math.cos(angle),xB,yB)
	end
end

function func.destoryOnHit(p,a,b,c)
	local func=function(a) 
		if a:isDestroyed() then return end
		a:getBody():destroy() 
	end
	table.insert(helper.system.todo,{func,a})
end


collMode.collisionType={
	begin={
		makeFrag=collMode.collisionFunc.spark,
		reverse=collMode.collisionFunc.reverse,
		explosion=collMode.collisionFunc.explosion,
		destoryOnHit=collMode.collisionFunc.destoryOnHit,
		},
	over={
		oneWay=collMode.collisionFunc.oneWayEnd,
	},
	pre={
		oneWay=collMode.collisionFunc.oneWayPre,
		buoyancy=collMode.collisionFunc.buoyancy,
		magnetField=collMode.collisionFunc.magnet,
	},
	post={
		crashable=collMode.collisionFunc.crash,
		embed=collMode.collisionFunc.embed,

	}	
}

return function(parent) 
	helper=parent
	helper.collMode=collMode
end