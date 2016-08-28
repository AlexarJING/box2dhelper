local test={}
local editor


test.mouseMode="std" --or ball

test.pause=false
test.modeIndex=1
local mouseModes={"std","power","ball","key","create"}
local mouseType={
	love.mouse.getSystemCursor("arrow"),
	love.mouse.getSystemCursor("sizeall"),
	love.mouse.getSystemCursor("hand"),
	love.mouse.getSystemCursor("arrow"),
}

function test:new()
	editor.action="start testing"
end

function test:release()
	editor.system:undo()
	editor.log:push("stop testing")
end


function test:update(dt)
	if self.mouseMode=="power" then
		self:dragForce()
	elseif self.mouseMode=="ball" then
		self.mouseBall.joint:setTarget(editor.mouseX,editor.mouseY)
	elseif self.mouseMode=="key" then
		self:downForce()
	elseif self.moseMode=="create" then
		editor.createMode:update()
	end	
end

function test:togglePause()
	self.pause=not self.pause
end

function test:reset()
	editor.log:push("rest world")
	editor.system:redo()
end



function test:toggleMouse()
	
	if mouseModes[self.modeIndex+1] then
		self.modeIndex=self.modeIndex+1
		
	else
		self.modeIndex=1
	end
	self.mouseMode = mouseModes[self.modeIndex]
	love.mouse.setCursor(mouseType[self.modeIndex])

	if self.mouseMode=="ball" then
		if not self.mouseball or self.mouseBall.world~=editor.world  then
			local body = love.physics.newBody(editor.world, 0, 0, "dynamic")
			body:setUserData({})
			local shape = love.physics.newCircleShape(0, 0, 10)
			local fixture = love.physics.newFixture(body, shape, 100)
			fixture:setUserData({})
			local joint= love.physics.newMouseJoint(body, 0, 0)
			self.mouseBall={body=body,shape=shape,fixture=fixture,joint=joint,world=self.world,isDestroy=false}
		end
	elseif self.mouseBall then
		self.mouseBall.body:destroy()
		self.mouseBall=nil
	end

end

function test:downForce()
	if love.keyboard.isDown("w") then
		self:applyForce(0,-5000)
	end
	if love.keyboard.isDown("s") then
		self:applyForce(0,5000)
	end

	if love.keyboard.isDown("a") then
		self:applyForce(-5000,0)
	end	

	if love.keyboard.isDown("d") then
		self:applyForce(5000,0)
	end

	if love.keyboard.isDown("q") then
		self:applyTorque(-50000)
	end

	if love.keyboard.isDown("e") then
		self:applyTorque(50000)
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
	if not selection then self.dragForcing = false;return end
	if not self.dragForcing and not not self:mouseTest() then
		return
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
		self:applyForce(dx*200,dy*200)
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
	love.graphics.setColor(255, 255, 255, 255)
	if self.dragForcing then
		love.graphics.line(self.dragOX,self.dragOY,self.dragTX,self.dragTY)
	end
	love.graphics.print(self.mouseMode.." mode",editor.mouseX+10,editor.mouseY+10,0,2,2)
end

return function(parent) 
	editor=parent
	return test
end