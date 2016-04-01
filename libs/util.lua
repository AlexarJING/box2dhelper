Pi=math.pi
love.system.run=love.system.openURL
lg = love.graphics
lk = love.keyboard
lm = love.math
function w() return lg.getWidth() end
function h() return lg.getHeight() end


function love.graphics.hexagon(mode, x,y,l)
	local i=(l/2)*3^0.5
	love.graphics.polygon(mode, x,y,x+l,y,x+1.5*l,y+i,x+l,y+2*i,x,y+2*i,x-l*0.5,y+i)
end
function math.getDistance(x1,y1,x2,y2)
   return ((x1-x2)^2+(y1-y2)^2)^0.5
end
function math.axisRot(x,y,rot)
	return math.cos(rot)*x-math.sin(rot)*y,math.cos(rot)*y+math.sin(rot)*x
end

function math.axisRot_P(x,y,x1,y1,rot)
  x=x -x1
  y=y- y1
  local xx=math.cos(rot)*x-math.sin(rot)*y
  local yy=math.cos(rot)*y+math.sin(rot)*x
  return xx+x1,yy+y1
end

function math.sign(x)
	if x>0 then return 1
	elseif x<0 then return -1
	else return 0 end
end
function math.getRot(x1,y1,x2,y2) --p1->p2 direction
	if x1==x2 and y1==y2 then return 0 end 
	local angle=math.atan((x1-x2)/(y1-y2))
	if y1-y2<0 then angle=angle-math.pi end
	if angle>0 then angle=angle-2*math.pi end
	if angle==0 then return 0 end
	return -angle
end

function love.graphics.randomColor()
	local r=math.random(0,255)
	local g=math.random(0,255)
	local b=math.random(0,255)
	return {r,g,b,255}
end
function math.polygonTrans(x,y,rot,size,v)
	local tab={}
	for i=1,#v/2 do
		tab[2*i-1],tab[2*i]=math.axisRot(v[2*i-1],v[2*i],rot)
		tab[2*i-1]=tab[2*i-1]*size+x
		tab[2*i]=tab[2*i]*size+y
	end
	return tab
end
function math.randomPolygon(count,size)
	local v={}
	local rt={}
	local lastK=0
	local lastX=0
	local lastY=0
	local lastRad=0
	local v_c=count
	for i=1,v_c do
		v[i]={}
		v[i].x=love.math.random(-50,50)*size
		v[i].y=love.math.random(-50,50)*size
	end
	local maxY=-50*size
	local oK=0
	for k,v in pairs(v) do
		if v.y>maxY then
			maxY=v.y
			oK=k
		end	
	end
	lastK=oK
	lastX=v[lastK].x
	lastY=v[lastK].y
	table.insert(rt,v[lastK].x)
	table.insert(rt,v[lastK].y)
	local i=0
	while i<100 do
		i=i+1
		local minRad=2*math.pi
		local minK=0
		for k,v in pairs(v) do
			local rad=math.getRot(lastX,lastY,v.x,v.y,true)
			if rad and rad>lastRad then
				if rad<minRad then
					minRad=rad
					minK=k
				end
			end
		end
		if minK==maxK or minK==0 then return rt end
		lastK=minK
		lastRad=minRad
		lastX=v[lastK].x
		lastY=v[lastK].y
		table.insert(rt,v[lastK].x)
		table.insert(rt,v[lastK].y)
	end
end
function math.round(num, n)
	if n > 0 then
		local scale = math.pow(10, n-1)
		return math.floor(num * scale + 0.5) / scale
	elseif n < 0 then
		local scale = math.pow(10, n)
		return math.floor(num * scale + 0.5) / scale
	elseif n == 0 then
		return num
	end
end
function math.clamp(a,low,high) --取三者中间的
	--if a>math.pi then a=a-2*math.pi; end
	return math.max(low,math.min(a,high))
end

function math.getLoopDist(p1,p2,loop)
	loop=loop or 2*Pi
  local dist=math.abs(p1-p2)
	local dist2=loop-math.abs(p1-p2)
  if dist>dist2 then dist=dist2 end
	return dist
end

function table.getIndex(tab,item)
	for k,v in pairs(tab) do
		if v==item then return k end
	end
end

function table.removeItem(tab,item)
   table.remove(tab,table.getIndex(tab,item))
end

function string.split(str,keyword)
	local tab={}
	local index=1
	local from=1
	local to=1
	while true do
		if string.sub(str,index,index)==keyword then
			to=index-1
			if from>to then 
				table.insert(tab, "")
			else
				table.insert(tab, string.sub(str,from,to))
			end
			from=index+1
		end
		index=index+1
		if index>string.len(str) then
			if from<=string.len(str) then
				table.insert(tab, string.sub(str,from,string.len(str)))
			end
			return tab
		end
	end
end

function table.copy(st,copyto,ifcopyfunction)
	copyto=copyto or {}
	for k, v in pairs(st or {}) do
		if type(v) == "table" then
			copyto[k] = table.copy(v,copyto[k])          
		elseif type(v) == "function" then 
			if ifcopyfunction then
				copyto[k] = v
			end
		else 
			copyto[k] = v
		end
	end
	return copyto
end

function string.generateName(num,seed)
   local list = {}
   list[1] = {{'b','c','d','f','g','h','j','l','m','n','p','r','s','t','v','x','z','k','w','y'},{'qu','th','ll','ph'}} --21,4
   list[2] = {'a','e','i','o','u'} --v
   random = love.math.newRandomGenerator(os.time())
   random:setSeed(love.math.random(1,9999))
   local first = random:random(2)
   local name = ''
   local char = ''
   local nchar = ''
   --creates first letter(s)
   if first == 2 then --v
	  for i=1, random:random(2) do
		 char = list[2][random:random(#list[2])]
		 if i == 2 then
			while char == name do
			   char = list[2][random:random(#list[2])]
			end
			name = name .. char
		 else
			name = name .. char
		 end
	  end
   else --c
	  if random:random(2) == 1 then
		 for i=1, random:random(2) do
			char = list[1][1][random:random(#list[1][1])]
			if i == 2 then
			   while char == name do
				  char = list[1][1][random:random(#list[1][1])]
			   end
			   name = name .. char
			else
			   name = char
			end
		 end
	  else
		 char = list[1][2][random:random(#list[1][2])]
		 if char == 'qu' then
			nchar = list[2][random:random(2,3)]
			first = 2
		 end
		 name = char .. nchar
	  end
   end

   --creates the rest of the name
   local add = ''
   for i=1,num do
	  first = first == 1 and 2 or 1 -- change between v and c
	  add = ''
	  if first == 2 then --v
		 for i=1, random:random(2) do
			char = list[2][random:random(#list[2])]
			if i == 2 then
			   while char == add do
				  char = list[2][random:random(#list[2])]
			   end
			   add = add .. char
			else
			   add = add .. char
			end
		 end
	  else --c
		 if random:random(2) == 1 then
			for i=1, random:random(2) do
			   char = list[1][1][random:random(#list[1][1])]
			   if i == 2 then
				  while char == add do
					 char = list[1][1][random:random(#list[1][1])]
				  end
				  add = add .. char
			   else
				  add = add .. char
			   end
			end
		 else
			char = list[1][2][random:random(#list[1][2])]
			if char == 'qu' then
			   nchar = list[2][random:random(2,3)]
			end
			add = char .. nchar
		 end
	  end
	  name = name .. add
   end

   return name
end
function table.save(tab,name)
	name=name or "test"
	local output="local "..name.."=\n"
	local function ergodic(target,time)
		time=time+1
		output=output.."{\n"
		for k,v in pairs(target) do
			output=output .. string.rep("\t",time)
			if type(v)=="table" then
				if type(k)=="number" then
					output=output.."["..k.."]".."="
				elseif type(k)=="string" then
					output=output.."[\""..k.."\"]="
				end 
				ergodic(v,time)
				output=output .. string.rep("\t",time)
				output=output.."},\n"
			elseif type(v)=="string" then
				if type(k)=="number" then
					output=output.."["..k.."]".."=\""..v.."\",\n"
				elseif type(k)=="string" then
					output=output.."[\""..k.."\"]=\""..v.."\",\n"
				end 
			elseif type(v)=="number" or type(v)=="boolean" then
				if type(k)=="number" then
					output=output.."["..k.."]".."="..tostring(v)..",\n"
				elseif type(k)=="string" then
					output=output.."[\""..k.."\"]="..tostring(v)..",\n"
				end 
			end
		end
	end
	ergodic(tab,0)
	output=output.."}"
	return output 
end

function math.pointTest(x,y,verts)
	local pX={}
	local pY={}
	for i=1,#verts,2 do
		table.insert(pX, verts[i])
		table.insert(pY, verts[i+1])
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

function math.pointTest_xy(x,y,pX,pY)
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


function math.polar(x,y) 
  return math.getDistance(x,y,0,0),math.atan2(y, x)
end

function math.cartesian(r,phi)
  return r*math.cos(phi),r*math.sin(phi)
end


function math:RGBtoHSV(r,g,b)
  local max=math.max(r,g,b)
  local min=math.min(r,g,b)
  local d=max-min
  local v=max
  local s
  if v==0 then 
	s=0 
  else 
	s=1-min/max
  end
  local h=0
  if d~=0 then
	if r==max then
	  h=(g-b)/d
	elseif g==max then
	  h=2+(b-r)/d
	elseif b==max then 
	  h=4+(r-g)/d
	end
	h=h*60
	if h<0 then h=h+360 end
  end
  return h,s,v

end

function math.HSVtoRGB(h,s,v)
  local r,g,b
  local x,y,z
  if s==0 then
	r=v;g=v;b=v
  else
	h=h/60
	i=math.floor(h)
	f=h-i
	x=v*(1-s)
	y=v*(1-s*f)
	z=v*(1-s*(1-f))
  end   
  if i==0 then
	r=v;g=z;b=x
  elseif i==1 then
	r=y;g=v;b=x
  elseif i==2 then
	r=x;g=v;b=z
  elseif i==3 then
	r=x;g=y;b=v
  elseif i==4 then
	r=z;g=x;b=v
  elseif i==5 then
	r=v;g=x;b=y
  else
	r=v;g=z;b=x
  end
  return math.floor(r),math.floor(g),math.floor(b)
end





function love.graphics.drawLightning(x1,y1,x2,y2,displace,curDetail)
  if displace < curDetail then
	  love.graphics.line(x1, y1, x2, y2)
  else 
	local mid_x = (x2+x1)/2;
	local mid_y = (y2+y1)/2;
	mid_x = mid_x+(love.math.random()-.5)*displace;
	mid_y = mid_y+(love.math.random()-.5)*displace;
	love.graphics.drawLightning(x1,y1,mid_x,mid_y,displace/2,curDetail);
	love.graphics.drawLightning(x2,y2,mid_x,mid_y,displace/2,curDetail);
  end
end



function love.graphics.handwrite_line(displace,curDetail,...)
  local lines={...}
  if #lines%2~=0 then error("must be 2x") end
  for i=1, #lines/2-1 do
	local px,py=lines[2*i-1],lines[2*i]
	local px2,py2=lines[2*i+1],lines[2*i+2]
	love.graphics.drawLightning(px,py,px2,py2,displace,curDetail)
  end
end



function table.insertM(tab,...)
  for i,v in ipairs({...}) do
	table.insert(tab, v)
  end
end


function math.pointToLine(a,b,c,x,y)
  return math.abs(a*x+b*y+c)/math.sqrt(a*a+b*b)
end


--source 必须包含.x,.y作为起始坐标，.rot为发射角
--toTest为待检测table 必须包含 .x,.y,.r作为碰撞球
function math.raycast(source,toTest) 
  local x1,y1=source.x,source.y
  local x2,y2
  local dist
  local dir=source.rot
  local tan=math.tan(dir)
  local a=tan
  local b=-1
  local c=-x1*tan+y1
  local rt={}
  for i,v in ipairs(toTest) do
	  x2,y2=v.x,v.y
	  dist=math.pointToLine(a,b,c,x2,y2)
	  if math.sign(math.cos(dir))~=math.sign(x2-x1) and math.sign(math.sin(dir))~=math.sign(y2-y1) then
		dist=math.tan(Pi/2)
	  end
	  if dist<= v.r then
		local a2,b2,c2=math.vertToLine(a,b,c,x2,y2)
		local cx,cy=math.crossPoint(a,b,c,a2,b2,c2)
		table.insert(rt, {v,cx,cy})
	  end
  end
  return rt
end


function math.unitAngle(angle)  --convert angle to 0,2*Pi
  angle=math.fmod(angle,2*Pi+0.0000000001)
  --angle= (angle/(2*Pi) - math.floor(angle/(2*Pi)))*2*Pi
  angle= angle<0 and angle+2*Pi or angle
  return angle
end

function math.vertToLine(a,b,c,x,y) --过已知点垂线公式
  local a2=math.abs(b/a)==1/0 and math.sign(b/a)*math.tan(Pi/2) or b/a
  return a2,-1,y-a2*x
end


function math.crossPoint(a1,b1,c1,a2,b2,c2) --两线交点公式
  return (b1*c2-b2*c1)/(a1*b2-a2*b1), (a1*c2-a2*c1)/(b1*a2-b2*a1)
end



function debug.tracebackex()    --局部变量
local ret = ""    
local level = 2    
ret = ret .. "stack traceback:\n"    
while true do    
   --get stack info    
   local info = debug.getinfo(level, "Sln")    
   if not info then break end    
   if info.what == "C" then                -- C function    
	ret = ret .. tostring(level) .. "\tC function\n"    
   else           -- Lua function    
	ret = ret .. string.format("\t[%s]:%d in function `%s`\n", info.short_src, info.currentline, info.name or "")    
   end    
   --get local vars    
   local i = 1    
   while true do    
	local name, value = debug.getlocal(level, i)    
	if not name then break end    
	ret = ret .. "\t\t" .. name .. " =\t" .. tostringex(value, 3) .. "\n"    
	i = i + 1    
   end      
   level = level + 1    
end    
return ret    
end

function table.state(tab)
	local output={}
	local function ergodic(target,name)
		for k,v in pairs(target) do
			if type(v)=="table" then
				name=name.."/"..k
				output[name]=#v
				print(name,#v)
				ergodic(v,name)
			end
		end
	end
	ergodic(tab,tostring(tab))
	return output 
end

function table.safeRemove(tab,index)
	local v=tab[#tab]
	tab[index]=v
	tab[#tab]=nil
end

function table.isEmpty(tab)
	for k,v in pairs(tab) do
		return false
	end
	return true
end

function string.toTable(str)
	local tab={}
	for uchar in string.gfind(str, "[%z\1-\127\194-\244][\128-\191]*") do tab[#tab+1] = uchar end
	return tab
end


function string.sub_utf8(s, n)    
	local dropping = string.byte(s, n+1)    
	if not dropping then return s end    
	if dropping >= 128 and dropping < 192 then    
		return string.sub_utf8(s, n-1)    
	end    
	return string.sub(s, 1, n)    
end  

local _SetStencil=love.graphics.setStencil
function love.graphics.setStencil(func)
	if  _SetStencil then 
		_SetStencil(func)
	else
		if func then
			love.graphics.stencil(func)
			love.graphics.setStencilTest("greater", 0)
		else
			love.graphics.setStencilTest()
		end
	end
end


function love.math.createEllipse(rx,ry,segments)
	segments = segments or 30
	local vertices = {}
	for i=0, segments do
		local angle = (i / segments) * math.pi * 2
		local x = math.cos(angle)*rx
		local y = math.sin(angle)*ry
		table.insert(vertices, x)
		table.insert(vertices, y)
	end
 	
	return vertices
end

