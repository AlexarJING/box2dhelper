local helper
local func={}

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
			fixture:setRestitution(1)
			local angle= love.math.random()*math.pi*2
			body:setLinearVelocity(math.sin(angle)*boomV,math.cos(angle)*boomV)
			fixture:setGroupIndex(-2)
			table.insert(frags, body)
		end
		a:getBody():destroy()
	end
	table.insert(helper.todo,{func,a,b,coll})
	local func=function()
		for i,v in ipairs(frags) do
			if not v:isDestroyed() then
				v:destroy()
			end
		end
	end
	addDelay(func,4)
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
				body:setLinearDumping(3)
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
				addDelay(func2,3)
			end
		end
	end
	table.insert(helper.todo,{func,a,b,coll})
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
	table.insert(helper.todo,{func,a,b,coll})
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
	table.insert(helper.todo,{func,a,b,coll})
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
				table.insert(verts, x+r*math.cos(i*math.pi/4))
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
	table.insert(helper.todo,{func,a,b,coll})
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





return function(parent) 
	helper=parent
	return func
end