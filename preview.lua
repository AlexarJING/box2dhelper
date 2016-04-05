local preview={}


self.preview.cam=require("libs.gamera").new(-5000,-5000,10000,10000)
	self.preview.world=love.physics.newWorld(0, 9.8*64, false)
	self.preview.cam:setWindow(w()-300,0,300,300)
	self.preview.cam:setScale(0.3)
	self.preview.cam:setPosition(0,0)

function preview:draw()
	self.preview.cam:draw(function()
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.rectangle("line", -300, -299, 599, 599)
		love.graphics.line(-20,0,20,0)
		love.graphics.line(0,-20,0,20)
		helper.draw(self.preview.world)
	end)

end

function editor:switchPreview(slot)
	if not self.units[slot] then return end
	self.preview.world=love.physics.newWorld(0, 9.8*64, false)
	helper.createWorld(self.preview.world,self.units[slot])
end