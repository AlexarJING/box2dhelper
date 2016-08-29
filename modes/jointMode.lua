local jMode={}
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

function jMode:new()
	self:getAnchors()
end

local function testExist(anchors,joint)
	for i,v in ipairs(anchors) do
		if v.joint==joint then
			return true
		end 
	end
	return false
end

function jMode:getAnchors()
	self.anchors={}
	for i,joint in ipairs(editor.world:getJointList()) do
		if not testExist(self.anchors,joint) and joint:getType()~="gear" then
			local x1,y1,x2,y2=joint:getAnchors()
			if joint:getType()=="pulley" then
				local gx1,gy1,gx2,gy2 = joint:getGroundAnchors()
				table.insert(self.anchors,{joint=joint,x=x1,y=y1,index=1})
				table.insert(self.anchors,{joint=joint,x=x2,y=y2,index=2})
				table.insert(self.anchors,{joint=joint,x=gx1,y=gy1,index=3})
				table.insert(self.anchors,{joint=joint,x=gx2,y=gy2,index=4})
			else
				table.insert(self.anchors,{joint=joint,x=x1,y=y1,index=1})
				if x1~=x2 or y1~=y2 then
					table.insert(self.anchors,{joint=joint,x=x2,y=y2,index=2})
				end
			end
		end	
	end
end

function jMode:inRect(tx,ty)
	if editor.mouseX==clamp(editor.mouseX,tx-3,tx+3) 
		and editor.mouseY==clamp(editor.mouseY,ty-3,ty+3) then
		return true
	end
end


function jMode:update() --左键可调整节点，右键可建立齿轮关节
	
	local down=love.mouse.isDown(1) and 1 
	down=down or (love.mouse.isDown(2) and 2)
	if down then self.dragTX,self.dragTY=editor.mouseX,editor.mouseY end
	if down and not self.selectedAnchor then
		for i,v in ipairs(self.anchors) do
			if jMode:inRect(v.x,v.y) then
				self.selectedAnchor=v
				break
			end
		end	
		self.downType=down
	elseif down==2 and self.selectedAnchor then --齿轮连接
		self.selectedAnchor2=nil
		for i,v in ipairs(self.anchors) do
			if jMode:inRect(v.x,v.y) then
				self.selectedAnchor2=v
				break
			end
		end
	elseif not down and self.selectedAnchor then
		if self.downType==1 then
			self:moveAnchor()
		elseif self.selectedAnchor2 then
			self:createGear()
		end
		self.selectedAnchor=nil
		self.selectedAnchor2=nil
		self:getAnchors()
		self.downType=nil
	end
	return true
end

function jMode:moveAnchor()
	local joint=self.selectedAnchor.joint
	local body1,body2=joint:getBodies()
	local x1,y1 = body1:getPosition()
	local x2,y2 = body2:getPosition()
	
	local jx={}
	local jy={}
	jx[1],jy[1],jx[2],jy[2] = joint:getAnchors()
	local jType=joint:getType()

	if jType == "pulley" then
		jx[3],jy[3],jx[4],jy[4] = joint:getGroundAnchors()
	end

	local tx,ty=self.dragTX,self.dragTY
	local toChange = self.selectedAnchor.index
	if getDist(jx[toChange],jy[toChange],tx,ty)<5 then return end
	jx[toChange]=tx;jy[toChange]=ty
	local jointData=editor.helper.getStatus(joint,"joint")
	local j
	if jType=="rope" then
		j=love.physics.newRopeJoint(body1, body2, jx[1], jy[1], jx[2], jy[2], 
			getDist(jx[1], jy[1], jx[2], jy[2]),joint:getCollideConnected())
	elseif jType=="distance" then
		j=love.physics.newDistanceJoint(body1, body2, jx[1], jy[1], jx[2], jy[2],
			joint:getCollideConnected())
		
	elseif jType=="prismatic" then  ---错误！！需要重新搭建gear!!
		local angle= getRot(x1,y1,jx[1],jy[1])
		j = love.physics.newPrismaticJoint(body1,body2,jx[1],jy[1],math.sin(angle), -math.cos(angle),
			joint:getCollideConnected())
		
	elseif jType=="pulley" then
		j = love.physics.newPulleyJoint(body1, body2, jx[3], jy[3], jx[4], jy[4],jx[1], jy[1], jx[2], jy[2],
			joint:getRatio(),joint:getCollideConnected())
	elseif jType=="revolute" then ---错误！！需要重新搭建gear!!
		j = love.physics.newRevoluteJoint(body1, body2, jx[1], jy[1], joint:getCollideConnected())
		
	elseif jType=="weld" then
		j = love.physics.newWeldJoint(body1, body2, jx[1], jy[1], joint:getCollideConnected())
		
	elseif jType=="wheel" then	
		local angle= getRot(x1, y1,jx[1], jy[1])
		j = love.physics.newWheelJoint(body1, body2, jx[1], jy[1],math.sin(angle), -math.cos(angle), joint:getCollideConnected())
	else
		return
	end
	local jointData=editor.helper.getStatus(joint,"joint")
	editor.helper.setStatus(j,"joint",jointData)
	self.selection=j
	editor.selector.selection={j}
	joint:destroy()
end

function jMode:createGear()
	local j1=self.selectedAnchor.joint
	local j2=self.selectedAnchor2.joint
	if j1==j2 then return end
	if j1:getType()~="revolute" and j1:getType()~="prismatic" then return end
	if j2:getType()~="revolute" and j2:getType()~="prismatic" then return end
	local joint = love.physics.newGearJoint(j1, j2, 1, false)
	editor.action="create Gearjoint"
end





local function CreateGear(segments)
	segments = segments or 40
	local vertices = {}
	table.insert(vertices, {0, 0})
	for i=0, segments do
		local angle = (i / segments) * math.pi * 2
		local x = math.cos(angle)+(i%2)*math.cos(angle)*0.7
		local y = math.sin(angle)+(i%2)*math.sin(angle)*0.7
		table.insert(vertices, {x, y})
	end
	return love.graphics.newMesh(vertices, "fan")
end

function jMode:click()
	if not self.selectedAnchor then 
		editor.selector.selection=nil
		return 
	end
	self.selection=self.selectedAnchor.joint
	editor.selector.selection={self.selection}
end


function jMode:comboSet()
	local t=editor.interface.property.targetType
	local target=editor.interface.property.target
	if not t=="joint" then return end
	local data=editor.helper.getStatus(target,"joint")
	local targetType=target:getType()
	local tested={}
	tested[target]=true
	local toTest={target}
	repeat
		local tmp={}
		for i,joint in ipairs(toTest) do
			local body1,body2=joint:getBodies()
			for i,j in ipairs(body1:getJointList()) do
				if not tested[j] and j:getType()==targetType then
					editor.helper.setStatus(j,"joint",data)
					table.insert(tmp, j)
					tested[j]=true
				end
			end
		end
		toTest=tmp
	until #toTest==0
end



local gearShape = CreateGear(20)



function jMode:draw()

	for i,anchor in ipairs(self.anchors) do
		love.graphics.setColor(255, 255, 0, 255)
		love.graphics.rectangle("fill", anchor.x-3,anchor.y-3, 6, 6)
	end
	
	if self.selectedAnchor then
		love.graphics.setColor(0, 255, 0, 255)
		love.graphics.rectangle("fill", self.selectedAnchor.x-3,self.selectedAnchor.y-3, 6, 6)
		local joint=self.selectedAnchor.joint
		local tx,ty=self.dragTX,self.dragTY
		local jx={}
		local jy={}
		jx[1],jy[1],jx[2],jy[2] = joint:getAnchors()
		if joint:getType()=="pulley" then jx[3],jy[3],jx[4],jy[4] = joint:getGroundAnchors() end
		local toChange = self.selectedAnchor.index
		jx[toChange]=tx;jy[toChange]=ty
		
		if joint:getType()=="pulley" then 
			love.graphics.line(jx[1],jy[1],jx[3],jy[3])
			love.graphics.line(jx[3],jy[3],jx[4],jy[4])
			love.graphics.line(jx[2],jy[2],jx[4],jy[4])
		else
			love.graphics.line(jx[1],jy[1],jx[2],jy[2])
		end
	end
	
	if self.downType==2 then
		local x1,y1,x2,y2=self.selectedAnchor.x,self.selectedAnchor.y,self.dragTX,self.dragTY
		love.graphics.line(x1, y1, ((x1+x2)/2)-5,((y1+y2)/2)-5)
		love.graphics.line(x2, y2, ((x1+x2)/2)+5,((y1+y2)/2)+5)
		love.graphics.draw(gearShape, ((x1+x2)/2)-5,((y1+y2)/2)-5,1,5,5)
		love.graphics.draw(gearShape, ((x1+x2)/2)+5,((y1+y2)/2)+5,-1,5,5)
	end


	if self.selectedAnchor2 then
		love.graphics.setColor(0, 255, 0, 255)
		love.graphics.rectangle("fill", self.selectedAnchor2.x-3,self.selectedAnchor2.y-3, 6, 6)
	end	
end



return function(parent) 
	editor=parent
	return jMode 
end