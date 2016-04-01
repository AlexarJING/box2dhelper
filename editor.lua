local editor={}
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
local function clamp(a,low,high)
	if low>high then 
		return math.max(high,math.min(a,low))
	else
		return math.max(low,math.min(a,high))
	end
end



world = love.physics.newWorld(0, 9.8*64, false)
love.physics.setMeter(64)
editor.world = world
editor.objects={}
editor.selection=nil
editor.inEditMode=true
editor.undoStack={}
editor.undoIndex=0
editor.action="initialize"
editor.units={}
editor.preview={}
editor.preview.cam=require("libs.gamera").new(-5000,-5000,10000,10000)
editor.preview.world=love.physics.newWorld(0, 9.8*64, false)
editor.preview.cam:setWindow(w()-300,0,300,300)
editor.preview.cam:setScale(0.3)
editor.preview.cam:setPosition(0,0)

editor.popTags={"body","shape","fixture","joint"}
editor.popTagIndex=1
editor.popItemIndex=1

editor.mouseBall={enable=false}

editor.showHelp=false

function editor:update(dt)
	
	self:pushUndo()
	if self.inEditMode then
		if self:vertMode() then return end
		if self:downCreate() then return end
		if not self.dragSelecting and self:dragMove() then return end
		self:dragSelect()
		self:updateRelativeFrame()

	else
		if self.mouseBall.enable then
			self.mouseBall.joint:setTarget(mouseX,mouseY)
		else
			
			if not self.dragSelecting then
				if not self:dragForce() then
					self:dragSelect()
				end
			else
				self:dragSelect()
			end
		end
		self:downForce()
		self.world:update(dt)
	end
	self:unpdatePopValue()
end

function editor:updateRelativeFrame()

	if not self.selection or self.oPop~=self.selection[1][1] then
		self:popRelativeFrame()
	end

end

function editor:unpdatePopValue()
	if not self.popGrid then return end
	if not self.selection or self.oPop~=self.selection[1][1] then
		return
	end
	local tmp=helper.getStatus(self.popTarget,self.popTags[self.popTagIndex])

	self.popData={}
	local data=self.popData
	
	for i,v in ipairs(helper.properties[self.popTags[self.popTagIndex]]) do
		if tmp[v]~=nil then table.insert(data,{prop=v,value=tmp[v]}) end
	end

	for i,v in ipairs(self.popData) do

		local value=self.popGrid[i][2]
		if type(v.value)=="number" then
			value:SetText(tostring(v.value))
		elseif type(v.value)=="table" then
			local str=""
			for i,v in ipairs(v.value) do
				str=str..tostring(v)..","
			end
			value:SetText(str)
		elseif type(v.value)=="boolean" then
			value:SetChecked(v.value)
		elseif type(v.value)=="string" then
			value:SetText(tostring(v.value))
		end
		
	end

end

function editor:saveToFile()
	if self.popFrame then
		self.popList:Remove()
		self.popFrame:Remove() 
	end
	 
	local frame =ui.Create("frame")
	frame:SetName("save to file...")
	frame:SetSize(300,80)
	frame:CenterWithinArea(0,0,w(),h())
	local input = ui.Create("textinput",frame)
	input:SetSize(280,30)
	input:SetPos(10,40)
	input.OnEnter=function()
		love.filesystem.createDirectory("save")
		local file = love.filesystem.newFile("save/"..input:GetText()..".lua")
		file:open("w")
		file:write(table.save(self.undoStack[self.undoIndex].world))
		file:close()
		frame:Remove()
	end
end


function editor:loadFromFile()

	local files = love.filesystem.getDirectoryItems("save")
	local frame =ui.Create("frame")
	local count=#files
	frame:SetName("select a file to load...")
	frame:SetSize(300,30*count+30)
	frame:CenterWithinArea(0,0,w(),h())
	local list = ui.Create("list",frame)
	list:SetDisplayType("vertical")
	list:SetPos(5, 30)
	list:SetSize(280, 28*count)
	for i,v in ipairs(files) do
		local b= ui.Create("button")
		b:SetText(v)
		list:AddItem(b)
		b.OnClick=function()
			local file = love.filesystem.newFile("save/"..b:GetText())
			file:open("r")
			local str=file:read()
			world = love.physics.newWorld(0, 9.8*64, false)
			love.physics.setMeter(64)
			self.world = world
			self.objects=helper.createWorld(self.world,loadstring(str)())
			self:clearSelection()
			frame:Remove()
		end
	end
end

function editor:popRelativeFrame() --弹出选中的第一个body,fixture,joint
	if self.popFrame then
		self.popList:Remove()
		self.popFrame:Remove() 
	end

	if not self.selection then 
		self.oPop=nil
		return 
	end
	local tag=self.popTags[self.popTagIndex]
	local index=self.popItemIndex
	local obj=self.selection[1][1]
	self.oPop=obj
	local target
	if tag=="body" then
		self.popItem=nil
		target=self.selection[1][1].body
	elseif tag=="shape" then
		self.popItem=self.selection[1][1].body:getFixtureList()
		target=self.popItem[index] and self.popItem[index]:getShape() or self.popItem[1]:getShape()
	elseif tag=="fixture" then
		self.popItem=self.selection[1][1].body:getFixtureList()
		target=self.popItem[index] or self.popItem[1]
	elseif tag=="joint" then
		self.popItem=self.selection[1][1].body:getJointList()
		target=self.popItem[index] or self.popItem[1]
	end	

	if not target then
		self.popItem=nil
		self.popItemIndex=1
		self.popTagIndex=1
		tag="body"
		target=self.selection[1][1].body
	end
	self.popTarget=target

	local tmp=helper.getStatus(target,tag)

	self.popData={}
	local data=self.popData
	
	for i,v in ipairs(helper.properties[tag]) do
		if tmp[v]~=nil then table.insert(data,{prop=v,value=tmp[v]}) end
	end


	self.popFrame= ui.Create("frame")
	local frame = self.popFrame
	frame:SetName(tag)
	frame:SetSize(250, 35+#data*30)
	frame:SetPos(w()*0.8, 300)
	frame:ShowCloseButton(false)
	self.popList=ui.Create("grid", frame)
	local list = self.popList
	list:SetPos(5, 30)
	list:SetSize(240, #data*20)
	list:SetCellWidth(110)
	list:SetCellHeight(20)
	list:SetRows(#data)
	list:SetColumns(2)
	list:SetItemAutoSize(true)

	self.popGrid={}
	for i,v in ipairs(data) do
		local key = ui.Create("button")
		key:SetText(v.prop)
		local value
		if type(v.value)=="number" then
			value = ui.Create("textinput")
			value:SetText(tostring(v.value))
			value.OnEnter=function()
				local text=value:GetText()
				local num=tonumber(text)
				if num then
					target["set"..v.prop](target,num)
					self.action="change property"
				end
			end
			--value.OnFocusLost=value.OnEnter
		elseif type(v.value)=="table" then
			value = ui.Create("textinput")
			local str=""
			for i,v in ipairs(v.value) do
				str=str..tostring(v)..","
			end
			value:SetText(str)
			value.OnEnter=function()
				local text=value:GetText()
				local tab= string.split(text,",")
				target["set"..v.prop](target,unpack(tab)) 
				self.action="change property"
			end
			--value.OnFocusLost=value.OnEnter
		elseif type(v.value)=="boolean" then
			value = ui.Create("checkbox")
			value:SetChecked(v.value)
			value.OnChanged=function()
				target["set"..v.prop](target,value:GetChecked()) 
				self.action="change propert"
			end
			
		elseif type(v.value)=="string" then
			value = ui.Create("textinput")
			value:SetText(tostring(v.value))
			value.OnEnter=function()
				local text=value:GetText()
				target["set"..v.prop](target,text) 
				self.action="change property"
			end
			--value.OnFocusLost=value.OnEnter
		end
		if not target["set"..v.prop] then 
			if value.SetEditable then
				value:SetEditable(false)
			else
				value:SetEnabled(false)
			end
		end
		list:AddItem(key,i,1)
		list:AddItem(value,i,2)
		table.insert(self.popGrid, {key,value})
	end


end

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

function editor:pushUndo()
	if self.action then
		self.undoIndex=self.undoIndex+1
		self.undoStack[self.undoIndex]={event=self.action,world=helper.getWorldData(self.world)}
		if #self.undoStack>10 then
			table.remove(self.undoStack, 1)
			self.undoIndex=10
		end
		for i=self.undoIndex+1,10 do
			self.undoStack[i]=nil
		end
		self.action=nil
	end
end

function editor:undo()
	--print("undo")
	self.undoIndex=self.undoIndex-1
	if self.undoIndex<1 then self.undoIndex=1 end
	world = love.physics.newWorld(0, 9.8*64, false)
	love.physics.setMeter(64)
	self.world = world
	self.objects=helper.createWorld(self.world,self.undoStack[self.undoIndex].world)
	self:clearSelection()
end

function editor:redo()
	--print("redo")
	self.undoIndex=self.undoIndex+1
	if self.undoIndex>#self.undoStack then self.undoIndex=#self.undoStack end
	world = love.physics.newWorld(0, 9.8*64, false)
	love.physics.setMeter(64)
	self.world = world
	self.objects=helper.createWorld(self.world,self.undoStack[self.undoIndex].world)
	self:clearSelection()
end

function editor:test()
	self.inEditMode = not self.inEditMode
	if self.inEditMode then
		self:redo()
	else
		self.action="test"
	end
end


function editor:keypress(key)
	
	if self.inEditMode then
		if key=="f1" then
			self:test()
		elseif key=="escape" then
			self:clearSelection()
		elseif key=="r" then
			self:rope()
		elseif key=="d" then
			self:distance()
		elseif key=="w" then
			self:weld()
		elseif key=="q" then
			self:prismatic()
		elseif key=="i" then
			self:wheel()
		elseif key=="u" then
			self:pully()
		elseif key=="o" then
			self:revolute()
		elseif key=="delete" then
			self:delete()
		elseif key=="v" then
			if love.keyboard.isDown("lctrl") then self:duplicate() end
		elseif key=="f" then
			if love.keyboard.isDown("lctrl") then self:fix() end
		elseif key=="a" then
			if love.keyboard.isDown("lctrl") then 
				self:selectAll() 
			else
				self:aline(true)
			end
		elseif key=="s" then
			if love.keyboard.isDown("lctrl") then
				self:saveToFile()
			else
				self:aline(false)
			end
			
		elseif key=="end" then
			self:removeJoint()
		elseif key=="m" then
			if love.keyboard.isDown("lctrl") then self:combine() end
		elseif key=="b" then
			if love.keyboard.isDown("lctrl") then self:divide() end
		elseif key=="z" then
			if love.keyboard.isDown("lctrl") then self:undo() end
		elseif key=="y" then
			if love.keyboard.isDown("lctrl") then self:redo() end
		elseif tonumber(key) then
			if love.keyboard.isDown("lctrl") then self:saveUnit(key) end
			if love.keyboard.isDown("lalt") then self:loadUnit(key) end
			self:switchPreview(key)
		elseif key=="tab" then
			self:switchPopTag()
		elseif key=="`" then
			self:switchPopItemIndex()
		elseif key=="h" then
			self.showHelp=not self.showHelp
		elseif key=="l" then
			if love.keyboard.isDown("lctrl") then self:loadFromFile() end
		end

	else
		if key=="f1" then
			self:test()
		elseif key=="a" then
			if love.keyboard.isDown("lctrl") then 
				self:selectAll() 
			end
		elseif key=="escape" then
			self:clearSelection()
		elseif key=="m" then
			self:toggleMouse()
		end
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


function editor:downCreate()
	if love.keyboard.isDown("c") then
		self.createTag="circle"
		self:getPoints()
	elseif love.keyboard.isDown("b") then
		self.createTag="box"
		self:getPoints()		
	elseif love.keyboard.isDown("l") then
		self.createTag="line"
		self:getPoints()
	elseif love.keyboard.isDown("e") then
		self.createTag="edge"
		self:getVerts()
	elseif love.keyboard.isDown("p") then
		self.createTag="polygon"
		self:getVerts()
	elseif love.keyboard.isDown("f") then
		self.createTag="freeLine"
		self:freeDraw()
	elseif love.keyboard.isDown("t") then
		self:rotate()
	else
		self.createOX=nil
		self.createTag=nil
		return false
	end
	return true
end

function editor:saveUnit(slot)
	if not self.selection then return end
	self.action="save unit in slot "..slot
	local bodyList={}

	for i,v in ipairs(self:getSelected()) do

		bodyList[i]=v[1].body
	end
	
	self.units[slot]=helper.getWorldData(bodyList)
end

function editor:loadUnit(slot)
	if not self.units[slot] then return end
	self.action="load unit from slot"..slot
	local add=helper.createWorld(self.world,self.units[slot],mouseX,mouseY)
	local selection = {}
	for i,v in ipairs(add) do
		table.insert(self.objects, v)
		selection[i]={v}
	end
	self:clearSelection()
	self.selection=selection
	for i=1,#selection do
		self.selection[i][1].body:setUserData(true)
	end
	self.selectIndex=1
end

function editor:switchPreview(slot)
	if not self.units[slot] then return end
	self.preview.world=love.physics.newWorld(0, 9.8*64, false)
	helper.createWorld(self.preview.world,self.units[slot])
end

function editor:switchPopTag()
	self.popTagIndex=self.popTagIndex+1
	self.popTag=self.popTags[self.popTagIndex] or self.popTags[1]
	self:popRelativeFrame()
end

function editor:switchPopItemIndex()
	if not self.popItem then return end
	self.popItemIndex=self.popItemIndex+1
	if not self.popItem[self.popItemIndex] then self.popItemIndex=1 end
	self:popRelativeFrame()
end


function editor:aline(isVerticle)
	self.action="aline,".."isVerticle:"..tostring(isVerticle)
	local tab=self:getSelected()
	if not tab then return end
	local alineX,alineY =tab[1][1].body:getPosition()
	for i,objs in ipairs(tab) do
		local obj = objs[1]
		local body = obj.body
		if isVerticle then
			body:setY(alineY)
		else
			body:setX(alineX)
		end		
	end
end

function editor:removeJoint()
	self.action="remove joint"
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

function editor:selectAll()
	self.selection={}
	for i,obj in ipairs(self.objects) do
		obj.body:setUserData(true)
		self.selection[i]={obj}
	end
	self.selectIndex=1
end


function editor:getSelected()
	if not self.selection then return end
	local tab={}
	for i=1,#self.selection-1 do
		table.insert(tab, self.selection[i])
	end
	if self.selection[#self.selection][self.selectIndex].body:getUserData() then
		table.insert(tab, self.selection[#self.selection])
	end
	if #tab==0 then return end
	return tab
end

function editor:fix()
	self.action="toggle static/dynamic"
	if not self.selection then return end
	if not #self.selection==1 then return end
	if self.selection[1][1].body:getType()=="dynamic" then
		self.selection[1][1].body:setType("static")
	else
		self.selection[1][1].body:setType("dynamic")
	end
end

function editor:rotate()
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
		self.action="rotate by body center"
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
		self.action="rotate by 0,0"
	end
end


function editor:duplicate()
	if not love.keyboard.isDown("lctrl") then return end
	local tab=self:getSelected()
	if not tab then return end
	self.action="copy selected object"
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


function editor:delete()
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
	self.action="delect selected object"
	self.selection=nil
	self.selectIndex=1
end


function editor:inRect(x,y)
	if x==clamp(x,self.dragOX,self.dragTX) 
		and y==clamp(y,self.dragOY,self.dragTY) then
		return true
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

function editor:move(dx,dy,throw)
	for i,tab in ipairs(self.selection) do
		local obj
		if i==#self.selection then
			obj=tab[self.selectIndex]
		else
			obj=tab[1]
		end
		local x,y = obj.body:getPosition()

		if throw then
			local dt = love.timer.getDelta()
			obj.body:setLinearVelocity( dx/dt, dy/dt )
		else
			obj.body:setLinearVelocity(0,0)
			obj.body:setAngularVelocity(0,0)
		end
		obj.body:setPosition(x+dx,y+dy)
	end
end


function editor:combine()
	local objs=self:getSelected()
	if not objs then return end
	self.action="combine objects"
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

function editor:divide()
	self.action="divide object"
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


function editor:mouseTest()
	local check=false
	for i,tab in ipairs(self.selection) do
		local obj
		if i==#self.selection then
			obj=tab[self.selectIndex]
		else
			obj=tab[1]
		end
		for i,fix in ipairs(obj.body:getFixtureList()) do
			if fix:testPoint( mouseX, mouseY ) then
				check=true
				break
			end
		end
	end
	return check
end

function editor:dragMove()
	if not self.selection then return end
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
		self.action="move"
	end

	return self.dragMoving
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

function editor:clearSelection()
	for i,obj in ipairs(self.objects) do
		if not obj.body:isDestroyed() then
			obj.body:setUserData(false)
		end
	end
	self.selection=nil
	self.selectIndex=1

end




function editor:dragSelect()

	if love.mouse.isDown(1) and not self.dragSelecting then
		self.dragOX,self.dragOY=mouseX,mouseY
		self.dragSelecting=true	
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif love.mouse.isDown(1) and self.dragSelecting then
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif not love.mouse.isDown(1) and self.dragSelecting then
		local selection={}
		for i,obj in ipairs(self.objects) do
			for i,fix in ipairs(obj.body:getFixtureList()) do
				local shape=fix:getShape()
				if shape:type()=="CircleShape" then
					local x,y=obj.body:getPosition()
					local r=shape:getRadius()
					if self:inRect(x,y) and self:inRect(x+r,y) and self:inRect(x-r,y)
						and self:inRect(x,y+r) and self:inRect(x,y-r) then
						table.insert(selection, {obj})
					end
				elseif shape:type()~="ChainShape" then
					local points={shape:getPoints()}
					local check=true
					for i=1,#points/2,2 do
						if not self:inRect(shape:getPoints()) then
							check=false
							break
						end
					end
					if check then
						table.insert(selection, {obj})
					end
				end
			end
		end
		if selection[1] then
			self:clearSelection()
			self.selection=selection
			for i=1,#selection do
				self.selection[i][1].body:setUserData(true)
			end
		end
		self.dragSelecting=false
	end
end

function editor:click(key)
	if self.mouseBall.enable then return end
	if self.dragOX~=self.dragTX or self.dragOY~=self.dragTY then return end
	if key=="l" then
		local selection={}
		for i,obj in ipairs(self.objects) do
			for i,fix in ipairs(obj.body:getFixtureList()) do
				if fix:testPoint( mouseX, mouseY ) then
					table.insert(selection, obj)
				end
			end
		end
		
		if selection[1] then
			if  love.keyboard.isDown("lctrl") then
				
				if self.selection then
					if self.selection[#self.selection][self.selectIndex] then
						self.selection[#self.selection][1]=self.selection[#self.selection][self.selectIndex]
						if not self.selection[#self.selection][1].body:getUserData() then
							--如果最后一项的body状态是未选中，那么就把最后一项删除。
							table.remove(self.selection, #self.selection)
						end
					end
				else
					self.selection={}
				end

				self.selection[#self.selection+1]=selection
				if self.selection[#self.selection][1].body:getUserData() then
					for i=1,#self.selection-1  do
						if self.selection[i][1]==self.selection[#self.selection][1] then
							table.remove(self.selection, i)
							break
						end
					end
					self.selection[#self.selection][1].body:setUserData(false)
				else
					self.selection[#self.selection][1].body:setUserData(true)
				end
				self.selectIndex=1		
			else
				self:clearSelection()
				self.selection={}
				self.selection[1]=selection
				self.selection[1][1].body:setUserData(true)
				self.selectIndex=1
			end
		end
		--if self.selection then print(#self.selection) end
	elseif key=="r" then
		if self.selection and self.selection[#self.selection][self.selectIndex] then
			self.selection[#self.selection][self.selectIndex].body:setUserData(false)
			self.selectIndex=self.selectIndex+1
			if self.selection[#self.selection][self.selectIndex] then
				self.selection[#self.selection][self.selectIndex].body:setUserData(true)
			else
				self.selectIndex=1
				self.selection[#self.selection][self.selectIndex].body:setUserData(true)
			end
		end
	end
end



function editor:getPoints()
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= mouseX,mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createR=0
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=mouseX,mouseY
		self.createR = getDist(self.createOX,self.createOY,self.createTX,self.createTY)
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
		self.createOX=nil
		self.createOY=nil
		self.createTX=nil
		self.createTY=nil
	end
end

function editor:getVerts()
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= mouseX,mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createVerts={self.createOX,self.createOY}
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=mouseX,mouseY
		if love.mouse.isDown(2) and not self.rIsDown then
			self.rIsDown=true
			table.insert(self.createVerts, self.createTX)
			table.insert(self.createVerts, self.createTY)
		elseif not love.mouse.isDown(2) then
			self.rIsDown=false
		end
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
		self.createOX=nil
		self.createOY=nil
		self.createTX=nil
		self.createTY=nil
	end
end

function editor:freeDraw()
	if not self.createOX and love.mouse.isDown(1) then
		self.createOX,self.createOY= mouseX,mouseY	
		self.createTX,self.createTY=self.createOX,self.createOY
		self.createVerts={self.createOX,self.createOY}
	elseif self.createOX and love.mouse.isDown(1) then
		self.createTX,self.createTY=mouseX,mouseY
		local dist=getDist(self.createTX,self.createTY,self.createVerts[#self.createVerts-1],self.createVerts[#self.createVerts])
		if dist>3 then
			table.insert(self.createVerts, self.createTX)
			table.insert(self.createVerts, self.createTY)
		end
	elseif self.createOX and not love.mouse.isDown(1) then
		self:create()
		self.createOX=nil
		self.createOY=nil
		self.createTX=nil
		self.createTY=nil
	end


end


function editor:circle()
	self.action="create circle"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"dynamic")
	local shape = love.physics.newCircleShape(self.createR)
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	return {body=body,shape=shape,fixture=fixture}
end

function editor:box()
	self.action="create box"
	local body = love.physics.newBody(self.world, (self.createOX+self.createTX)/2, 
		(self.createTY+self.createOY)/2,"dynamic")
	local shape = love.physics.newRectangleShape(math.abs(self.createOX-self.createTX),math.abs(self.createTY-self.createOY))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	return {body=body,shape=shape,fixture=fixture}
end

function editor:line()
	self.action="create line"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newEdgeShape(0,0,self.createTX-self.createOX,self.createTY-self.createOY)
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	sensor = love.physics.newFixture(body, shape)
	sensor:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end

function editor:edge()
	if #self.createVerts<6 then return end
	self.action="create edge"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newChainShape(false, polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	fixture = love.physics.newFixture(body, shape)
	fixture:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end

function editor:freeLine()
	if #self.createVerts<6 then return end
	self.action="create freeline"
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"static")
	local shape = love.physics.newChainShape(false, polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	shape = love.physics.newCircleShape(5)
	fixture = love.physics.newFixture(body, shape)
	fixture:setSensor(true)
	return {body=body,shape=shape,fixture=fixture}
end




function editor:polygon()
	if #self.createVerts<6 then return end
	if #self.createVerts>16 then
		for i=16,#self.createVerts do
			self.createVerts[i]=nil
		end
	end
	self.action="create polygon"	
	local body = love.physics.newBody(self.world, self.createOX, self.createOY,"dynamic")
	local shape = love.physics.newPolygonShape(polygonTrans(-self.createOX, -self.createOY,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	local x,y=body:getWorldPoint(fixture:getMassData( ))
	body:destroy()
	local body = love.physics.newBody(self.world, x, y,"dynamic")
	local shape = love.physics.newPolygonShape(polygonTrans(-x, -y,0,1,self.createVerts))
	local fixture = love.physics.newFixture(body, shape)
	self:setMaterial(fixture,"wood")
	return {body=body,shape=shape,fixture=fixture}
end

function editor:getBodies()
	if not self.selection then return end
	local body1,body2,check
	for i,tab in ipairs(self.selection) do
		local obj
		if i==#self.selection then
			obj=tab[self.selectIndex]
		else
			obj=tab[1]
		end
		if not body1 then 
			body1=obj.body 
		elseif not body2 then 
			body2=obj.body
		elseif not check then
			check=obj.body:getUserData()
			break
		end
	end
	if body1 and body2 and not check then 
		return body1,body2 
	end
end

function editor:rope()
	
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create rope joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint=love.physics.newRopeJoint(body1, body2, x1, y1, x2, y2, getDist(x1, y1, x2, y2), false)
	return joint
end

function editor:distance()
	
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create distance joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint = love.physics.newDistanceJoint(body1, body2, x1, y1, x2, y2, false)
	joint:setFrequency(10)
end

function editor:weld()
	
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create weld joint"
	local x1,y1 = body1:getPosition()
	local joint = love.physics.newWeldJoint(body1, body2, x1, y1, false)
	joint:setFrequency(10)
end

function editor:prismatic()
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create prismatic joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local angle= getRot(x1,y1,x2,y2)
	local joint = love.physics.newPrismaticJoint(body1, body2, x2, y2, math.sin(angle), -math.cos(angle), false)
	--joint:setLimits(-90,50)
end

function editor:revolute()
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create revolute joint"
	local x,y = body2:getPosition()
	local joint = love.physics.newRevoluteJoint(body1, body2, x, y, false)
end

function editor:pully()
	local body1,body2=self:getBodies()
	if not body1 then return end
	self.action="create pully joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local joint = love.physics.newPulleyJoint(body1, body2, x1, y1-200, x2, y2-200, x1, y1, x2, y2, 1, false)
end

function editor:wheel()
	local body2,body1=self:getBodies()
	if not body1 then return end
	self.action="create wheel joint"
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	local angle= getRot(x1,y1,x2,y2)
	local joint = love.physics.newWheelJoint(body2, body1, x1, y1, math.sin(angle), -math.cos(angle), false)
end

function editor:create()
	local obj=self[self.createTag](self)
	table.insert(self.objects,obj)
end






function editor:setMaterial(fixture,m_type)
	--self.action="set material"..m_type
	if m_type=="wood" then
		fixture:setDensity(1)
		fixture:setFriction(1)
		fixture:setRestitution(0.2)
	elseif m_type=="rock" then
	end
end

function editor:inRect2(tx,ty)
	if mouseX==clamp(mouseX,tx-3,tx+3) 
		and mouseY==clamp(mouseY,ty-3,ty+3) then
		return true
	end
end

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

function editor:drawEditor()
	love.graphics.setColor(255,255,255)
	if self.dragSelecting then
		love.graphics.polygon("line",
			self.dragOX,self.dragOY,
			self.dragOX,self.dragTY,
			self.dragTX,self.dragTY,
			self.dragTX,self.dragOY)
	end

	if self.createTag then
		love.graphics.print("creating "..self.createTag, mouseX+5,mouseY+5,0,2,2)
	end

	if self.dragForcing then
		love.graphics.line(self.dragOX,self.dragOY,self.dragTX,self.dragTY)
	end

	if self.createOX then
		if self.createTag=="circle" then
			love.graphics.circle("line", self.createOX, self.createOY, self.createR)
			love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
		elseif self.createTag=="box" then
			love.graphics.polygon("line",
				self.createOX,self.createOY,
				self.createOX,self.createTY,
				self.createTX,self.createTY,
				self.createTX,self.createOY)
		elseif self.createTag=="line" then
			love.graphics.line(self.createOX,self.createOY,self.createTX,self.createTY)
		elseif self.createTag=="edge" or self.createTag=="freeLine" then
			
			for i=1,#self.createVerts-3,2 do
				love.graphics.line(self.createVerts[i],self.createVerts[i+1],self.createVerts[i+2],self.createVerts[i+3])
			end
			love.graphics.line(self.createVerts[#self.createVerts-1],self.createVerts[#self.createVerts],self.createTX,self.createTY)

		elseif self.createTag=="polygon" then
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

	if (not love.keyboard.isDown("lalt")) and (not love.keyboard.isDown("t")) then return end
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

function editor:draw()
	
	cam:draw(function()
		self:drawEditor()
		helper.draw(self.world)	
	end)
	
	self.preview.cam:draw(function()
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.rectangle("line", -300, -299, 599, 599)
		love.graphics.line(-20,0,20,0)
		love.graphics.line(0,-20,0,20)
		helper.draw(self.preview.world)
	end)

	local text=[[
	select relative
	*****click to select, drag to multi-select,hold ctrl to addtive select, press esc to clear selection
	*****for selected objects, drag to move, holding t and left/right drag to rotate at center body/axis.
	---------------------------------------------------------------------------------------
	*****hold space button and drag to scoll the screen
	*****use mouse scroll to change the scale of the screen
	----------------------------------------------------------------------------------
	create relative
	*****hold button and drag/right click to create shapes
	c=circle b=box l=line p=polygon e=edge  f=freeline
	*****select 2 objects and press button to create joints
	r=rope, d=distance, w=weld, q= prismatic, i=wheel, u=pully, o=revolute
	-------------------------------------------------------------------------------------
	edit relative
	F1 	--- toggle test mode or edit mode
	f 	--- toggle static/dynamic
	del ---	delete selected bodies
	v 	--- copy selected bodies
	a 	--- aline horizontally
	s 	--- aline vertically
	end --- remove joint
	m 	--- combine fixtures to a body
	b 	--- divide fixtures into bodies
	ctrl+z 	undo
	ctrl+y 	redo
	----------------------------------------------------------------------------------------
	verticle relative
	********hold alt to edit verticle, drag to change the shape or radius
	-------------------------------------------------------------------------------------
	ctrl + number ----- save selected units
	number  ---- preview saved units
	alt + number ---- place unit to the position of mouse
	---------------------------------------------------------------------------------------
	tab --- switch "body" "shape" "fixture" "joint" info
	~ 	--- switch different "shape" "fixture" "joint" to the body
	]]

	love.graphics.setColor(255, 255, 255, 200)
	if self.showHelp then
		love.graphics.print(text, 10, 10, 0, 1,1)
	else
		love.graphics.print("press h to toggle help info", 10, 10, 0, 1.5,1.5)
	end
	love.graphics.setColor(255, 255, 255, 255)
	if self.inEditMode then
		love.graphics.printf("Edit Mode", 0, 20, w()/2, "center", 0, 2, 2)
	else
		love.graphics.printf("Test Mode", 0, 20, w()/2, "center", 0, 2, 2)
	end

end

return editor