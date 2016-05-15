local vertex={}
local editor
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

function vertex:new()
	self:getVerts()
end

function vertex:getVerts()
	self.verts={}
	local x,y
	for i,body in ipairs(editor.world:getBodyList()) do
		for i,fix in ipairs(body:getFixtureList()) do
		
			local shape=fix:getShape()
			if shape:type()=="CircleShape"  then
				local sx,sy=shape:getPoint()
				x,y=body:getWorldPoint(shape:getRadius()+sx,sy)
				table.insert(self.verts, {type="radius",body=body,fixture=fix,x=x,y=y})
				if i==#body:getFixtureList() then
					x,y=body:getWorldPoint(sx,sy)
      				table.insert(self.verts, {type="center",body=body,fixture=fix,x=x,y=y})
      			end
			else
				local verts= {body:getWorldPoints(shape:getPoints())}
				for i= 1,#verts-1,2 do
					x,y = verts[i],verts[i+1]
					table.insert(self.verts, {type="normal",body=body,fixture=fix,x=x,y=y,index=i,verts=verts})
				end
			end
			
		end
		table.insert(self.verts, {type="center",body=body,fixture=nil,x=body:getX(),y=body:getY(),verts=nil})
	end

end

function vertex:inRect(tx,ty)
	if editor.mouseX==clamp(editor.mouseX,tx-3,tx+3) 
		and editor.mouseY==clamp(editor.mouseY,ty-3,ty+3) then
		return true
	end
end


function vertex:update()
	
	local down=love.mouse.isDown(1) and 1 
	down=down or (love.mouse.isDown(2) and 2)

	if down and not self.selectedVert then
		for i,v in ipairs(self.verts) do
			if vertex:inRect(v.x,v.y) then
				self.selectedVert=v
				break
			end
		end
		self.dragTX,self.dragTY=editor.mouseX,editor.mouseY
		self.downType=down
	elseif down and self.selectedVert then
		self.dragTX,self.dragTY=editor.mouseX,editor.mouseY
	elseif not down and self.selectedVert then
		if getDist(self.selectedVert.x,self.selectedVert.y,self.dragTX,self.dragTY)<5 then
		 	self.selectedVert=nil
			return 
		end
		local vType=self.selectedVert.type
		if vType=="radius" then
			self:changeR()
		elseif vType=="center" then
			self:rotate()
		elseif vType=="normal" then
			self:changeNormal()
		end
		self.selectedVert=nil
		self:getVerts()
	end
	return true
end

function vertex:changeR()
	local shape=self.selectedVert.fixture:getShape()
	local cx,cy = shape:getPoint()
	local bx,by = self.selectedVert.body:getPosition()
	local r=getDist(cx+bx,cy+by,self.dragTX,self.dragTY)
	local newShape = love.physics.newCircleShape(cx,cy,r)
	local newFixture= love.physics.newFixture(self.selectedVert.body,newShape)
	self.selectedVert.fixture:destroy()
	self.action="change radius"
end

function vertex:changeNormal()
	local body=self.selectedVert.body
	local offx,offy=body:getPosition()
	local shape=self.selectedVert.fixture:getShape()
	local shapeType=shape:getType()
	local verts=self.selectedVert.verts
	verts[self.selectedVert.index],verts[self.selectedVert.index+1]=self.dragTX,self.dragTY
	local newShape 
	if shapeType=="polygon" then
		newShape = love.physics.newPolygonShape(
		polygonTrans(-offx,-offy,0,1,verts) )
	elseif shapeType=="chain" then
		newShape = love.physics.newChainShape(false,
		polygonTrans(-offx,-offy,0,1,verts) )
	elseif shapeType=="edge" then
		newShape = love.physics.newEdgeShape(unpack(
		polygonTrans(-offx,-offy,0,1,verts)) )
	end
	local newFixture=love.physics.newFixture(body,newShape)
	self.selectedVert.fixture:destroy()
	self.action="translate vertex"
end

function vertex:rotate()
	local ifCopy
	if love.keyboard.isDown("lctrl") then 
		ifCopy=true 
	else
		ifCopy=false
	end

	local fixture=self.selectedVert.fixture
	local body=self.selectedVert.body
	local x,y =self.selectedVert.x,self.selectedVert.y
	
	
		if self.downType==1 then
			if ifCopy then
				local obj=editor.helper.getWorldData({body})
				editor.helper.createWorld(editor.world,obj)
			end
			local rotation=getRot(x,y,self.dragTX,self.dragTY)
			local angle=rotation-Pi/2
			body:setAngle(angle)
		else
			if ifCopy then
				local obj=editor.helper.getWorldData({body})
				editor.helper.createWorld(editor.world,obj)
			end
			local rotation=getRot(0,0,self.dragTX,self.dragTY)
			local bodyR= getRot(0,0,x,y)
			local rotation=getRot(0,0,self.dragTX,self.dragTY)
			local angle=body:getAngle()
			body:setAngle(angle+rotation-bodyR)
			body:setPosition(axisRot(x,y,rotation-bodyR))
		end
	

	
	self.action="rotate fixture"
end

function vertex:click()
	if not self.selectedVert then 
		editor.selector.selection=nil
		return 
	end
	self.selection=self.selectedVert.fixture and 
		self.selectedVert.fixture:getShape() or 
		self.selectedVert.body:getFixtureList()[1]:getShape()
	editor.selector.selection={self.selection}
end


function vertex:draw()
	
	for i,vert in ipairs(self.verts) do
		if vert.type=="center" then
			love.graphics.setColor(0, 255, 0, 255)
		else
			love.graphics.setColor(255, 0, 0, 255)
		end
		love.graphics.rectangle("fill", vert.x-3,vert.y-3, 6, 6)
	end
	
	if self.selectedVert then

		local vert=self.selectedVert
		if vert.type=="center" then
			love.graphics.setColor(0, 255, 0, 255)
		else
			love.graphics.setColor(255, 0, 0, 255)
		end

		
		local bx,by = vert.body:getPosition()
		local body = vert.body
		if vert.type=="radius" then
			local cx,cy = vert.fixture:getShape():getPoint()
			love.graphics.line(self.dragTX,self.dragTY,bx+cx,by+cy)
			love.graphics.circle("line", bx+cx, by+cy, math.getDistance(self.dragTX,self.dragTY,bx+cx,by+cy))
		elseif vert.type=="center" then
			local cx,cy=body:getPosition()
			local rotation
			if love.mouse.isDown(1) then
				rotation=getRot(cx,cy,self.dragTX,self.dragTY)-Pi/2
				love.graphics.line(self.dragTX,self.dragTY,cx,cy)
				love.graphics.push()
				love.graphics.translate(cx, cy)
				love.graphics.rotate(rotation)
				editor.helper.draw({body},nil,-cx,-cy,0)
				love.graphics.pop()
			else
				rotation=getRot(0,0,self.dragTX,self.dragTY)
				bodyR= getRot(0,0,cx,cy)
				editor.helper.draw({body},nil,0,0,rotation-bodyR)
			end
		else
			local shapeVerts=vert.verts
			local i = vert.index
			local nextIndex = shapeVerts[i+2] and i+2 or 1
			local prevIndex = shapeVerts[i-2] and i-2 or #shapeVerts-1
			love.graphics.line(shapeVerts[prevIndex],shapeVerts[prevIndex+1],self.dragTX,self.dragTY)
			love.graphics.line(shapeVerts[nextIndex],shapeVerts[nextIndex+1],self.dragTX,self.dragTY)
		end
	end
	
end



return function(parent) 
	editor=parent
	return vertex 
end