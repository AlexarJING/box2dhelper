local cam = require("libs.gamera").new(-5000,-5000,10000,10000)
local editor
cam:setPosition(0,0)

function cam:update()
	self:shakeProcess()
	--self:edgeMove()
	self:holdMove()
	if editor.state=="test" then
		self.state="test"
		if not editor.testMode.dragForcing then self:followSelection() end
	elseif editor.state~="test" and self.state=="test" then
		--cam:setPosition(0,0)
	end
	editor.mouseX,editor.mouseY = cam.x+ (love.mouse.getX()-w()/2)/cam.scale,cam.y+(love.mouse.getY()-h()/2)/cam.scale
end

function cam:shakeProcess()
	if self.shakeState==true then 
        local maxShake = 5
        local atenuationSpeed = 4
        self.shakeIntensity = math.max(0 , self.shakeIntensity - atenuationSpeed * 0.02)        
        if self.shakeIntensity > 0 then
            local x,y = self:getPosition()
            local dx,dy=(100 - 200*love.math.random()) * 0.02*self.shakeIntensity,
            (100 - 200*love.math.random()) * 0.02*self.shakeIntensity
            x = x + dx
            y = y + dy       
            self:setPosition(x,y)
        else
            self.shakeState=false
        end
    end

end


function cam:shake(int)
	self.shakeState=true
    self.shakeIntensity=int or 5
end

function cam:edgeMove()
	local x, y = love.mouse.getPosition()
	if x<=0 then self:move(-self.camMoveSpeed,0); self.camMoveSpeed=self.camMoveSpeed+0.5
	elseif x>=w()-1 then self:move(self.camMoveSpeed,0); self.camMoveSpeed=self.camMoveSpeed+0.5
	elseif y<=0 then self:move(0,-self.camMoveSpeed); self.camMoveSpeed=self.camMoveSpeed+0.5
	elseif y>=h()-1 then self:move(0,self.camMoveSpeed) ; self.camMoveSpeed=self.camMoveSpeed+0.5
	else self.camMoveSpeed=3
	end
end

function cam:holdMove()
	if love.mouse.isDown(1) and love.keyboard.isDown("space") and  not editor.interface:isHover() then
		if self.holdOX then
			self:move((self.holdOX-love.mouse.getX())/self.scale,(self.holdOY-love.mouse.getY())/self.scale)
			self.holdOX,self.holdOY= love.mouse.getPosition()
		else
			self.holdOX,self.holdOY= love.mouse.getPosition()
		end
	else
		self.holdOX=nil
	end
end

function cam:followSelection()
	self.target=editor.selector.selection and editor.selector.selection[1] or nil
	if self.target then
		cam:setPosition(self.target:getPosition())
	else
		--cam:setPosition(0,0)
	end
end

function cam:scrollScale(y)
	if editor.LoveFrames.util.GetHover() then return end

	if y>0 then
		self:setScale(self:getScale()*1.05)
	else
		self:setScale(self:getScale()*0.95)
	end
end

return function(parent) cam.editor=parent; editor=parent return cam end