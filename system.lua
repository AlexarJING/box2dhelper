local system={}
local editor
system.undoStack={}
system.undoIndex=0

function system:saveToFile()
	if self.popFrame then
		self.popList:Remove()
		self.popFrame:Remove() 
	end
	 
	local frame =ui.Create("frame")
	frame:SetName("save to file...")
	frame:SetSize(300,80)
	frame:CenterWithinArea(0,0,w(),h())
	local input = ui.Create("textinput",frame)
	input:SetSize(280,30)
	input:SetPos(10,40)
	input.OnEnter=function()
		love.filesystem.createDirectory("save")
		local file = love.filesystem.newFile("save/"..input:GetText()..".lua")
		file:open("w")
		file:write(table.save(self.undoStack[self.undoIndex].world))
		file:close()
		frame:Remove()
	end
end


function system:loadFromFile()

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
			local file = love.filesystem.newFile("save/"..b:GetText())
			file:open("r")
			local str=file:read()
			world = love.physics.newWorld(0, 9.8*64, false)
			love.physics.setMeter(64)
			self.world = world
			self.objects=helper.createWorld(self.world,loadstring(str)())
			self:clearSelection()
			frame:Remove()
		end
	end
end



function system:toggleUI()
	self.showUI=not self.showUI
	self.createFrame:SetVisible(self.showUI)
	if self.popFrame then
		self.popFrame:SetVisible(self.showUI)
	end
end



function system:pushUndo()
	
	self.undoIndex=self.undoIndex+1
	self.undoStack[self.undoIndex]={event=editor.action,world=editor.helper.getWorldData(editor.world)}
	if #self.undoStack>10 then
		table.remove(self.undoStack, 1)
		self.undoIndex=10
	end
	for i=self.undoIndex+1,10 do
		self.undoStack[i]=nil
	end

end

function system:undo()
	editor.log:push("undo")
	self.undoIndex=self.undoIndex-1
	if self.undoIndex<1 then self.undoIndex=1 end
	editor.world =love.physics.newWorld(0, 9.8*64, false)
	editor.helper.createWorld(editor.world,self.undoStack[self.undoIndex].world)
	editor.selector.selection=nil
end

function system:redo()
	editor.log:push("redo")
	self.undoIndex=self.undoIndex+1
	if self.undoIndex>#self.undoStack then self.undoIndex=#self.undoStack end
	editor.world = love.physics.newWorld(0, 9.8*64, false)
	editor.helper.createWorld(editor.world,self.undoStack[self.undoIndex].world)
	editor.selector.selection=nil
end

return function(parent) 
	editor=parent
	return system 
end



