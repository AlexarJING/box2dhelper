local helper
local collMode={}
local func={}

collMode.collisionFunc=func




local function findReaction(callbackType,a,b,...)
	local data=a:getUserData()

	if data then
		local script
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

local script_callbacks = {
	beginC = {},
	endC = {},
	preC = {},
	postC = {}
}


local function findScript(ctype,a, b, contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
	local body = a:getBody()
	if script_callbacks[ctype][body] then
		script_callbacks[ctype][body](
			a,b,contact, normal_impulse1, tangent_impulse1, normal_impulse2, tangent_impulse2)
	end

	local body = b:getBody()
	if script_callbacks[ctype][body] then
		script_callbacks[ctype][body](
			b,a,contact, normal_impulse2, tangent_impulse2, normal_impulse1, tangent_impulse1)
	end
end


local function beginC(...)
	findScript("beginC",...)
	findReaction("begin",...)
	
end

local function endC(...)
	findScript("endC",...)
	findReaction("over",...)	
end

local function preC(...)
	findScript("preC",...)
	findReaction("pre",...)
end

local function postC(...)
	findScript("postC",...)
	findReaction("post",...)
	
end



local function setScriptCallbacks(world)
	for i,body in ipairs(world:getBodyList()) do
		local scription = helper.getProperty(body,"scription")
		if scription then
			if scription.beginC then script_callbacks.beginC[body]=scription.beginC end
			if scription.endC then script_callbacks.endC[body] = scription.endC end
			if scription.preC then script_callbacks.preC[body]=scription.preC end
			if scription.postC then script_callbacks.postC[body]=scription.postC end
		end
	end

end

function collMode.setCallbacks()
	local world = helper.world
	setScriptCallbacks(world)
	world:setCallbacks(beginC,endC,preC,postC)
end





func.explosion=function(boomV,a,b,coll)	
	
	
	boomV=boomV or 1000
	local frags={}
	local func=function(a,b,coll)
		if a:isDestroyed() then return end
		local x,y=a:getBody():getPosition()
		local r = a:getShape():getRadius()
		for i=1,r do
			local body = love.physics.newBody(helper.world, x, y,"dynamic")
			local shape = love.physics.newCircleShape(3)
			local fixture = love.physics.newFixture(body, shape,99)
			fixture:setDensity(99)
			--fixture:setFriction(99)
			fixture:setRestitution(0.5)
			fixture:setGroupIndex(-1)
			local angle= love.math.random()*math.pi*2
			body:setLinearVelocity(math.sin(angle)*boomV,math.cos(angle)*boomV)
			--body:setLinearDamping(3)
			body:setBullet(true)
			body:setUserData({{prop="anticount",value=love.math.random()*2}})
			helper.reactMode.addBody(body)
			table.insert(frags, body)
		end
		a:getBody():destroy()
	end
	table.insert(helper.system.todo,{func,a,b,coll})

end

func.spark=function(threshold,a,b,coll)
	threshold = threshold or 300
	local func=function(threshold,a,b,coll)
		if a:isDestroyed() or b:isDestroyed() or coll:isDestroyed() then return end
		
		local bodyA,bodyB=a:getBody(),b:getBody()
		
		local matA=helper.getProperty(a,"material")
		local hardA=helper.getProperty(a,"hardness")
		local matB=helper.getProperty(b,"material")
		local hardB=helper.getProperty(b,"hardness")

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
	
func.reverse=function(enabled,a,b,coll)
	if not enabled then return end
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
		helper.setProperty(a,"embed",false)
	end
	table.insert(helper.system.todo,{func,a,b,coll})
end

local function circle2polygon(a,rate)
	rate = rate  or 8
	local x,y=a:getShape():getPoint()
	local r = a:getShape():getRadius()
	local verts={}
	for i=1,rate do
		table.insert(verts, x+r*math.sin(i*2*math.pi/rate))
		table.insert(verts, y+r*math.cos(i*2*math.pi/rate))
	end
	local shape = love.physics.newPolygonShape(verts)
	local body=a:getBody()
	a:destroy()
	return love.physics.newFixture(body, shape)
end


func.crash=function(threshold,a,b,coll,np,tp)
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
		
		if shapeType=="circle" then
			a=circle2polygon(a,16)
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
					if helper.getProperty(a,"crashcombo") then
						helper.setProperty(fixture,"crashable",threshold)
					end
					helper.setProperty(fixture,"meterial","rock")
					helper.setProperty(fixture,"hardness",3)			
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
	if helper.getProperty(a,"oneWayState")~=nil then
		coll:setEnabled(helper.getProperty(a,"oneWayState"))
		return
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
		helper.setProperty(a,"oneWayState",true)
	else
		helper.setProperty(a,"oneWayState",false)
	end
	
end


function func.oneWayEnd(enabled,a,b,coll)
	coll:setEnabled(true)
	helper.setProperty(a,"oneWayState",nil)
end

function func.bulletPre(enabled,a,b,coll)
	if not enabled then return end
	coll:setEnabled(false)
	a:setSensor(true)
end

function func.bulletEnd(enabled,a,b,coll)
	if helper.getProperty(a,"lancher")==b then
		a:setSensor(false)
		helper.setProperty(a,"bullet",false)
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


	local gx,gy=helper.world:getGravity()
	local aVerts={bodyA:getWorldPoints(shapeA:getPoints())}
	local intersection = math.polygonClip(bVerts,aVerts)
	if not intersection then return end
	local cx,cy,area = math.getPolygonArea(intersection)
	if not area then return end

	local displacedMass = area*density/love.physics.getMeter()^2
	bodyB:applyForce(-displacedMass*gx ,-displacedMass*gy,cx,cy)
	local fixtureB=bodyB:getFixtureList()[1]
	--bodyB:resetMassData()
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

	local magB=helper.getProperty(b,"magnetField")
	local matB=helper.getProperty(b,"material")
	
	local parent = a:getBody():getFixtureList()[#a:getBody():getFixtureList()]

	if matB~="steel" and matB~="magnet" then return end
	local bodyA,bodyB=a:getBody(),b:getBody()
	local shapeA,shapeB=a:getShape(),b:getShape()
	local xA,yA= bodyA:getWorldPoint(shapeA:getPoint())
	local xB,yB

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

function func.destroyOnHit(threshold,a,b,c,np)
	
	if not threshold then return end
	if np<threshold then return end
	local func=function(a) 
		if a:isDestroyed() then return end
		a:getBody():destroy() 
	end
	table.insert(helper.system.todo,{func,a})
end

function func.scene(name)
	if not helper.editor then return end
	helper.editor.system:loadScene(name or "",true)
end

function func.creator(toggle,a,b,c)
	if not toggle then return end
	local x = helper.getProperty(a,"creatorX") or 0
	local y = helper.getProperty(a,"creatorY") or 0
	local body = helper.getProperty(a,"creatorBody")
	local data = body and helper.getStatus(body) or collMode.defaultObject()
	local func = function()
		helper.createWorld(helper.world,data,x,y)
	end
	table.insert(helper.system.todo,{func,true} )
end

local polygonClip = require "libs/polybool"

function func.destructor(toggle,a,b)
	if not toggle then return end
	if not helper.getProperty(b,"destruct") then return end

	local ball = {}
	local x,y=a:getShape():getPoint()
	local r = a:getShape():getRadius()*2
	for i=1,16 do
		table.insert(ball, a:getBody():getX()+x+r*math.sin(i*math.pi/8))
		table.insert(ball, a:getBody():getY()+y+r*math.cos(i*math.pi/8))
	end

	local target
	if b:getShape():getType()=="circle" then
		---
	else
		target={b:getBody():getWorldPoints( b:getShape():getPoints() )}
	end
	local rest = polygonClip(target,ball,"not")
	local tri = {}
	for i,v in ipairs(rest) do
		local test, res = pcall(love.math.triangulate,v)
		if test then
			for i,t in ipairs(res) do
				table.insert(tri,t)
			end		
		else
			b:getBody():destroy()
		end
	end

	local desBody = b:getBody()
	local function create()
		local destruct
		for i,v in ipairs(tri) do				
			destruct = true
			
			local test,re =pcall(love.physics.newPolygonShape,math.polygonTrans(-v[1],-v[2],0,1,v))
			if test then
				local body = love.physics.newBody(helper.world, v[1], v[2], "static")
				local shape=re
				local fixture = love.physics.newFixture(body, shape)			
				helper.setProperty(fixture,"meterial","wood")
				helper.setProperty(fixture,"destruct",true)				
			end
		end
		if destruct then 
			if not desBody:isDestroyed() then desBody:destroy() end 
		end
	end
	table.insert(helper.system.todo,{create})
end

function func.toPixel(toggle,a,b,c,np)
	if not toggle then return end
	
	local threshold = helper.getProperty(a,"toPixel_threshold") or 1
	if np<threshold then return end
	a = helper.getProperty(a,"subFixture") or a
	local scale = helper.getProperty(a,"toPixel_scale") or 10
	local shape = a:getShape()
	local body = a:getBody()
	local l,t,r,b = shape:computeAABB(body:getX(),body:getY(),body:getAngle())
	local pixelShape = love.physics.newPolygonShape(0,0,scale,0,scale,scale,0,scale)
	local outLine =  helper.getProperty(a,"fixturesOutline")
	local verts = outLine and {body:getWorldPoints(unpack(outLine))} or
		{body:getWorldPoints( shape:getPoints() )}


	local func=function()
		for x = l,r,scale do
			for y = t,b,scale do
				if math.pointTest(x,y,verts) then
					local body = love.physics.newBody(helper.world, x, y,"dynamic")
					local fixture = love.physics.newFixture(body, pixelShape)
					helper.setProperty(fixture,"meterial","wood")
				end
			end
		end

		if not body:isDestroyed() then 
			body:destroy()
		end	 
	end
	table.insert(helper.system.todo,{func})
end


local polyCut = require "libs/polygonCut"
function func.breakup(toggle,a,b,c,np)
	if not toggle then return end
	local threshold = helper.getProperty(a,"breakup_threshold") or 1
	if np<threshold then return end	
	a = helper.getProperty(a,"subFixture") or a
	local scale = helper.getProperty(a,"break_scale") or 100
	local shape = a:getShape()
	local body = a:getBody()
	local outLine =  helper.getProperty(a,"fixturesOutline")
	local verts = outLine and {body:getWorldPoints(unpack(outLine))} or
		{body:getWorldPoints( shape:getPoints() )}
	local r = 100

	local cx,cy = body:getPosition()
	local subshapes = {verts}
	local target
	for i = 1, np/scale do
		target = {}
		for i,v in ipairs(subshapes) do
			local angle = love.math.random()*2*math.pi
			local offx = love.math.random(-r,r)/2
			local offy = love.math.random(-r,r)/2
			local sx = cx + offx +2*r*math.sin(angle)
			local sy = cy + offy +2*r*math.cos(angle)
			local tx = cx + offx -2*r*math.sin(angle)
			local ty = cy + offy -2*r*math.cos(angle)
			local v1,v2 = polyCut(v,sx,sy,tx,ty)
			if v1 and v2 then
				table.insert(target,v1)
				table.insert(target,v2)
			else
				table.insert(target,v)
			end
		end
		subshapes = target
	end
	helper.setProperty(a,"breakup",false)

	if not target then return end

	local function create()
		for i,v in ipairs(target) do
			local cx,cy = math.getPolygonArea(v)
			if cx then
				local test , pshape = pcall(love.physics.newPolygonShape,math.polygonTrans(-cx,-cy,0,1,v))
				if test then
					local pbody = love.physics.newBody(helper.world, cx, cy, "dynamic")
					local pfixture = love.physics.newFixture(pbody, pshape)
					helper.setProperty(pfixture,"meterial","wood")
				end
			end
		end
		if not body:isDestroyed() then 
			body:destroy()
		end	 
	end

	table.insert(helper.system.todo,{create})
end


collMode.collisionType={
	begin={
		makeFrag=collMode.collisionFunc.spark,
		reverse=collMode.collisionFunc.reverse,
		explosion=collMode.collisionFunc.explosion,
		
		scenejumper=collMode.collisionFunc.scene,
		creator=collMode.collisionFunc.creator,
		destructor = collMode.collisionFunc.destructor
		},
	over={
		oneWay=collMode.collisionFunc.oneWayEnd,
		bullet=collMode.collisionFunc.bulletEnd,
	},
	pre={
		oneWay=collMode.collisionFunc.oneWayPre,
		bullet=collMode.collisionFunc.bulletPre,
		buoyancy=collMode.collisionFunc.buoyancy,
		magnetField=collMode.collisionFunc.magnet,
		--destroyOnHit=collMode.collisionFunc.destroyOnHit,
		--destructor = collMode.collisionFunc.destructor
		
	},
	post={
		crashable=collMode.collisionFunc.crash,
		embed=collMode.collisionFunc.embed,
		toPixel = collMode.collisionFunc.toPixel,
		breakup = collMode.collisionFunc.breakup,
		destroyOnHit=collMode.collisionFunc.destroyOnHit,
	}	
}

collMode.defaultObject=function() 
	local world = love.physics.newWorld(0,0)
	local body = love.physics.newBody(world,0,0,"dynamic")
	local shape = love.physics.newCircleShape(10)
	local fixture = love.physics.newFixture(body, shape)
	body:setUserData({prop="anticount",value=10})
	body:setLinearVelocity(love.math.random()*10,love.math.random()*10)
	helper.setProperty(fixture,"explosion",1000)
	helper.setProperty(fixture,"destroyOnHit",1)

	return helper.getWorldData({body})
end

collMode.collisions={
	makeFrag={
		{prop="makeFrag",value=500},
	},
	reverse={
		{prop="reverse",value=true},
	},
	explosion={
		{prop="explosion",value=1000},
	},
	destroyOnHit={
		{prop="destroyOnHit",value=1}
	},
	oneWay={
		{prop="oneWay",value=true},
	},
	buoyancy={
		{prop="buoyancy",value=1}
	},
	magnetField={
		{prop="magnetField",value=5000}
	},
	crashable={
		{prop="crashable",value=100},
		{prop="crashcombo",value=false}
	},
	embed={
		{prop="embed",value=500},
	},
	sceneJumper={
		{prop="scenejumper",value="edit!"}
	},
	creator = {
		{prop="creator",value = true},
		{prop="creatorX",value = 0},
		{prop="creatorY",value = 0},
		{prop="creatorBody",value = false}
	},
	destructor = {
		{prop="destructor",value = true},
	},
	toPixel = {
		{prop="toPixel",value = true},
		{prop="toPixel_threshold",value = 1}
	},
	breakup = {
		{prop="breakup",value = true},
		{prop="breakup_threshold",value = 1}
	}
}

return function(parent) 
	helper=parent
	helper.collMode=collMode
end