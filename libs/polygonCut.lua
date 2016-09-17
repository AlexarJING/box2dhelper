local lineCross = function (x1,y1,x2,y2,x3,y3,x4,y4)
	local denom, offset;         
	local x, y             
	a1 = y2 - y1;
	b1 = x1 - x2;
	c1 = x2 * y1 - x1 * y2;
	r3 = a1 * x3 + b1 * y3 + c1;
	r4 = a1 * x4 + b1 * y4 + c1;
	if ( r3 ~= 0 and r4 ~= 0 and ((r3 >= 0 and r4 >= 0) or (r3 < 0 and r4 < 0))) then
		return --none
	end
	a2 = y4 - y3;
	b2 = x3 - x4;
	c2 = x4 * y3 - x3 * y4;
	r1 = a2 * x1 + b2 * y1 + c2;
	r2 = a2 * x2 + b2 * y2 + c2;
	if (r1 ~= 0 and r2 ~= 0 and ((r1 >= 0 and r2 >= 0) or (r1 < 0 and r2 < 0))) then
		return --none
	end
	denom = a1 * b2 - a2 * b1;
	if ( denom == 0 ) then
		return true; -- one line
	end
	offset = denom < 0 and - denom / 2 or denom / 2;
	x = b1 * c2 - b2 * c1;
	y = a2 * c1 - a1 * c2;
  	return x / denom, y / denom
end



return function(verts,sx,sy,tx,ty)
	local entry
	local exit
	for i = 1 , #verts-1, 2 do
		local curX,curY = verts[i],verts[i+1]
		local nextX,nextY = verts[i+2] or verts[1],verts[i+3] or verts[2]
		local crossX,crossY = lineCross(curX,curY,nextX,nextY,sx,sy,tx,ty)
		if crossX then
			if not entry then
				entry = {
					x = crossX,
					y = crossY,
					pos = i
				}
			elseif not exit then
				exit = {
					x = crossX,
					y = crossY,
					pos = i
				}
			else
				error("check")
			end
		end
	end

	

	if entry and exit then
		local rt1 = {}
		table.insert(rt1,exit.x)
		table.insert(rt1,exit.y)
		local i = exit.pos + 2
		while true do
			if i > #verts then i = 1 end
			if i== entry.pos then
				table.insert(rt1,verts[i])
				table.insert(rt1,verts[i+1])
				table.insert(rt1,entry.x)
				table.insert(rt1,entry.y)
				break
			else			
				table.insert(rt1,verts[i])
				table.insert(rt1,verts[i+1])
			end
			i = i+2
		end
		
		local rt2 = {}
		table.insert(rt2,entry.x)
		table.insert(rt2,entry.y)
		local i = entry.pos + 2
		while true do
			if i== exit.pos then
				table.insert(rt2,verts[i])
				table.insert(rt2,verts[i+1])
				table.insert(rt2,exit.x)
				table.insert(rt2,exit.y)
				break
			else			
				table.insert(rt2,verts[i])
				table.insert(rt2,verts[i+1])
			end
			i = i+2
		end
		return rt1,rt2
	end	
end