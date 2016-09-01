local matcat = {}

local cat={
"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
".","0","1","2","3","4","5","6","7","8","9",",","%","'","&","!"	,"=","\\","*","-",":","+","/"," "
}

--[[
cat.print("ABCDEFGHIJKLMNOPQRSTUVWXYZ",500,500,5)
cat.print("abcdefghijklmnopqrstuvwxyz",500,600,5)
cat.print(".0123456789,%'&!=\\-=:+*/",500,700,5)
]]


function matcat.new(path)
	matcat.dictionary = {}
	local catIndex=0
	local index=0
	local lines={}
	for line in  love.filesystem.lines(path) do
		index = index+1
		if index<=5 then
			lines[index] = string.sub(line,6,-1)
		end
		if index==7 then
			index=0
			catIndex=catIndex+1
			local c = {}

			for x=1,5 do
				c[x]={}
				for y = 1,7 do
					c[x][y] =  string.sub(lines[x],y,y) =="1" and true or false
				end
			end
			matcat.dictionary[cat[catIndex]] = c
		end
	end
	matcat.pos=nil
	return matcat
end

function matcat.getPos(str,bx,by,size)
	local pos = {}
	for i = 1,string.len(str) do
		local t= string.sub(str,i,i)
		local p = matcat.dictionary[t]
		if p then	
			for x = 1, 5 do
				for y = 1,7 do
					if p[x][y] then
						table.insert(pos, {bx+(x-1)*size+(i-1)*size*6, by+(y-1)*size, size,size})
					end
				end
			end
		end
	end
	matcat.pos = pos
	return pos
end

function matcat.print(str,x,y,size)
	
	matcat.getPos(str,x,y,size)
	love.graphics.setColor(255, 0, 0, 255)
	for i,v in ipairs(matcat.pos) do
		love.graphics.rectangle("fill",unpack(v))
	end


end

return matcat