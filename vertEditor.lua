function editor:vertMode()
	if not love.keyboard.isDown("lalt") then return end
	if not self.selection then return end
	if not #self.selection==1 then return end
	if love.mouse.isDown(1) and not self.selectedVert then
		if self.selection[1][1].shape:type()=="CircleShape" then
			self.selectedVerts= {self.selection[1][1].body:getWorldPoint(self.selection[1][1].shape:getRadius(),0)}
			local x,y = self.selectedVerts[1],self.selectedVerts[2]
			if self:inRect2(x,y) then
				self.selectedVert=1
			end
		else
			self.selectedVerts= {self.selection[1][1].body:getWorldPoints(self.selection[1][1].shape:getPoints())}
			for i= 1,#self.selectedVerts-1,2 do
				local x,y = self.selectedVerts[i],self.selectedVerts[i+1]
				if self:inRect2(x,y) then
					self.selectedVert=i
					break
				end
			end
		end
	elseif love.mouse.isDown(1) and self.selectedVert then
		self.selectedVerts[self.selectedVert],self.selectedVerts[self.selectedVert+1]=mouseX,mouseY
	elseif not love.mouse.isDown(1) and self.selectedVert then

		self.selection[1][1].fixture:destroy()
		local shape,fixture
		if self.selection[1][1].shape:type()=="CircleShape" then
			local r=getDist(self.selection[1][1].body:getX(),self.selection[1][1].body:getY(),
				self.selectedVerts[1],self.selectedVerts[2])
			shape = love.physics.newCircleShape(0,0,r)
		else
			shape = love.physics.newPolygonShape(
			polygonTrans(
				-self.selection[1][1].body:getX(),
				-self.selection[1][1].body:getY()
				,0,1,self.selectedVerts)
			)
		end
		
		fixture = love.physics.newFixture(self.selection[1][1].body,shape)
		self.selection[1][1].shape=shape
		self.selection[1][1].fixture=fixture
		self.selectedVert=nil
		self.action="change verticles"
	end
	return true
end


function vert:draw()
	for i,body in ipairs(self.world:getBodyList()) do
		local color={0,255,0,255}
		local bodyX=body:getX()
		local bodyY=body:getY()
		local bodyAngle=body:getAngle()
		for i,fixture in ipairs(body:getFixtureList()) do
			local shape=fixture:getShape()
			local shapeType = shape:type()
			local shapeR=shape:getRadius()
			love.graphics.setColor(color)
			if shapeType=="CircleShape" then
				love.graphics.rectangle("line", bodyX-3,bodyY-3, 6, 6)
				love.graphics.rectangle("line", bodyX+math.cos(bodyAngle)*shapeR-3,bodyY+math.sin(bodyAngle)*shapeR-3, 6, 6)
			else
				local verts={shape:getPoints()}
				for i= 1,#verts-1,2 do
					local x,y = body:getWorldPoint(verts[i],verts[i+1])
					love.graphics.rectangle("line", x-3,y-3, 6, 6)
				end
			end
		end
	end

	if self.selectedVert then 
		
		local x,y= self.selectedVerts[self.selectedVert],self.selectedVerts[self.selectedVert+1]
		
		if self.selection[1][1].shape:type()=="CircleShape" then 
			love.graphics.line(self.selection[1][1].body:getX(),self.selection[1][1].body:getY(),x,y)

		else
			if self.selectedVert-2<1 then
				love.graphics.line(x,y,self.selectedVerts[#self.selectedVerts-1],self.selectedVerts[#self.selectedVerts])
			else
				love.graphics.line(x,y,self.selectedVerts[self.selectedVert-2],self.selectedVerts[self.selectedVert-1])
			end

			if self.selectedVert+2>#self.selectedVerts-1 then
				love.graphics.line(x,y,self.selectedVerts[1],self.selectedVerts[2])
			else
				love.graphics.line(x,y,self.selectedVerts[self.selectedVert+2],self.selectedVerts[self.selectedVert+3])
			end

		end
		
		love.graphics.rectangle("line", x, y, 6, 6)
	end

end