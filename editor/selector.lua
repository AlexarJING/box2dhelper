local selector={}
local editor
local mouseX,mouseY
local clamp= function (a,low,high)
	if low>high then 
		return math.max(high,math.min(a,low))
	else
		return math.max(low,math.min(a,high))
	end
end
local getDist = function(x1,y1,x2,y2) return math.sqrt((x1-x2)^2+(y1-y2)^2) end

selector.colorStyle={
		dynamic={100, 200, 0, 255},
		static={100, 100, 0, 255},
		kinematic={100, 255, 0, 255},
		sensor={0,0,-255,0},
		joint={255, 100, 0, 150},
		body={255, 0, 0, 255},
		contact={0,255,255,255},
	}

function selector:update()
	mouseX,mouseY=editor.mouseX,editor.mouseY
	self:dragSelect()
end

function selector:draw()
	love.graphics.setColor(255, 255, 255, 255)
	if self.dragSelecting then
		love.graphics.polygon("line",
			self.dragOX,self.dragOY,
			self.dragOX,self.dragTY,
			self.dragTX,self.dragTY,
			self.dragTX,self.dragOY)
	end

	if self.selection then
		editor.helper.draw(self.selection,self.colorStyle)
	end
end


function selector:selectAll()
	self.selection=editor.world:getBodyList()
	if #self.selection==0 then self.selection=nil end
	self.selectIndex=1
end

function selector:clearSelection()
	self.selection=nil
	self.selectToggle=nil
end

function selector:inRect(x,y)
	if x==clamp(x,self.dragOX,self.dragTX) 
		and y==clamp(y,self.dragOY,self.dragTY) then
		return true
	end
end




function selector:dragSelect()

	if love.mouse.isDown(1) and not self.dragSelecting then
		self.dragOX,self.dragOY=mouseX,mouseY
		self.dragSelecting=true	
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif love.mouse.isDown(1) and self.dragSelecting then
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif not love.mouse.isDown(1) and self.dragSelecting then
		local selection={}
		local fixtureIndex={}
		for i,body in ipairs(editor.world:getBodyList()) do
			for i,fix in ipairs(body:getFixtureList()) do
				local shape=fix:getShape()
				if shape:type()=="CircleShape" then
					local x,y=body:getPosition()
					local r=shape:getRadius()
					if self:inRect(x,y) and self:inRect(x+r,y) and self:inRect(x-r,y)
						and self:inRect(x,y+r) and self:inRect(x,y-r) then
						table.insert(selection,body)
					end
				elseif shape:type()~="ChainShape" then
					local points={shape:getPoints()}
					local check=true
					for i=1,#points/2-1,2 do
						if not self:inRect(points[i]+body:getX(),points[i+1]+body:getY()) then
							check=false
							break
						end
					end
					if check then
						table.insert(selection, body)
					end
				end
			end
		end
		if selection[1] then
			self:clearSelection()
			self.selection=selection
		end
		self.dragSelecting=false
	end
end


function selector:click(key)

	if editor.bodyMode.dragMoving then return end


	if key=="l" then
		local selectTest={}
		for i,body in ipairs(editor.world:getBodyList()) do
			for i,fix in ipairs(body:getFixtureList()) do
				if fix:testPoint( editor.mouseX, editor.mouseY ) then
					if not table.getIndex(selectTest,body) then --避免重复加入同一个body
						table.insert(selectTest, body)
					end
				end
			end
		end
		if selectTest[1] then
			if  love.keyboard.isDown("lctrl") then
				
				if not self.selection then
					self.selection={}
				end

				local index=table.getIndex(self.selection,selectTest[1]) 
				if index then --避免重复加入同一个body
					table.remove(self.selection, index)
				else
					table.insert(self.selection, selectTest[1])
				end	

				self.selectIndex=1
				
			else
				self:clearSelection()
				self.selection={}
				self.selection[1]=selectTest[1]
				self.selectIndex=1
			end
			self.selectToggle=selectTest
		else
			--self.selection=nil
		end

	elseif key=="r" then
		
		if not self.selectToggle then return end
		self.selectIndex=self.selectIndex+1
		if not self.selectToggle[self.selectIndex] then self.selectIndex=1 end
		local target=self.selectToggle[self.selectIndex]
		
		
		table.remove(self.selection,1)
		table.insert(self.selection,1,target)
		

	end
end








return function(parent) 
	editor=parent
	return selector
end


--[[
	todo:
	new frame named component
	including

	lancher 一个刚体矩形，在内部可以生成一个物体，物体可以被指定为 标准刚体/爆炸/烟雾等 生成物体与本身不碰撞
			同时，对生成物体和本身施力
			拥有属性：bullet  rate key demand force 等
	bouncer  一个标准刚体和一组感受器，如果感受器与任何物体接触，则jumper的受反向力与被接触的物体速度变化量成正比。
			拥有属性：sensors jumpforce key demand等
	roller 一个标准刚体，在有指定按键时受转向力。
			拥有属性：key rollforce
	jumper 两个标准刚体，以prismatic和distance双重连接 在无按键时，保持distance 在指定按键时 连接失效

	jet 一个标准刚体，在有按键时 默认 w ，向正方向施加力，同时向反方向 制造烟雾

	mouseTurn 一个标准刚体，随鼠标方向转向。
		
	keyTurn 一个标准刚体，随按键 左右 或 a d  转向

	piston 两个刚体，做活塞运动


]]