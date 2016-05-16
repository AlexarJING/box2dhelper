local creator={} --to create objects joints
local editor
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
local clamp= function (a,low,high)
	if low>high then 
		return math.max(high,math.min(a,low))
	else
		return math.max(low,math.min(a,high))
	end
end

local Softbody=require "editor/softbody"


function creator:update()
	self:getPoint()
	self:getPoints()
	self:getVerts()
	self:freeDraw()
end

function creator:new(cType)
	self.oState=editor.state
	editor:cancel()
	if not editor.state then return end
	editor.state="create"
	self.createTag=cType
	if cType=="circle" or cType=="box" 
		or cType=="line" or cType=="softrope" 
		or cType=="softcircle" or ctype=="softbox"
		or cType=="explosion"
		then
		self.needPoints=true
	elseif cType=="freeline" then
		self.needLines=true
	elseif cType=="water" then
		self.needPoint=true
	else
		self.needVerts=true
	end

end

function creator:draw()
	love.graphics.setColor(255, 255, 255, 255)
	if self.createTag then
		love.graphics.print("creating "..self.createTag, editor.mouseX+5,editor.mouseY+5,0,2,2)
	end

	if self.createOX then
		if self.createTag=="circle" or self.createTag=="softcircle" or self.createTag=="explosion"then
			love.graphics.circle("line", self.createOX, self.createOY, self.createR)
			love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
		elseif self.createTag=="box" or self.createTag=="softbox" then
			love.graphics.polygon("line",
				self.createOX,self.createOY,
				self.createOX,self.createTY,
				self.createTX,self.createTY,
				self.createTX,self.createOY)
		elseif self.createTag=="line" or self.createTag=="softrope" then
			love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
		elseif self.createTag=="edge" or self.createTag=="freeline" then
			if not self.createVerts then return end
			for i=1,#self.createVerts-3,2 do
				love.graphics.line(self.createVerts[i],self.createVerts[i+1],self.createVerts[i+2],self.createVerts[i+3])
			end
			love.graphics.line(self.createVerts[#self.createVerts-1],self.createVerts[#self.createVerts],self.createTX,self.createTY)

		elseif self.createTag=="polygon" or self.createTag=="softpolygon" then
			if not self.createVerts then return end
			local count=#self.createVerts
			if count==0 then
				love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
			elseif count==2 then
				love.graphics.line(self.createOX,self.createOY,self.createVerts[1],self.createVerts[2])
				love.graphics.line(self.createVerts[1],self.createVerts[2],self.createTX,self.createTY)
				love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
			else
				
				love.graphics.line(self.createOX,self.createOY,self.createVerts[1],self.createVerts[2])
				for i=1,count-3,2 do
					love.graphics.line(self.createVerts[i],self.createVerts[i+1],self.createVerts[i+2],self.createVerts[i+3])
				end
				love.graphics.line(self.createVerts[count-1],self.createVerts[count],self.createTX,self.createTY)
				love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
			end
		end
	end

end

createTimer=0
createCD=20

function creator:getPoint()
	if not self.needPoint then return end
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= editor.mouseX,editor.mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=editor.mouseX,editor.mouseY
		createTimer=createTimer-1
		if createTimer<0 then
			self:water()
		end
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
		editor.action="create water"
	end
end


function creator:importFromImage(file)
	
	local name=string.stripfilename(file:getFilename())
	love.filesystem.createDirectory("texture")
	local file2 = love.filesystem.newFile("texture/"..name)
	file2:open("w")
	file2:write(file:read())
	file2:close()

	local Point    = editor.Delaunay.Point
	local points = {}
	local test,imageData = pcall(love.image.newImageData,file)
	local imageW = imageData:getWidth()
	local imageH = imageData:getHeight()

	local rate=imageW/32 > 1 and math.ceil(imageW/32) or 1
	local threshold= imageW/10
	function sample( x, y, r, g, b, a )
	   if x%rate==0 and y%rate==0 then
	   		if a~=0 then table.insert(points,Point(x,y)) end
	   end
	   return r,g,b,a
	end
	 
	imageData:mapPixel(sample)
	local image = love.graphics.newImage(imageData)
	
	local triangles = editor.Delaunay.triangulate(points)

	for i=#triangles,1,-1 do
		if triangles[i]:getCircumRadius()>threshold then
			table.remove(triangles, i)
		end
	end


	local edges={}
	for i,t in ipairs(triangles) do
		table.insert(edges,t.e1)
		table.insert(edges,t.e2)
		table.insert(edges,t.e3)
	end


	for i,t in ipairs(triangles) do
		
		for j,e in ipairs(edges) do
			if t.e1:same(e) and e~=t.e1 then
				table.remove(edges, j)	
				break
			end
		end
		
		for j,e in ipairs(edges) do
			if t.e2:same(e) and e~=t.e2 then
				table.remove(edges, j)
				break
			end
		end

		for j,e in ipairs(edges) do
			if t.e3:same(e) and e~=t.e3 then
				table.remove(edges, j)	
				break
			end
		end
	end

	local target={}
	table.remove(edges, 1)
	while #edges~=0 do
		local verts={edges[1].p1.x,edges[1].p1.y,edges[1].p2.x,edges[1].p2.y}
			table.insert(target, verts)
		repeat
			local test
			for i,e in ipairs(edges) do
				if e.p1.x==verts[#verts-1] and e.p1.y==verts[#verts] then
					table.insert(verts, e.p2.x)
					table.insert(verts, e.p2.y)
					table.remove(edges, i)
					test=true
					break
				end

				if e.p2.x==verts[#verts-1] and e.p2.y==verts[#verts] then
					table.insert(verts, e.p1.x)
					table.insert(verts, e.p1.y)
					table.remove(edges, i)
					test=true
					break
				end
			end
			
		until not test or #edges==0
		
		if not(verts[#verts-1]==verts[1] and verts[#verts]==verts[2]) then
			local x,y=verts[1],verts[2]
			verts[1],verts[2]=verts[3],verts[4]
			verts[3],verts[4]=x,y
		end
	end


	local body = love.physics.newBody(editor.world, 0, 0, "dynamic")
	body:setUserData({})
	table.insert(body:getUserData(), {prop="texture",value=image})
	table.insert(body:getUserData(), {prop="texturePath",value="texture/"..name})
	for i,v in ipairs(target) do
		local test,triangles = pcall(love.math.triangulate,v)
		if test then
			for i,v in ipairs(triangles) do
				local rt,shape = pcall(love.physics.newPolygonShape,
					math.polygonTrans(-imageW/2,-imageH/2,0,1,v))
				if rt then
					local fixture = love.physics.newFixture(body, shape)
					self:setMaterial(fixture,"wood")
				else
					
				end
			end
		end
	end
	editor.action="importFromImage"
end

function creator:water()
	local body = love.physics.newBody(editor.world, self.createTX, self.createTY,"dynamic")
	local shape = love.physics.newCircleShape(5)
	local fixture = love.physics.newFixture(body, shape,1)
	self:setMaterial(fixture,"water")
end


function creator:getPoints()
	if not self.needPoints then return end
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= editor.mouseX,editor.mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createR=0
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=editor.mouseX,editor.mouseY
		self.createR = getDist(self.createOX,self.createOY,self.createTX,self.createTY)
	elseif self.createOX and not love.mouse.isDown(1) then
		
		self:create()
	end
end

function creator:getVerts()
	if not self.needVerts then return end
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= editor.mouseX,editor.mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createVerts={self.createOX,self.createOY}
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=editor.mouseX,editor.mouseY
		if love.mouse.isDown(2) and not self.rIsDown then
			self.rIsDown=true
			table.insert(self.createVerts, self.createTX)
			table.insert(self.createVerts, self.createTY)
		elseif not love.mouse.isDown(2) then
			self.rIsDown=false
		end
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
	end
end

function creator:freeDraw()
	if not self.needLines then return end
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= editor.mouseX,editor.mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createVerts={self.createOX,self.createOY}
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=editor.mouseX,editor.mouseY
		local dist=getDist(self.createTX,self.createTY,self.createVerts[#self.createVerts-1],self.createVerts[#self.createVerts])
		if dist>3 then
			table.insert(self.createVerts, self.createTX)
			table.insert(self.createVerts, self.createTY)
		end
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
	end


end

function creator:softrope()
	local angle=getRot(self.createOX, self.createOY,self.createTX, self.createTY)
	local stepX=math.sin(angle)
	local stepY=-math.cos(angle)
	local len=50
	local rest=self.createR%30
	self.createTX,self.createTY=self.createTX-rest*stepX,self.createTY-rest*stepY

	editor.action="create softrope"
	local body1 = love.physics.newBody(editor.world, self.createOX, self.createOY,"dynamic")
	local shape = love.physics.newCircleShape(5)
	local fixture = love.physics.newFixture(body1, shape)
	fixture:setSensor(true)
	self:setMaterial(fixture,"wood")

	local body2 = love.physics.newBody(editor.world, self.createTX, self.createTY,"dynamic")
	local shape = love.physics.newCircleShape(5)
	local fixture = love.physics.newFixture(body2, shape)
	fixture:setSensor(true)
	self:setMaterial(fixture,"wood")

	
	local chain={}
	
	for i=len/2,self.createR-len/2,len do
		local body = love.physics.newBody(editor.world, 
			self.createOX+i*stepX, self.createOY+i*stepY,"dynamic")
		body:setAngle(angle+math.pi/2)
		local shape = love.physics.newRectangleShape(len,1)
		local fixture = love.physics.newFixture(body, shape,1)
		fixture:setGroupIndex(-1)
		self:setMaterial(fixture,"wood")
		table.insert(chain, body)
	end
	love.physics.newRevoluteJoint(body1, chain[1], body1:getX(),body1:getY(), false)
	love.physics.newDistanceJoint(body1, chain[1], 
		body1:getX(), body1:getY(),chain[1]:getX(), chain[1]:getY(),
		false)
	love.physics.newRevoluteJoint(body2, chain[#chain], body2:getX(),body2:getY(), false)
	love.physics.newDistanceJoint(body2, chain[#chain], 
		body2:getX(), body2:getY(),chain[#chain]:getX(), chain[#chain]:getY(),
		false)

	for i=2,#chain do
		love.physics.newRevoluteJoint(chain[i], chain[i-1], 
		chain[i]:getX()-len*stepX/2, chain[i]:getY()-len*stepY/2, false)
		love.physics.newDistanceJoint(chain[i], chain[i-1], 
			chain[i]:getX(), chain[i]:getY(),chain[i-1]:getX(), chain[i-1]:getY(),
			false)
	end

	return {body=body}
end

function creator:softcircle()
	editor.action="create softcircle"
	local soft=Softbody(editor.world, "ball",{x=self.createOX,y=self.createOY,r=self.createR})
	print(soft.centerFixture)
	self:setMaterial(soft.centerFixture,"wood")
	for i,v in ipairs(soft.nodes) do
		self:setMaterial(v.fixture,"wood")
	end
end

function creator:softbox()
	editor.action="create softbox"
	local soft=Softbody(editor.world, "rect",{
		x=(self.createOX+self.createTX)/2,
		y=(self.createTY+self.createOY)/2,
		w=math.abs(self.createOX-self.createTX),
		h=math.abs(self.createTY-self.createOY)}
		)
	self:setMaterial(soft.centerFixture,"wood")
	for i,v in ipairs(soft.nodes) do
		self:setMaterial(v.fixture,"wood")
	end
end

function creator:softpolygon()
	editor.action="create softpolygon"
	local soft=Softbody(editor.world, "polygon",{x=self.createOX,y=self.createOY,
		vert=polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts)})
	self:setMaterial(soft.centerFixture,"wood")
	for i,v in ipairs(soft.nodes) do
		self:setMaterial(v.fixture,"wood")
	end
end



function creator:explosion()
	editor.action="create explosion"
	local body = love.physics.newBody(editor.world, self.createOX, self.createOY,"dynamic")
	local shape = love.physics.newCircleShape(self.createR)
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
end




function creator:circle()
	editor.action="create circle"
	local body = love.physics.newBody(editor.world, self.createOX, self.createOY,"dynamic")
	local shape = love.physics.newCircleShape(self.createR)
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"steel")
	return {body=body}
end

function creator:box()
	editor.action="create box"
	local body = love.physics.newBody(editor.world, (self.createOX+self.createTX)/2, 
		(self.createTY+self.createOY)/2,"dynamic")
	local shape = love.physics.newRectangleShape(math.abs(self.createOX-self.createTX),math.abs(self.createTY-self.createOY))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	return {body=body}
end

function creator:line()
	editor.action="create line"
	local body = love.physics.newBody(editor.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newEdgeShape(0,0,self.createTX-self.createOX,self.createTY-self.createOY)
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	sensor = love.physics.newFixture(body, shape)
	sensor:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end

function creator:edge()
	if #self.createVerts<6 then return end
	editor.action="create edge"
	local body = love.physics.newBody(editor.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newChainShape(false, polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	fixture = love.physics.newFixture(body, shape)
	fixture:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end

function creator:freeline()
	if #self.createVerts<6 then return end
	editor.action="create freeline"
	local body = love.physics.newBody(editor.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newChainShape(false, polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	fixture = love.physics.newFixture(body, shape)
	fixture:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end




function creator:polygon()
	if not self.createVerts then return end
	if #self.createVerts<6 then return end
	editor.action="create polygon"
	if #self.createVerts>16 or not love.math.isConvex(self.createVerts) then
		local x,y=math.getPolygonArea(self.createVerts)
		local body = love.physics.newBody(editor.world, x, y,"dynamic")
		local triangles = love.math.triangulate( self.createVerts )
		for i,triangle in ipairs(triangles) do
			local shape = love.physics.newPolygonShape(polygonTrans(-x, -y,0,1,triangle))
			local fixture = love.physics.newFixture(body, shape)
			self:setMaterial(fixture,"wood")
		end

	else
		local x,y=math.getPolygonArea(self.createVerts)
		local body = love.physics.newBody(editor.world, x, y,"dynamic")
		local shape = love.physics.newPolygonShape(polygonTrans(-x, -y,0,1,self.createVerts))
		local fixture = love.physics.newFixture(body, shape)
		self:setMaterial(fixture,"wood")
	end

end

function creator:getBodies()
	local selection=editor.selector.selection
	if not selection then return end
	local body1,body2=selection[1],selection[2]
	if body1 and body2 then 
		return body1,body2 
	end
end

function creator:getContBodies()
	local selection=editor.selector.selection
	if not selection then return end
	for i=1,#selection do

	end

	local body1,body2=selection[1],selection[2]
	if body1 and body2 then 
		return body1,body2 
	end
end


function creator:rope()
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create rope joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint=love.physics.newRopeJoint(body1, body2, x1, y1, x2, y2, getDist(x1, y1, x2, y2), false)
	return joint
end

function creator:distance()
	
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create distance joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint = love.physics.newDistanceJoint(body1, body2, x1, y1, x2, y2, false)
	--joint:setFrequency(10)
end

function creator:weld()
	
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create weld joint"
	local x1,y1 = body1:getPosition()
	local joint = love.physics.newWeldJoint(body1, body2, x1, y1, false)
	--joint:setFrequency(0)
end

function creator:prismatic()
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create prismatic joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local angle= getRot(x1,y1,x2,y2)
	local joint = love.physics.newPrismaticJoint(body1, body2, x2, y2, math.sin(angle), -math.cos(angle), false)
end

function creator:revolute()
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create revolute joint"
	local x,y = body2:getPosition()
	local joint = love.physics.newRevoluteJoint(body1, body2, x, y, false)
end

function creator:pully()
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create pully joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint = love.physics.newPulleyJoint(body1, body2, x1, y1-200, x2, y2-200, x1, y1, x2, y2, 1, false)
end

function creator:wheel()
	local body1,body2=self:getBodies()
	if not body1 then return end
	editor.action="create wheel joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local angle= getRot(x2,y2,x1,y1)
	local joint = love.physics.newWheelJoint(body1, body2, x2, y2, math.sin(angle), -math.cos(angle), false)
end

--mainbody
--magnet = +999 or -999 


function creator:magnetField(fixture)
	editor.helper.setProperty(fixture,"magnet",1000)
	local body=fixture:getBody()
	local shape=fixture:getShape()
	local power
	for i,v in ipairs(fixture:getUserData()) do
		if v.prop=="magnet" then power=v.value end
	end
	local _, _, mass = fixture:getMassData( )
	if shape:getType()=="circle" then
		local x,y= shape:getPoint()
		local fieldShape = love.physics.newCircleShape(x, y, math.sqrt(mass)*100)
		local fieldfixture = love.physics.newFixture(body, fieldShape, 0.00001)
		fieldfixture:setUserData {
			{prop="magnetField",value=power*math.sqrt(mass)*49999},
		}
	elseif shape:getType()=="polygon" then
		local verts={shape:getPoints()}
		if #verts~=8 then print("only rect");return end

		local x,y=(verts[1]+verts[3]) /2,(verts[2]+verts[4]) /2

		local fieldShape = love.physics.newCircleShape(x, y, math.sqrt(mass)*60)
		local fieldfixture = love.physics.newFixture(body, fieldShape, 0.00001)
		fieldfixture:setUserData {
			{prop="magnetField",value=power*math.sqrt(mass)*49999},
		}
		local x,y=(verts[5]+verts[7]) /2,(verts[6]+verts[8]) /2
		local fieldShape = love.physics.newCircleShape(x,y,math.sqrt(mass)*60)
		local fieldfixture = love.physics.newFixture(body, fieldShape, 0.00001)
		fieldfixture:setUserData {
			{prop="magnetField",value=-power*math.sqrt(mass)*49999},
		}
	else
		print("can not solve")
	end

end

function creator:setData(target,data)
	local tab=target:getUserData()
	if not tab then
		tab={data}
		target:setUserData(tab)
	elseif data then
		local found=false
		for i,v in ipairs(target:getUserData()) do
			if v.prop==data.prop then
				v.value=data.value
				found=true
				break
			end
		end
		if not found then
			table.insert(tab, data)
		end
	end
	
end


function creator:setMaterial(fixture,material,arg)
	editor.action="set material:"..material
	local body=fixture:getBody()
	body:setLinearDamping(editor.linearDamping)
	body:setAngularDamping(editor.angularDamping)
	
	editor.helper.setProperty(body)
	editor.helper.setMaterial(fixture,material)

	if m_type=="magnet" then
		self:magnetField(fixture)
	end
end

function creator:cancel()
	self.createOX=nil
	self.createOY=nil
	self.createTX=nil
	self.createTY=nil
	self.needLines=false
	self.needPoints=false
	self.needVerts=false
	self.needPoint=false
	self.createTag=nil
end


function creator:create()
	if not self.createTag then return end
	if self.createOX==self.createTX and self.createOY==self.createTY then
		--do nothing?
	else
		self[self.createTag](self)
	end
	
	--[[
	for i,v in ipairs(self.createList) do
		if v~=self then
			v.toggle=false
		end
		
	end]]
	self.createOX=nil
	self.createOY=nil
	self.createTX=nil
	self.createTY=nil
	self.needLines=false
	self.needPoints=false
	self.needVerts=false
	self.needPoint=false
	self.createTag=nil
	editor.state=self.oState
end

return function(parent) 
	editor=parent
	return creator 
end