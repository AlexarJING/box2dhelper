local test={}
local editor


test.mouseMode="std" --or ball

test.pause=false
test.modeIndex=1
local mouseModes={"std","power","ball","key","scissor"}
local mouseType={
	love.mouse.getSystemCursor("arrow"),
	love.mouse.getSystemCursor("sizeall"),
	love.mouse.getSystemCursor("hand"),
	love.mouse.getSystemCursor("arrow"),
}

function test:new()
	editor.action="start testing"
	self.modeIndex = 1
	self.mouseMode = "std"

end

function test:release()
	editor.system:undo()
	editor.log:push("stop testing")
end


function test:update(dt)
	if self.mouseMode=="power" then
		self:dragForce()
	elseif self.mouseMode=="ball" then
		if love.mouse.isDown(1) then
			self.mouseBall.fixture:setSensor(true)
		else
			self.mouseBall.fixture:setSensor(false)
		end
		self.mouseBall.joint:setTarget(editor.mouseX,editor.mouseY)
	elseif self.mouseMode=="key" then
		self:downForce()
	elseif self.mouseMode == "scissor" then
		self:cutTest()
	end	
end

function test:togglePause()
	self.pause=not self.pause
end

function test:reset()
	editor.log:push("rest world")
	editor.system:redo()
end


local polyCut = require "libs/polygonCut"
local lastX,lastY
local function getLocalPoints(body,vert)
	local rt={}
	for i=1,#vert-1,2 do
		local x,y=body:getLocalPoint(vert[i],vert[i+1])
		table.insert(rt,x)
		table.insert(rt,y)
	end
	return rt
end

function test:cutTest()
	if love.mouse.isDown(1) and not lastX then
		lastX,lastY=editor.mouseX,editor.mouseY
	end

	if not love.mouse.isDown(1) and lastX then 

		----for joints
		local joints = editor.world:getJointList()
		local toTest = {}
		for i,v in ipairs(joints) do
			if v:getType() == "rope" then
				table.insert(toTest,v)
			end
		end

		for i,v in ipairs(toTest) do
			local x1,y1,x2,y2 = v:getAnchors()
			local source={x=x1,y=y1,tx=x2,ty=y2}
			local mouseLine = {x=lastX,y=lastY,tx=editor.mouseX,ty=editor.mouseY}
			local test = math.lineCross(source,mouseLine)
			if test then v:destroy() end
		end

		---------for fixtures-----
		for i,body in ipairs(editor.world:getBodyList()) do
			if not body:isDestroyed() then
				for i,fixture in ipairs(body:getFixtureList()) do
					if not fixture:isDestroyed() and fixture:getShape():getType() == "polygon" then
						local verts = {body:getWorldPoints( fixture:getShape():getPoints() )}
						local v1,v2 = polyCut(verts,lastX,lastY,editor.mouseX,editor.mouseY)		
						if v1 then
							for i,v in pairs({v1,v2}) do
								local x,y=v[1],v[2]
								local body = love.physics.newBody(editor.world, x, y,"dynamic")
								local test ,triangles =pcall(love.math.triangulate,v)
								if not test then print(triangles);break end
								local mainFixture
								for i,triangle in ipairs(triangles) do
									local verts=math.polygonTrans(-x, -y,0,1,triangle)
									local shape = love.physics.newPolygonShape(verts)
									local fixture = love.physics.newFixture(body, shape)
									editor.createMode:setMaterial(fixture,"wood")
									
									if i==1 then
										editor.helper.setProperty(fixture,"mainFixture",true)
										editor.helper.setProperty(fixture,"fixturesOutline",
											getLocalPoints(body,v))
										mainFixture=fixture
									else
										editor.helper.setProperty(fixture,"subFixture",mainFixture)
									end
									
								end
							end
							body:destroy()
						end
					end
				end
			end
		end

		lastX,lastY=nil,nil
	end

	
	

end

function test:toggleMouse()
	if editor.state ~= "test" then return end
	if mouseModes[self.modeIndex+1] then
		self.modeIndex=self.modeIndex+1
		
	else
		self.modeIndex=1
	end
	self.mouseMode = mouseModes[self.modeIndex]
	love.mouse.setCursor(mouseType[self.modeIndex])

	if self.mouseMode=="ball" then
		if not self.mouseball or self.mouseBall.world~=editor.world  then
			local body = love.physics.newBody(editor.world, editor.mouseX,editor.mouseY, "dynamic")
			body:setUserData({})
			local shape = love.physics.newCircleShape(0, 0, 10)
			local fixture = love.physics.newFixture(body, shape, 100)
			editor.helper.setProperty(fixture,"destructor",true)
			--fixture:setUserData({})
			local joint= love.physics.newMouseJoint(body, editor.mouseX,editor.mouseY)
			self.mouseBall={body=body,shape=shape,fixture=fixture,joint=joint,world=self.world,isDestroy=false}
		end
	elseif self.mouseBall then
		if not self.mouseBall.body:isDestroyed() then self.mouseBall.body:destroy() end
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
		self:applyTorque(-100000)
	end

	if love.keyboard.isDown("e") then
		self:applyTorque(100000)
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

	if lastX then
		love.graphics.line(editor.mouseX,editor.mouseY, lastX,lastY)
	end
	love.graphics.print(self.mouseMode.." mode",editor.mouseX+10,editor.mouseY+10,0,2,2)
end

return function(parent) 
	editor=parent
	return test
end