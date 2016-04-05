function editor:toggleMouse()
	self.mouseBall.enable=not self.mouseBall.enable
	if self.mouseBall.enable then
		if self.mouseBall.world~=self.world then
			local body = love.physics.newBody(editor.world, 0, 0, "dynamic")
			local shape = love.physics.newCircleShape(0, 0, 10)
			local fixture = love.physics.newFixture(body, shape, 100)
			local joint= love.physics.newMouseJoint(body, 0, 0)
			self.mouseBall={body=body,shape=shape,fixture=fixture,joint=joint,world=self.world,enable=true}
		end
		self.mouseBall.fixture:setSensor(false)
	else
		self.mouseBall.fixture:setSensor(true)
		self.mouseBall.body:setPosition(0,0)
		self.mouseBall.body:setLinearVelocity(0,0)
	end

end

function editor:downForce()
	if love.keyboard.isDown("w") then
		self:applyForce(0,-100)
	end
	if love.keyboard.isDown("s") then
		self:applyForce(0,100)
	end

	if love.keyboard.isDown("a") then
		self:applyForce(-100,0)
	end	

	if love.keyboard.isDown("d") then
		self:applyForce(100,0)
	end

	if love.keyboard.isDown("q") then
		self:applyTorque(-10000)
	end

	if love.keyboard.isDown("e") then
		self:applyTorque(10000)
	end
end


function editor:applyForce(x,y)
	local objs=self:getSelected()
	if not objs then return end
	local body=objs[1][1].body
	body:applyForce(x*10,y*10)
end

function editor:applyTorque(t)
	local objs=self:getSelected()
	if not objs then return end
	local body=objs[1][1].body
	body:applyTorque(t*10)
end


function editor:dragForce()
	if not self.selection then return end
	if not self.dragForcing then
		if not self:mouseTest() then return end	
	end
	if love.mouse.isDown(1) and not self.dragForcing then
		self.dragForcing=true	
		self.dragOX,self.dragOY=self.selection[1][1].body:getPosition()
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif love.mouse.isDown(1) and self.dragForcing then
		self.dragOX,self.dragOY=self.selection[1][1].body:getPosition()
		self.dragTX,self.dragTY=mouseX,mouseY
		local dx,dy=self.dragTX-self.dragOX,self.dragTY-self.dragOY
		self:applyForce(dx,dy)
	elseif not love.mouse.isDown(1) and self.dragForcing then
		self.dragForcing=false
	end

	return self.dragForcing
end



function test:draw()
	if self.dragForcing then
		love.graphics.line(self.dragOX,self.dragOY,self.dragTX,self.dragTY)
	end
end