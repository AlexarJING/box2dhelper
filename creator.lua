local editor={}

function editor:getPoints()
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= mouseX,mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createR=0
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=mouseX,mouseY
		self.createR = getDist(self.createOX,self.createOY,self.createTX,self.createTY)
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
		self.createOX=nil
		self.createOY=nil
		self.createTX=nil
		self.createTY=nil
	end
end

function editor:getVerts()
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= mouseX,mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createVerts={self.createOX,self.createOY}
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=mouseX,mouseY
		if love.mouse.isDown(2) and not self.rIsDown then
			self.rIsDown=true
			table.insert(self.createVerts, self.createTX)
			table.insert(self.createVerts, self.createTY)
		elseif not love.mouse.isDown(2) then
			self.rIsDown=false
		end
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
		self.createOX=nil
		self.createOY=nil
		self.createTX=nil
		self.createTY=nil
	end
end

function editor:freeDraw()
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= mouseX,mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createVerts={self.createOX,self.createOY}
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=mouseX,mouseY
		local dist=getDist(self.createTX,self.createTY,self.createVerts[#self.createVerts-1],self.createVerts[#self.createVerts])
		if dist>3 then
			table.insert(self.createVerts, self.createTX)
			table.insert(self.createVerts, self.createTY)
		end
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
		self.createOX=nil
		self.createOY=nil
		self.createTX=nil
		self.createTY=nil
	end


end


function editor:circle()
	self.action="create circle"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"dynamic")
	local shape = love.physics.newCircleShape(self.createR)
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	return {body=body,shape=shape,fixture=fixture}
end

function editor:box()
	self.action="create box"
	local body = love.physics.newBody(self.world, (self.createOX+self.createTX)/2, 
		(self.createTY+self.createOY)/2,"dynamic")
	local shape = love.physics.newRectangleShape(math.abs(self.createOX-self.createTX),math.abs(self.createTY-self.createOY))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	return {body=body,shape=shape,fixture=fixture}
end

function editor:line()
	self.action="create line"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newEdgeShape(0,0,self.createTX-self.createOX,self.createTY-self.createOY)
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	sensor = love.physics.newFixture(body, shape)
	sensor:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end

function editor:edge()
	if #self.createVerts<6 then return end
	self.action="create edge"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newChainShape(false, polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	fixture = love.physics.newFixture(body, shape)
	fixture:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end

function editor:freeLine()
	if #self.createVerts<6 then return end
	self.action="create freeline"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newChainShape(false, polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	fixture = love.physics.newFixture(body, shape)
	fixture:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end




function editor:polygon()
	if #self.createVerts<6 then return end
	if #self.createVerts>16 then
		for i=16,#self.createVerts do
			self.createVerts[i]=nil
		end
	end
	self.action="create polygon"	
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"dynamic")
	local shape = love.physics.newPolygonShape(polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	local x,y=body:getWorldPoint(fixture:getMassData( ))
	body:destroy()
	local body = love.physics.newBody(self.world, x, y,"dynamic")
	local shape = love.physics.newPolygonShape(polygonTrans(-x, -y,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	return {body=body,shape=shape,fixture=fixture}
end

function editor:getBodies()
	if not self.selection then return end
	local body1,body2,check
	for i,tab in ipairs(self.selection) do
		local obj
		if i==#self.selection then
			obj=tab[self.selectIndex]
		else
			obj=tab[1]
		end
		if not body1 then 
			body1=obj.body 
		elseif not body2 then 
			body2=obj.body
		elseif not check then
			check=obj.body:getUserData()
			break
		end
	end
	if body1 and body2 and not check then 
		return body1,body2 
	end
end

function editor:rope()
	
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create rope joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint=love.physics.newRopeJoint(body1, body2, x1, y1, x2, y2, getDist(x1, y1, x2, y2), false)
	return joint
end

function editor:distance()
	
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create distance joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint = love.physics.newDistanceJoint(body1, body2, x1, y1, x2, y2, false)
	joint:setFrequency(10)
end

function editor:weld()
	
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create weld joint"
	local x1,y1 = body1:getPosition()
	local joint = love.physics.newWeldJoint(body1, body2, x1, y1, false)
	joint:setFrequency(10)
end

function editor:prismatic()
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create prismatic joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local angle= getRot(x1,y1,x2,y2)
	local joint = love.physics.newPrismaticJoint(body1, body2, x2, y2, math.sin(angle), -math.cos(angle), false)
	--joint:setLimits(-90,50)
end

function editor:revolute()
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create revolute joint"
	local x,y = body2:getPosition()
	local joint = love.physics.newRevoluteJoint(body1, body2, x, y, false)
end

function editor:pully()
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create pully joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint = love.physics.newPulleyJoint(body1, body2, x1, y1-200, x2, y2-200, x1, y1, x2, y2, 1, false)
end

function editor:wheel()
	local body2,body1=self:getBodies()
	if not body1 then return end
	self.action="create wheel joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local angle= getRot(x1,y1,x2,y2)
	local joint = love.physics.newWheelJoint(body2, body1, x1, y1, math.sin(angle), -math.cos(angle), false)
end