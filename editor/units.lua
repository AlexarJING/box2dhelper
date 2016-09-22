local units={}
local editor

units.cam=require("libs.gamera").new(-5000,-5000,10000,10000)
units.cam:setWindow(w()-200,30,200,200)
units.cam:setScale(0.3)
units.cam:setPosition(0,0)

function units:draw()
	if self.target then
		self.cam:setWindow(editor.interface.unit.frame.x+
				editor.interface.unit.frame.width,
				editor.interface.unit.frame.y
				,200,200)
		self.cam:draw(function()
			love.graphics.setColor(100, 100, 100, 255)
			love.graphics.rectangle("fill", -300, -299, 599, 599)
			love.graphics.setColor(255, 0, 0, 255)
			love.graphics.rectangle("line", -300, -299, 599, 599)
			
			love.graphics.line(-20,0,20,0)
			love.graphics.line(0,-20,0,20)
			editor.helper.draw(self.world:getBodyList())
		end)
	end
end

function units:showPreview(text)
	if not text then self.target=nil ;return end
	local file = love.filesystem.newFile(editor.currentProject.."/units/"..text)
	file:open("r")
	self.target=loadstring(file:read())()
	file:close()
	self.world=love.physics.newWorld(0, 0, true)
	editor.helper.createWorld(self.world,self.target)
end



function units:save()
	if not editor.state=="body" then return end
	if not editor.selector.selection then return end
	editor.action="save unit"
	
	if not editor.saveUnit then 
		self:createSaveFrame()
		return
	end
	local name=editor.saveUnit

	editor.groupIndex=editor.groupIndex+1
	for i,body in ipairs(editor.selector.selection) do
		for i,fixture in ipairs(body:getFixtureList()) do
			fixture:setGroupIndex(-editor.groupIndex)
		end
	end
	local data=editor.helper.getWorldData(editor.selector.selection)
	local file = love.filesystem.newFile(editor.currentProject.."/units/"..name..".lua")
	file:open("w")
	file:write(table.save(data))
	file:close()
	editor.saveUnit=nil

end


function units:createSaveFrame()
	local frame =editor.LoveFrames.Create("frame")
	frame:SetName("save unit...")
	frame:SetSize(300,80)
	frame:CenterWithinArea(0,0,w(),h())
	local input = editor.LoveFrames.Create("textinput",frame)
	input:SetSize(280,30)
	input:SetPos(10,40)
	input:SetFocus(true)
	input.OnEnter=function()
		editor.saveUnit=input:GetText()
		units:save(text)
		input:Remove()
		frame:Remove()
		editor.interface.unit.frame:Remove()
		editor.interface.unit:create()
	end
end




function units:load(text)
	local file = love.filesystem.newFile(editor.currentProject.."/units/"..text)
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