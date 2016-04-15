local system={}
local editor

system.undoStack={}
system.undoIndex=0
system.maxUndo=20

function system:saveToFile()
	editor.interface:createSaveWorldFrame()
end


function system:loadFromFile()
	editor.interface:createLoadWorldFrame()
end



function system:clear()
	editor.world =love.physics.newWorld(0, 9.8*64, false)
	editor:changeMode("body")
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
	if #self.undoStack>self.maxUndo then
		table.remove(self.undoStack, 1)
		self.undoIndex=self.maxUndo
	end
	for i=self.undoIndex+1,self.maxUndo  do
		self.undoStack[i]=nil
	end
	editor.interface:updateHistoryFrame()
end

function system:undo()
	editor.log:push("undo")
	self.undoIndex=self.undoIndex-1
	if self.undoIndex<1 then self.undoIndex=1 end
	editor.world =love.physics.newWorld(0, 9.8*64, false)
	editor.helper.createWorld(editor.world,self.undoStack[self.undoIndex].world)
	editor:cancel()
end

function system:redo()
	editor.log:push("redo")
	self.undoIndex=self.undoIndex+1
	if self.undoIndex>#self.undoStack then self.undoIndex=#self.undoStack end
	editor.world = love.physics.newWorld(0, 9.8*64, false)
	editor.helper.createWorld(editor.world,self.undoStack[self.undoIndex].world)
	editor:cancel()
end

function system:returnTo(index)
	if not self.undoStack[index] then return end
	editor.log:push("return to histroy")
	self.undoIndex=index
	editor.world = love.physics.newWorld(0, 9.8*64, false)
	editor.helper.createWorld(editor.world,self.undoStack[self.undoIndex].world)
	editor:cancel()

end


return function(parent) 
	editor=parent
	return system 
end



