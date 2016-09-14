function math.sign(x)
	if x>0 then return 1
	elseif x<0 then return -1
	else return 0 end
end

function table.push(tab,tab2)
	for i,v in ipairs(tab2) do
		table.insert(tab,v)
	end
end

function table.unshift(tab,tab2)
	for i,v in ipairs(tab2) do
		table.insert(tab,i,v)
	end
end

function table.reverse(tab)
	local len = #tab
	local rt = {}
	for i,v in ipairs(tab) do
		rt[len-i+1] = v
	end
	tab = rt
end

function table.copy(tab)
	return {unpack(tab)}
end

function math.distance(x1,y1,x2,y2)
	return math.sqrt((x1-x2)^2+(y1-y2)^2)
end
local lineCross = function (x1,y1,x2,y2,x3,y3,x4,y4)
	local denom, offset;         
	local x, y             

	a1 = y2 - y1;
	b1 = x1 - x2;
	c1 = x2 * y1 - x1 * y2;


	r3 = a1 * x3 + b1 * y3 + c1;
	r4 = a1 * x4 + b1 * y4 + c1;

	if ( r3 ~= 0 and r4 ~= 0 and ((r3 >= 0 and r4 >= 0) or (r3 < 0 and r4 < 0))) then
		return 
	end

	a2 = y4 - y3;
	b2 = x3 - x4;
	c2 = x4 * y3 - x3 * y4;

	r1 = a2 * x1 + b2 * y1 + c2;
	r2 = a2 * x2 + b2 * y2 + c2;

	if (r1 ~= 0 and r2 ~= 0 and ((r1 >= 0 and r2 >= 0) or (r1 < 0 and r2 < 0))) then
		return
	end

	denom = a1 * b2 - a2 * b1;

	if ( denom == 0 ) then
		return true;
	end

	offset = denom < 0 and - denom / 2 or denom / 2;

	x = b1 * c2 - b2 * c1;
	y = a2 * c1 - a1 * c2;
  	return x / denom, y / denom
end
local pointContain = function(x,y,polygon)
	local pX={}
	local pY={}
	
	for i = 1 , #polygon-1 ,2 do
		table.insert(pX, polygon[i])
		table.insert(pY, polygon[i+1])
	end


	local oddNodes=false
	local pCount=#pX
	local j=pCount
	for i=1,pCount do
		if ((pY[i]<y and pY[j]>=y) or (pY[j]<y and pY[i]>=y))
			and (pX[i]<=x or pX[j]<=x) then
			if pX[i]+(y-pY[i])/(pY[j]-pY[i])*(pX[j]-pX[i])<x then
				oddNodes=not oddNodes
			end
		end
		j=i
	end
	return oddNodes
end
local polygonArea = function(polygon) 
	local ax,ay = 0,0;
	local bx,by = 0,0;


	local area = 0;
	local fx , fy = polygon[1],polygon[2]

	for i = 3, #polygon-1 , 2 do
		local px,py = polygon[i-2],polygon[i-1]
		local cx,cy = polygon[i],polygon[i+1]
		ax = fx - cx
		ay = fy - cy
		bx = fx - px
		by = fy - py
		area = area +(ax*by) - (ay*bx)
	end

	
	return area/2
end

local Node = {}
function Node:new(x,y,alpha,intersection)
	local new = {
		x = x,
		y = y,
		next = nil,
		prev = nil,
		nextPoly =nil,
		neighbor = nil,
		intersect = intersection,
		entry = nil,
		visited = false,
		alpha = alpha or 0
	}
	setmetatable(new, self)
	self.__index = self
	return new
end

function Node:nextNonIntersection()
	local a = self
	while a and a.intersect do
		a = a.next
	end
	return a
end

function Node:last()
	local a = self
	
	while a.next and a.next~=self do
		a = a.next
	end
	return a
end

function Node:createLoop()
	local last = self:last()
	last.prev.next = self
	self.prev = last.prev
end

function Node:firstNodeOfIntersect()
	local a = self
	
	while true do
		a = a.next
		if not a then break end --should check error
		if a == self then break end
		if a.intersect and not a.visited then break end
	end
	
	return a
end

function Node:insertBetween(first,last)
	local a = first
	
	while a~=last and a.alpha<self.alpha do
		a = a.next
	end

	self.next = a
	self.prev = a.prev
	
	if self.prev  then
		self.prev.next = self
	end

	self.next.prev = self;
end

local function cleanList(verts)
	for i = #verts , 4 , -1 do
		if verts[i-3]== verts[i-1] and
			verts[i-2] == verts[i] then
			table.remove(verts, i)
			table.remove(verts,i-1)
		end
	end
	return verts
end

local function createList(verts)
	local first,current

	for i = 1, #verts-1 , 2 do
		if current then
			current.next = Node:new(verts[i],verts[i+1])
			current.next.prev = current
			current = current.next
		else
			current = Node:new(verts[i],verts[i+1])
			first = current
		end
	end

	local next = Node:new(first.x,first.y,1)--何意？current
	current.next = next 
	next.prev = current
	return first , current -- first and last
end


local function indentifyIntersections(subjectList, clipList)
		

	local found = false 
	local subject = subjectList
	
	while subject.next do
		if not subject.intersect then
			local clip = clipList
			while clip.next do
				if not clip.intersect then
					local subjectNext = subject.next:nextNonIntersection()
					local clipNext = clip.next:nextNonIntersection()
					local ax,ay = subject.x , subject.y
					local bx,by = subjectNext.x , subjectNext.y
					local cx,cy = clip.x , clip.y
					local dx,dy = clipNext.x, clipNext.y
					
					local x,y = lineCross(ax,ay,bx,by,cx,cy,dx,dy)
					
					if x and x~=true then
						found = true
						local alphaS = math.distance(ax,ay,x,y)/math.distance(ax,ay,bx,by)
						local alphaC = math.distance(cx,cy,x,y)/math.distance(cx,cy,dx,dy)
						
						local subjectInter = Node:new(x,y,alphaS,true)
						local clipInter = Node:new(x,y,alphaC,true)
						subjectInter.neighbor = clipInter
						clipInter.neighbor = subjectInter						
						subjectInter:insertBetween(subject,subjectNext)
						clipInter:insertBetween(clip,clipNext)

					end
				end
				clip = clip.next
			end

		end
		subject = subject.next
	end
	return found
end

local function indentifyIntersectionType(subjectList, clipList, clipPoly, subjectPoly, type)
	
	local se = pointContain(subjectList.x,subjectList.y,clipPoly)
	if type == "and" then se = not se end
	
	local subject = subjectList
	while subject do
		if subject.intersect then
			subject.entry = se
			se = not se
		end
		subject = subject.next
	end

	local ce = not pointContain(clipList.x,clipList.y,subjectPoly)
	if (type == "or") then ce = not ce end

	local clip = clipList
	while clip do
		if clip.intersect then
			clip.entry = ce
			ce = not ce
		end
		clip = clip.next
	end
end


local function collectClipResults(subjectList, clipList)
	subjectList:createLoop()
	clipList:createLoop()

	local walker , results = _ , {}
	

	while true do
		walker = subjectList:firstNodeOfIntersect()
		if walker == subjectList then break end
		local result = {}
		while true do
			if walker.visited  then break end
			walker.visited = true
			walker = walker.neighbor
			table.insert(result,walker.x)
			table.insert(result,walker.y)
			local forward = walker.entry
			while true do
				walker.visited = true
				walker = forward and walker.next or walker.prev
				if walker.intersect then
					break
				else
					table.insert(result,walker.x)
					table.insert(result,walker.y)
				end
			end
		end

		table.insert(results,result)
	end

	return results
end


local function polygonBoolean(subjectPoly, clipPoly, operation)

	local subjectList ,last = createList(subjectPoly)
	local clipList ,last2= createList(clipPoly)

    local subject, clip, res
    local isects = indentifyIntersections(subjectList, clipList);


	if isects then
	    indentifyIntersectionType(
	      subjectList,
	      clipList,
	      clipPoly,
	      subjectPoly,
	      operation)
		
		res = collectClipResults(subjectList, clipList)	
	else 
		local inner = pointContain(subjectPoly[1],subjectPoly[2],clipPoly)
    	local outer = pointContain(clipPoly[1],clipPoly[2],subjectPoly)
		res = {}

		if operation == "or" then
			if not inner and not outer then
				table.push(res,table.copy(subjectPoly))
				table.push(res,table.copy(clipPoly))
			elseif inner then
				table.push(res,table.copy(clipPoly))
			elseif outer then
				table.push(res,table.copy(subjectPoly))
			end
		elseif operation == "and" then
			if inner then
				table.push(res,table.copy(subjectPoly))
			elseif outer then
				table.push(res,table.copy(clipPoly))
			else
				--error("oops")
			end
		elseif operation == "not" then	
			local sclone = table.copy(subjectPoly)
			local cclone = table.copy(clipPoly)

			local sarea = polygonArea(sclone)
			local carea = polygonArea(cclone)

			if math.sign(sarea) == math.sign(carea) then
				if outer then
					table.reverse(cclone)
				elseif inner then
					table.reverse(sclone)
				end
			end

			table.push(res,sclone)

			if math.abs(sarea)> math.abs(carea) then
				table.push(res,cclone)
			else
				table.unshift(res,cclone)
			end
		end
		
	end

	return res
end

return polygonBoolean