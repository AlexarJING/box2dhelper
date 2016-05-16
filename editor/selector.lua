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

function selector:inverseSelection()
	if not self.selection then self:selectAll() end
	local all=editor.world:getBodyList()
	for i,v in ipairs(self.selection) do
		if table.getIndex(all,v) then
			table.remove(all, i)
		end
	end
	self.selection=#self.selection==0 and nil or all
end

function selector:inRect(x,y)
	if x==clamp(x,self.dragOX,self.dragTX) 
		and y==clamp(y,self.dragOY,self.dragTY) then
		return true
	end
end




function selector:dragSelect()
	if love.keyboard.isDown("space") then return end
	if love.mouse.isDown(1) and not self.dragSelecting then
		self.dragOX,self.dragOY=mouseX,mouseY
		self.dragSelecting=true	
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif love.mouse.isDown(1) and self.dragSelecting then
		self.dragTX,self.dragTY=mouseX,mouseY
	elseif not love.mouse.isDown(1) and self.dragSelecting then
		local selection=selector:bodyAreaTest()
		if selection[1] then
			self:clearSelection()
			self.selection=selection
		end
		self.dragSelecting=false
	end
end


function selector:click(key)
	self:bodyPointTest(key)
end



function selector:bodyAreaTest()
	local selection={}
	for i,body in ipairs(editor.world:getBodyList()) do
		for i,fix in ipairs(body:getFixtureList()) do
			local shape=fix:getShape()
			if shape:type()=="CircleShape" then
				local x,y=body:getPosition()
				local r=shape:getRadius()
				if self:inRect(x,y) and self:inRect(x+r,y) and self:inRect(x-r,y)
					and self:inRect(x,y+r) and self:inRect(x,y-r) 
					and not table.getIndex(selection,body) then
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
				if check and not table.getIndex(selection,body) then
					table.insert(selection,body)
				end
			end
		end
	end
	return selection
end

function selector:bodyPointTest(key)
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
			self.selection=nil
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
