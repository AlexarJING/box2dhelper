local edit={} --to edit positions change name to body mode
local editor
local mouseX,mouseY
local selection

local clamp= function (a,low,high)
	if low>high then 
		return math.max(high,math.min(a,low))
	else
		return math.max(low,math.min(a,high))
	end
end
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



function edit:new()
	
end

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
		if joint:getType()=="gear" or bodyA==body and bodyB==body2 or bodyA==body2 and bodyB==body then
			editor.jointMode:removeJoint(joint)
		end
	end
end

function edit:copy()
	local selection=editor.selector.selection
	if not selection or selection[1]:type()~="Body" then 
		editor.log:push("error:need at least 1 body")
		return 
	end
	editor.log:push("copy selection")
	self.copied=editor.helper.getWorldData(selection,selection[1]:getX(),selection[1]:getY())
end


function edit:paste(x,y)
	if not self.copied then return end
	x=x or mouseX
	y=y or mouseY
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
	editor.selector.selection={}
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
			shape = love.physics.newPolygonShape(polygonTrans(-cx,-cy,0,1,{shape:getPoints()}))
		elseif shapeType=="edge" then
			shape = love.physics.newEdgeShape(polygonTrans(offx,offy,0,1,{shape:getPoints()}))
		end
		local fix = love.physics.newFixture(body, shape)
		editor.createMode:setMaterial(fix,"wood")
		table.insert(editor.selector.selection,body)
	end
	
	editor.action = "divide body fixtures"

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
		if love.keyboard.isDown("lctrl") then 
			self.dragCopy=true 
			self.dragCopyObj=editor.helper.getWorldData(editor.selector.selection)
		else
			self.dragCopy=false 
			self.dragCopyObj=nil
		end
	elseif love.mouse.isDown(1) and self.dragMoving then
		local dx,dy=mouseX-self.dragTX,mouseY-self.dragTY
		self:move(dx,dy)
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif not love.mouse.isDown(1) and self.dragMoving then
		local dx,dy=mouseX-self.dragTX,mouseY-self.dragTY
		
		if self.dragCopy then
			if self.dragOX~=self.dragTX or self.dragOY~=self.dragTY then
				editor.helper.createWorld(editor.world,self.dragCopyObj)
			end
			self.dragCopy=false 
			self.dragCopyObj=nil
		end

		self:move(dx,dy,true)
		self.dragMoving=false
		editor.action="move"
	end

	return self.dragMoving
end

function edit:draw()
	if self.dragCopy then
		editor.helper.draw(editor.selector.selection,_,self.dragOX-self.dragTX,self.dragOY-self.dragTY)
	end
end


function edit:move(dx,dy,throw)
	local selection=editor.selector.selection

	for i,body in ipairs(selection) do
		
		local x,y = body:getPosition()

		if throw then
			local dt = love.timer.getDelta()
			body:setLinearVelocity( dx/dt, dy/dt )
		else
			--body:setLinearVelocity(0,0)
			--body:setAngularVelocity(0,0)
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

function edit:clear()
	editor.world =love.physics.newWorld(0, 9.8*64, false)
	editor.action = "clear the world"
end



return function(parent) 
	editor=parent
	return edit
end