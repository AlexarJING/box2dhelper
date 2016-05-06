local units={}
local editor

units.cam=require("libs.gamera").new(-5000,-5000,10000,10000)
units.cam:setWindow(w()-200,30,200,200)
units.cam:setScale(0.3)
units.cam:setPosition(0,0)

function units:draw()
	if self.target then
		self.cam:draw(function()
			love.graphics.setColor(255, 0, 0, 255)
			love.graphics.rectangle("line", -300, -299, 599, 599)
			love.graphics.line(-20,0,20,0)
			love.graphics.line(0,-20,0,20)

			editor.helper.draw({self.world:getBodyList()})
		end)
	end
end

function units:showPreview(text)
	if not text then self.target=nil ;return end
	local file = love.filesystem.newFile("units/"..text)
	file:open("r")
	self.target=loadstring(file:read())()
	file:close()
	self.world=love.physics.newWorld(0, 0, true)
	editor.helper.createWorld(self.world,self.target)
end



function units:save(text)
	if not editor.selector.selection then return end
	editor.action="save unit"
	love.filesystem.createDirectory("units")
	local data=editor.helper.getWorldData(editor.selector.selection)
	local file = love.filesystem.newFile("units/"..text..".lua")
	file:open("w")
	file:write(table.save(data))
	file:close()
end

function units:getSaveName()
	if not editor.selector.selection then return end
	editor.interface:createSaveUnitFrame()
end


function units:load(text)
	local file = love.filesystem.newFile("units/"..text)
	file:open("r")
	local tab=loadstring(file:read())()
	file:close()
	if not tab then return end
	editor.bodyMode.copied=tab
end

return function(parent) 
	editor=parent
	return units
end