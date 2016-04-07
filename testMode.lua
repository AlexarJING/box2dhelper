local test={}
local editor


test.mouseMode="power" --or ball
test.mouseBall={}
test.pause=false

function test:new()

	if editor.state=="Test Mode" then
		editor.state="Edit Mode"
		editor.system:redo()
		editor.log:push("stop testing")
	else
		editor.state="Test Mode"
		editor.action="start testing"
	end
end

function test:update(dt)
	if self.mouseMode=="power" then
		self:dragForce()
	else
		self.mouseBall.joint:setTarget(editor.mouseX,editor.mouseY)
	end
	self:downForce()
end

function test:togglePause()
	self.pause=not self.pause
end

function test:reset()
	editor.log:push("rest world")
	editor.system:redo()
end

function test:toggleMouse()
	self.mouseMode=self.mouseMode=="power" and "ball" or "power"
	if self.mouseMode=="ball" then
		if self.mouseBall.world~=editor.world or self.mouseBall.isDestroy==true then
			local body = love.physics.newBody(editor.world, 0, 0, "dynamic")
			local shape = love.physics.newCircleShape(0, 0, 10)
			local fixture = love.physics.newFixture(body, shape, 100)
			local joint= love.physics.newMouseJoint(body, 0, 0)
			self.mouseBall={body=body,shape=shape,fixture=fixture,joint=joint,world=self.world,isDestroy=false}
		end
	else
		self.mouseBall.body:destroy()
		self.mouseBall.isDestroy=true
	end

end

function test:downForce()
	if love.keyboard.isDown("w") then
		self:applyForce(0,-1000)
	end
	if love.keyboard.isDown("s") then
		self:applyForce(0,1000)
	end

	if love.keyboard.isDown("a") then
		self:applyForce(-1000,0)
	end	

	if love.keyboard.isDown("d") then
		self:applyForce(1000,0)
	end

	if love.keyboard.isDown("q") then
		self:applyTorque(-10000)
	end

	if love.keyboard.isDown("e") then
		self:applyTorque(10000)
	end
end


function test:applyForce(x,y)
	local selection=editor.selector.selection
	if not selection then return end
	selection[1]:applyForce(x,y)
end

function test:applyTorque(t)
	local selection=editor.selector.selection
	if not selection then return end
	selection[1]:applyTorque(t)
end


function test:dragForce()
	local selection=editor.selector.selection
	if not selection then return end
	if not self.dragForcing then
		if not self:mouseTest() then return end	
	end
	local mouseX,mouseY=editor.mouseX,editor.mouseY
	if love.mouse.isDown(1) and not self.dragForcing then
		self.dragForcing=true	
		self.dragOX,self.dragOY=selection[1]:getPosition()
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif love.mouse.isDown(1) and self.dragForcing then
		self.dragOX,self.dragOY=selection[1]:getPosition()
		self.dragTX,self.dragTY=mouseX,mouseY
		local dx,dy=self.dragTX-self.dragOX,self.dragTY-self.dragOY
		self:applyForce(dx*20,dy*20)
	elseif not love.mouse.isDown(1) and self.dragForcing then
		self.dragForcing=false
	end
end

function test:mouseTest()
	local check=false
	for i,body in ipairs(editor.selector.selection) do
		for i,fix in ipairs(body:getFixtureList()) do
			if fix:testPoint( editor.mouseX, editor.mouseY ) then
				check=true
				break
			end
		end
	end
	return check
end


function test:draw()
	if self.dragForcing then
		love.graphics.line(self.dragOX,self.dragOY,self.dragTX,self.dragTY)
	end
end

return function(parent) 
	editor=parent
	return test
end