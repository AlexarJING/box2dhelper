local edit={}
local editor
local mouseX,mouseY
local selection

function edit:update()
	selection=editor.selector.selection
	mouseX,mouseY=editor.mouseX,editor.mouseY
	self:dragMove()
end


function edit:aline(isVerticle)
	editor.action="aline,".."isVerticle:"..tostring(isVerticle)
	if not selection then return end
	local alineX,alineY =selection[1]:getPosition()
	for i,body in ipairs(selection) do
		if isVerticle then
			body:setY(alineY)
		else
			body:setX(alineX)
		end		
	end
end

function edit:removeJoint()
	editor.action="remove joint"
	if not self.selection or not #self.selection==2 then return end
	local body=self.selection[1][1].body
	local body2=self.selection[2][1].body
	for i,joint in ipairs(body:getJointList()) do
		local bodyA,bodyB=joint:getBodies( )
		if bodyA==body and bodyB==body2 or bodyA==body2 and bodyB==body then
			joint:destroy()
			break
		end
	end
end

function edit:rotate()
	if not self.selection then return end
	local body=self.selection[1][1].body
	if not self.rotateO and love.mouse.isDown(1) then
		local x,y = body:getPosition()
		self.rotateO=getRot(x,y,mouseX,mouseY)
	elseif self.rotateO and love.mouse.isDown(1) then
		local x,y = body:getPosition()
		self.rotateT= getRot(x,y,mouseX,mouseY)
		local rotate=self.rotateT-self.rotateO
		local angle=body:getAngle()+rotate
		body:setAngle(angle)
		self.rotateO=self.rotateT
	elseif self.rotateO and not love.mouse.isDown(1) then
		self.rotateO=nil
		editor.action="rotate by body center"
	end

	if not self.rotateO_0 and love.mouse.isDown(2) then
		local x,y = body:getPosition()
		self.rotateO_0=getRot(0,0,mouseX,mouseY)
	elseif self.rotateO_0 and love.mouse.isDown(2) then
		local x,y = body:getPosition()
		self.rotateT_0= getRot(0,0,mouseX,mouseY)
		local rotate=self.rotateT_0-self.rotateO_0
		local angle=body:getAngle()+rotate
		body:setAngle(angle)
		body:setPosition(axisRot(x,y,rotate))
		self.rotateO_0=self.rotateT_0
	elseif self.rotateO_0 and not love.mouse.isDown(2) then
		self.rotateO_0=nil
		editor.action="rotate by 0,0"
	end
end

function edit:duplicate()
	if not love.keyboard.isDown("lctrl") then return end
	local tab=self:getSelected()
	if not tab then return end
	editor.action="copy selected object"
	local selection={}
	for i,objs in ipairs(tab) do
		local obj = objs[1]
		local body = love.physics.newBody(self.world, obj.body:getX()+50, obj.body:getY()+50, obj.body:getType())
		local shape,fixture
		for i,v in ipairs(obj.body:getFixtureList()) do
			shape= v:getShape()
			fixture = love.physics.newFixture(body, shape)
			table.insert(self.objects, {
				body=body,
				shape=shape,
				fixture=fixture
				})
		end
		
		table.insert(selection, {self.objects[#self.objects]})
	end
	self:clearSelection()
	self.selection=selection
	for i=1,#selection do
		self.selection[i][1].body:setUserData(true)
	end
end

function edit:delete()
	if self.selection and self.selection[#self.selection][self.selectIndex] then
		for i=1,#self.selection-1 do
			if not self.selection[i][1].body:isDestroyed() then 
				self.selection[i][1].body:destroy()
			end
			table.removeItem(self.objects,self.selection[i][1])
		end
		if self.selection[#self.selection][self.selectIndex].body:getUserData() then
			self.selection[#self.selection][self.selectIndex].body:destroy()
			table.removeItem(self.objects,self.selection[#self.selection][self.selectIndex])
		end

	end
	editor.action="delect selected object"
	self.selection=nil
	self.selectIndex=1
end

function edit:combine()
	local objs=self:getSelected()
	if not objs then return end
	editor.action="combine objects"
	local target=objs[1][1]
	for i= 2,#objs do
		local obj=objs[i][1]
		local shape
		local offx,offy=target.body:getX()-obj.body:getX(),target.body:getY()-obj.body:getY()
		local shapeType=obj.shape:type()
		if shapeType =="CircleShape" then
			shape = love.physics.newCircleShape( -offx, -offy, obj.shape:getRadius())
		elseif shapeType =="ChainShape" then
			shape = love.physics.newChainShape("false", polygonTrans(-offx,-offy,0,1,{obj.shape:getPoints()}))
		else
			shape = love.physics["new"..shapeType](polygonTrans(-offx,-offy,0,1,{obj.shape:getPoints()}))
		end
		obj.fixture:destroy()
		obj.shape=shape
		obj.fixture = love.physics.newFixture(target.body, shape)
		obj.body:destroy()
		obj.body=target.body
		table.removeItem(self.objects,objs[i])
		self:clearSelection()
	end
end

function edit:divide()
	editor.action="divide object"
	local objs=self:getSelected()
	if not objs then return end
	if not self.selection then return end
	local target=objs[1][1]
	local tBody=target.body
	local x,y = tBody:getPosition()
	for i,fixture in ipairs(tBody:getFixtureList()) do
		local cx,cy = fixture:getMassData()
		local offx,offy= cx+x,cy+y
		local body = love.physics.newBody(self.world, offx, offy, tBody:getType())
		local shape =fixture:getShape()
		local shapeType= shape:getType()
		if shapeType =="circle" then
			local tx,ty=shape:getPoint()
			shape = love.physics.newCircleShape( cx-tx, cy-ty, shape:getRadius())
		elseif shapeType =="chain" then
			shape = love.physics.newChainShape("false", polygonTrans(offx,offy,0,1,{shape:getPoints()}))
		elseif shapeType=="polygon" then
			shape = love.physics.newPolygonShape(polygonTrans(offx,offy,0,1,{shape:getPoints()}))
		elseif shapeType=="edge" then
			shape = love.physics.newEdgeShape(polygonTrans(offx,offy,0,1,{shape:getPoints()}))
		end
		local fixture  = love.physics.newFixture(body, shape)
		table.insert(self.objects, {body=body,shape=shape,fixture=fixture})
	end
	self:clearSelection()
	tBody:destroy()
	table.removeItem(self.objects,objs[1][1])
end


function edit:dragMove()
	if not editor.selector.selection then return end
	if not self.dragMoving then
		if not self:mouseTest() then return end	
	end

	if love.mouse.isDown(1) and not self.dragMoving then
		self.dragMoving=true	
		self.dragOX,self.dragOY=mouseX,mouseY
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif love.mouse.isDown(1) and self.dragMoving then
		local dx,dy=mouseX-self.dragTX,mouseY-self.dragTY
		self:move(dx,dy)
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif not love.mouse.isDown(1) and self.dragMoving then
		print(2)
		local dx,dy=mouseX-self.dragTX,mouseY-self.dragTY
		self:move(dx,dy,true)
		self.dragMoving=false
		editor.action="move"
	end

	return self.dragMoving
end

function edit:move(dx,dy,throw)
	local selection=editor.selector.selection
	for i,body in ipairs(selection) do
		
		local x,y = body:getPosition()

		if throw then
			local dt = love.timer.getDelta()
			body:setLinearVelocity( dx/dt, dy/dt )
		else
			body:setLinearVelocity(0,0)
			body:setAngularVelocity(0,0)
		end
		body:setPosition(x+dx,y+dy)
	end
end


function edit:inRect(x,y)
	if x==clamp(x,self.dragOX,self.dragTX) 
		and y==clamp(y,self.dragOY,self.dragTY) then
		return true
	end
end



function edit:inRect2(tx,ty)
	if mouseX==clamp(mouseX,tx-3,tx+3) 
		and mouseY==clamp(mouseY,ty-3,ty+3) then
		return true
	end
end


function edit:fix()
	editor.action="toggle static/dynamic"
	if not self.selection then return end
	if not #self.selection==1 then return end
	if self.selection[1][1].body:getType()=="dynamic" then
		self.selection[1][1].body:setType("static")
	else
		self.selection[1][1].body:setType("dynamic")
	end
end

function edit:mouseTest()
	local check=false
	for i,body in ipairs(editor.selector.selection) do
		for i,fix in ipairs(body:getFixtureList()) do
			if fix:testPoint( mouseX, mouseY ) then
				check=true
				break
			end
		end
	end
	return check
end

return function(parent) 
	editor=parent
	return edit
end