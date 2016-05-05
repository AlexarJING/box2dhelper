local world={}
local editor
local ui
local interface

function world:createSaveWorldFrame()
	local frame =ui.Create("frame")
	frame:SetName("save to file...")
	frame:SetSize(300,80)
	frame:CenterWithinArea(0,0,w(),h())
	local input = ui.Create("textinput",frame)
	input:SetSize(280,30)
	input:SetPos(10,40)
	input:SetFocus(true)
	input.OnEnter=function()
		love.filesystem.createDirectory("save")
		local file = love.filesystem.newFile("save/"..input:GetText()..".lua")
		file:open("w")
		file:write(table.save(editor.system.undoStack[editor.system.undoIndex].world))
		file:close()
		input:Remove()
		frame:Remove()
	end
end




function world:createLoadWorldFrame()
	local files = love.filesystem.getDirectoryItems("save")
	local frame =ui.Create("frame")
	local count=#files
	frame:SetName("select a file to load...")
	frame:SetSize(300,30*count+30)
	frame:CenterWithinArea(0,0,w(),h())
	local list = ui.Create("list",frame)
	list:SetDisplayType("vertical")
	list:SetPos(5, 30)
	list:SetSize(280, 28*count)
	for i,v in ipairs(files) do
		local b= ui.Create("button")
		b:SetText(v)
		list:AddItem(b)
		b.OnClick=function()
			if love.keyboard.isDown("lctrl") and love.keyboard.isDown("lalt") then
				love.filesystem.remove( "save/"..b:GetText() )
				frame:Remove()
				system:loadFromFile()
			else
				local file = love.filesystem.newFile("save/"..b:GetText())
				file:open("r")
				local str=file:read()
				editor.world = love.physics.newWorld(0, 9.8*64, false)
				editor.helper.createWorld(editor.world,loadstring(str)())
				editor.selector.selection=nil
				frame:Remove()
			end
		end
	end


end
return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return world
end