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
	local selection=editor.selector.selection
	if not selection or not #selection==2 then 
		editor.log:push("error:need 2 bodies")
		return 
	end
	local body=selection[1]
	local body2=selection[2]
	for i,joint in ipairs(body:getJointList()) do
		local bodyA,bodyB=joint:getBodies( )
		if bodyA==body and bodyB==body2 or bodyA==body2 and bodyB==body then
			joint:destroy()
			break
		end
	end
end

function edit:copy()
	local selection=editor.selector.selection
	if not selection then 
		editor.log:push("error:need at least 1 body")
		return 
	end
	editor.log:push("copy selection")
	self.copied=editor.helper.getWorldData(selection,selection[1]:getX(),selection[1]:getY())
end


function edit:paste()
	if not self.copied then return end
	editor.action="paste " .. #self.copied.obj .." body(s)"
	local add=editor.helper.createWorld(editor.world,self.copied,mouseX,mouseY)
	editor.selector.selection={}
	for i,v in ipairs(add) do
		table.insert(editor.selector.selection, v.body)
	end
end

function edit:removeBody()
	local selection=editor.selector.selection
	if not selection then 
		editor.log:push("error:need at least 1 body")
		return 
	end
	for i,v in ipairs(selection) do
		v:destroy()
	end
	editor.action="delect selected body"
	editor.selector.selection=nil

end

function edit:combine()
	local selection=editor.selector.selection
	if not selection or #selection<2 then 
		editor.log:push("error:need at least 2 body")
		return 
	end
	editor.action="combine objects"
	local target=selection[1]
	for i= 2,#selection do
		local body=selection[i]
		local shape
		local shapeType
		local offx,offy=target:getX()-body:getX(),target:getY()-body:getY()
		for i,fixture in ipairs(body:getFixtureList()) do
			shape=fixture:getShape()
			shapeType=shape:type()
			if shapeType =="CircleShape" then
				shape = love.physics.newCircleShape( -offx, -offy, shape:getRadius())
			elseif shapeType =="ChainShape" then
				shape = love.physics.newChainShape("false", polygonTrans(-offx,-offy,0,1,{shape:getPoints()}))
			else
				shape = love.physics["new"..shapeType](polygonTrans(-offx,-offy,0,1,{shape:getPoints()}))
			end
			fixture:destroy()
			love.physics.newFixture(target, shape)
		end

		body:destroy()
	end
	editor.selector.selection={target}
end

function edit:divide()
	local selection=editor.selector.selection
	if not selection or #selection~=1 then 
		editor.log:push("error:need 1 body")
		return 
	end

	local tBody=selection[1]
	local x,y = tBody:getPosition()
	for i,fixture in ipairs(tBody:getFixtureList()) do
		local cx,cy = fixture:getMassData()
		local offx,offy= cx+x,cy+y
		local body = love.physics.newBody(editor.world, offx, offy, tBody:getType())
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
		love.physics.newFixture(body, shape)
	end
	editor.selector.selection=nil
	tBody:destroy()
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





--local bodyType={"static","dynamic","kinematic"}

function edit:toggleBodyType()
	local selection=editor.selector.selection
	if not selection then 
		editor.log:push("error:need at least 1 body")
		return 
	end

	

	for i,body in ipairs(editor.selector.selection) do
		local bType=body:getType()
		if bType=="static" then
			body:setType("dynamic")
		elseif bType=="dynamic" then
			body:setType("kinematic")
		else
			body:setType("static")
		end
	end

	editor.action="toggle body type"
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