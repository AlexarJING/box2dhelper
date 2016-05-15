--How to create the raycast GLSL code
--   call generateglslcaster(data)
--   returns a string of glsl code
--   the code contains a function called raycast

--How to call the raycast function
--bool raycast(in vec3 o,in vec3 d,out vec3 pos,out vec3 norm,out vec4 color)
--   Returns whether the ray hit anything
--   o is the origin of the ray
--   d is the direction of the ray
--   pos is where the ray hits the object
--   norm is the normal of where the ray hits the object
--   color is the color of the object the ray hit




--Groups nearest spheres together
--This make a log-time ray search
--Way better than octrees... if you don't need to move anything.
local function partition(spheres)
   if #spheres==1 then
      return spheres[1]
   else
      local newspheres={}
      local taken={}
      for i=1,#spheres do
         if not taken[i] then
            local b0=spheres[i]
            local bestr=1/0
            local bestj
            for j=i+1,#spheres do
               if not taken[j] then
                  local b1=spheres[j]
                  local r
                  local d=((b1.x-b0.x)*(b1.x-b0.x)
                     +(b1.y-b0.y)*(b1.y-b0.y)
                     +(b1.z-b0.z)*(b1.z-b0.z))^0.5
                  if d+b0.r<b1.r then
                     r=b1.r
                  elseif d+b1.r<b0.r then
                     r=b0.r
                  else
                     r=(d+b0.r+b1.r)/2
                  end
                  if r<bestr then
                     bestr=r
                     bestj=j
                  end
               end
            end
            if bestj then
               taken[i]=true
               taken[bestj]=true
               local b1=spheres[bestj]
               local d=((b1.x-b0.x)*(b1.x-b0.x)
                     +(b1.y-b0.y)*(b1.y-b0.y)
                     +(b1.z-b0.z)*(b1.z-b0.z))^0.5
               if d+b0.r<b1.r then
                  newspheres[#newspheres+1]={
                     a=b0;
                     b=b1;
                     x=b1.x;
                     y=b1.y;
                     z=b1.z;
                     r=b1.r;
                  }
               elseif d+b1.r<b0.r then
                  newspheres[#newspheres+1]={
                     a=b0;
                     b=b1;
                     x=b0.x;
                     y=b0.y;
                     z=b0.z;
                     r=b0.r;
                  }
               else
                  local c0=((b0.r-b1.r)/d+1)/2
                  local c1=((b1.r-b0.r)/d+1)/2
                  newspheres[#newspheres+1]={
                     a=b0;
                     b=b1;
                     x=c0*b0.x+c1*b1.x;
                     y=c0*b0.y+c1*b1.y;
                     z=c0*b0.z+c1*b1.z;
                     r=bestr;
                  }
               end
            end
         end
      end
      for i=1,#spheres do
         if not taken[i] then
            newspheres[#newspheres+1]=spheres[i]
         end
      end
      return partition(newspheres)
   end
end

--Bounds all the objects into minimum size spheres.
--Because the only datatype is sphere, this is kind of useless, but whatever.
--I _was_ planning on adding more shapes
local function makespheres(data)
   local spheres={}
   for i=1,#data do
      local g=data[i]
      if g.type=="sphere" then
         spheres[i]={
            x=g.cx;
            y=g.cy;
            z=g.cz;
            r=g.r;
            g=g;
         }
      end
   end
   return spheres
end

--code to check if the ray intersects a partition sphere
local pcheck=[[
$tco=$c-o;
$tu=dot(d,co);
$tv2=u*u-dot(co,co)+$r;
$tif(0<v2&&0<u+sqrt(v2)&&u-sqrt(v2)<bestt){
$t   //Optimization: &&0<u+sqrt(v2)&&u-sqrt(v2)<bestt
$t   //I haven't tested it but I think square roots are significantly faster than more if statements
]]

--Solves the intersection of the ray and a sphere object
--sets hit distance, hit position, hit norm, and color
local solvesphere=[[
$t   vec3 co=$c-o;
$t   float u=dot(d,co);
$t   float v2=u*u-dot(co,co)+$r;
$t   if(0<v2){
$t      float t=u-sqrt(v2);
$t      if(0<t&&t<bestt){
$t         bestt=t;
$t         pos=o+t*d;
$t         norm=normalize(pos-$c);
$t         color=$q;
$t      }
$t   }
]]

--recursively hardcodes the partition checks and object solvers.
local function writecode(p,tabs)
   tabs=(tabs or "").."\t"
   local s0=string.gsub(pcheck,"$(.)",function(c)
      if c=="c" then
         return "vec3("..p.x..","..p.y..","..p.z..")"
      elseif c=="r" then
         return p.r*p.r
      elseif c=="t" then
         return tabs
      end
   end)
   local g=p.g
   if g then
      if g.type=="sphere" then
         local s1=string.gsub(solvesphere,"$(.)",function(c)
            if c=="c" then
               return "vec3("..g.cx..","..g.cy..","..g.cz..")"
            elseif c=="r" then
               return g.r*g.r
            elseif c=="t" then
               return tabs
            elseif c=="q" then
               return "vec4("..g.cr..","..g.cg..","..g.cb..",1)"
            end
         end)
         return s0..s1..tabs.."}\n"
      --elseif g.type=="convexmesh" then LOLOLOL Not going to happen
      end
   else
      return s0..writecode(p.a,tabs)..writecode(p.b,tabs)..tabs.."}\n"
   end
end

--Makes the glsl ray caster from the given data
local function generateglslcaster(data)
   local part=partition(makespheres(data))
   return [[
bool raycast(in vec3 o,in vec3 d,out vec3 pos,out vec3 norm,out vec4 color){
   d=normalize(d);
   float bestt=1.0f/0.0f;
   vec3 co;
   float u;
   float v2;
]]..writecode(part)..[[
   return bestt<1.0/0.0;
}
]]
end







--Trash code after this point.








--Make a bunch of spheres.
local data={}
for i=1,64 do
   --shitty non-uniform distribution.
   local cx=math.random()-0.5
   local cy=math.random()-0.5
   local cz=math.random()-0.5
   local c=7.5/(cx*cx+cy*cy+cz*cz)^0.5
   cx,cy,cz=c*cx,c*cy,c*cz

   data[i]={
      type="sphere";
      cx=cx;
      cy=cy;
      cz=cz;
      cr=math.random();
      cg=math.random();
      cb=math.random();
      r=math.random();
   }
end

data[65]={
   type="sphere";
   cx=0;
   cy=0;
   cz=0;
   cr=0.25;
   cg=0.25;
   cb=0.75;
   r=5;
}




--Create the caster
local caster=generateglslcaster(data)
--Create the tracer
--This is the part you rewrite to make less cruddy
local effecttracer=[[

extern float w=1600;
extern float h=800;
extern vec3 cp=vec3(0,0,0);
extern vec3 cx=vec3(1,0,0);
extern vec3 cy=vec3(0,1,0);
extern vec3 cz=vec3(0,0,1);
extern vec3 lightdir=normalize(vec3(1,1,1));

vec4 effect( vec4 _color, Image texture, vec2 p, vec2 screen_coords )
{
   vec3 throwaway3;
   vec4 throwaway4;
   vec3 pos=cp;
   //Notice how I'm not subtracting cz. It's because left hand rule is for cool peeps.
   vec3 dir=w/h*(2*p.x-1)*cx+(1-2*p.y)*cy+cz;
   vec3 norm;
   vec4 color;
   vec4 sumcolor=vec4(0,0,0,1);
   vec4 mulcolor=vec4(1,1,1,1);
   for(int i=0;i<10;i++){
      bool hit=raycast(pos,dir,pos,norm,color);
      if(!hit){
         return sumcolor;
      }
      //Some craptastic light stuff.
      hit=raycast(pos,lightdir,throwaway3,throwaway3,throwaway4);
      if(!hit){
         sumcolor+=0.5*max(0,dot(norm,lightdir))*mulcolor*color;
      }
      mulcolor*=color;
      dir-=2*dot(dir,norm)*norm;
   }
   return sumcolor;
}
]]

--Compile the fragment shader
local effect=love.graphics.newShader(caster..effecttracer)
















--In case you want to do something cool, hve a canvas
local canvas=love.graphics.newCanvas(800,600,"hdr")
love.graphics.setShader(effect)

--Position and angles... sort of.
local pos={10,10,10}
local mx,my=0,0

local sin=math.sin
local cos=math.cos
local function anglesyx(x,y)
   local cx,sx=cos(x),sin(x)
   local cy,sy=cos(y),sin(y)
   --Inefficient. Oh well. This is trash code.
   return {cy,0,-sy},{sx*sy,cx,cy*sx},{cx*sy,-sx,cx*cy}
end

function love.draw()
   love.graphics.draw(canvas)
end

love.mouse.setRelativeMode(true)

function love.mousemoved(x,y,dx,dy)
   mx=mx+dx
   my=my+dy
   local cx,cy,cz=anglesyx(my/256,mx/256)
   effect:send("cx",cx)
   effect:send("cy",cy)
   effect:send("cz",cz)
end

local t=0
function love.update(dt)
   t=t+dt
   effect:send("lightdir",{0.5^0.5*sin(t),0.5^0.5,0.5^0.5*cos(t)})
   if love.keyboard.isDown("escape") then
      love.event.quit()
   end
   local cx,cy,cz=anglesyx(my/256,mx/256)
   local dx=0;
   local dz=0;
   if love.keyboard.isDown("w") then
      dz=dz+1
   end
   if love.keyboard.isDown("a") then
      dx=dx-1
   end
   if love.keyboard.isDown("s") then
      dz=dz-1
   end
   if love.keyboard.isDown("d") then
      dx=dx+1
   end
   local d2=dx*dx+dz*dz
   if 0<d2 then
      local d=d2^0.5
      dx=dx/d
      dz=dz/d
   end
   if love.keyboard.isDown("lshift") then
      dx=dx/16
      dz=dz/16
   end
   pos[1]=pos[1]+dt*4*(dx*cx[1]+dz*cz[1])
   pos[2]=pos[2]+dt*4*(dx*cx[2]+dz*cz[2])
   pos[3]=pos[3]+dt*4*(dx*cx[3]+dz*cz[3])
   effect:send("cp",pos)
end