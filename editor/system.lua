local system={}
local editor

system.undoStack={}
system.undoIndex=0
system.maxUndo=20



function system:clear()
	editor.world =love.physics.newWorld()
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
	self.undoStack[self.undoIndex]={event=editor.action,world=editor.helper.getWorldData(editor.world,0,0,editor)}
	if #self.undoStack>self.maxUndo then
		table.remove(self.undoStack, 1)
		self.undoIndex=self.maxUndo
	end
	for i=self.undoIndex+1,self.maxUndo  do
		self.undoStack[i]=nil
	end
	editor.interface.history:update()
end

function system:setWorld(arg)
	love.physics.setMeter(arg.meter)
	editor.meter=arg.meter
	editor.linearDamping=arg.linearDamping
	editor.angularDamping=arg.angularDamping
end

function system:undo()
	editor.log:push("undo")
	self.undoIndex=self.undoIndex-1
	if self.undoIndex<1 then self.undoIndex=1 end
	editor.world =love.physics.newWorld()
	editor.helper.createWorld(editor.world,self.undoStack[self.undoIndex].world)
	self:setWorld(self.undoStack[self.undoIndex].world.world)
	editor:cancel()
end

function system:redo()
	editor.log:push("redo")
	self.undoIndex=self.undoIndex+1
	if self.undoIndex>#self.undoStack then self.undoIndex=#self.undoStack end
	editor.world = love.physics.newWorld()
	editor.helper.createWorld(editor.world,self.undoStack[self.undoIndex].world)
	self:setWorld(self.undoStack[self.undoIndex].world.world)
	editor:cancel()
end

function system:returnTo(index)
	if not self.undoStack[index] then return end
	editor.log:push("return to histroy")
	self.undoIndex=index
	editor.world = love.physics.newWorld()
	editor.helper.createWorld(editor.world,self.undoStack[self.undoIndex].world)
	self:setWorld(self.undoStack[self.undoIndex].world.world)
	editor:cancel()
end

function system:copyProject(source)
	local files = love.filesystem.getDirectoryItems(source.."/units")
	if files then
		for i,name in ipairs(files) do
			local from = love.filesystem.newFile(source.."/units/"..name, "r")
			local to = love.filesystem.newFile(editor.currentProject.."/units/"..name, "w")
			to:write(from:read())
			from:close()
			to:close()
		end
	end
	local files = love.filesystem.getDirectoryItems(source.."/scenes")
	if files then
		for i,name in ipairs(files) do
			local from = love.filesystem.newFile(source.."/scenes/"..name, "r")
			local to = love.filesystem.newFile(editor.currentProject.."/scenes/"..name, "w")
			to:write(from:read())
			from:close()
			to:close()
		end
	end
	local files = love.filesystem.getDirectoryItems(source.."/textures")
	if files then
		for i,name in ipairs(files) do
			local from = love.filesystem.newFile(source.."/textures/"..name, "r")
			local to = love.filesystem.newFile(editor.currentProject.."/textures/"..name, "w")
			to:write(from:read())
			from:close()
			to:close()
		end
	end
end

function system:saveAsProject()
	if editor.currentProject=="default" then
		editor.log:push("can not save an empty project")
		return
	end

	local source=editor.currentProject
	self.saveFrom=source
	system:createSaveProjectFrame()
	editor.createTime=os.date("%c")
	
	
end

function system:saveProject()


	if editor.currentProject=="default" then
		system:newProject()
		return
	end
	
	local text=editor.currentProject
	love.filesystem.createDirectory(text.."/units")
	love.filesystem.createDirectory(text.."/scenes")
	love.filesystem.createDirectory(text.."/textures")
	local project = love.filesystem.newFile(text..".proj", "w")
	
	local data={
		projectName=editor.currentProject,
		currentScene=editor.currentScene,
		visible=editor.interface.visible,
		layout=editor.interface:getLayout(),
		keyconf=editor.keyconf,
		windowMode={love.window.getMode( )},
		createTime=editor.createTime,
		lastEditTime=os.date("%c"),
		groupIndex=editor.groupIndex,
		colorstyle = editor.helper.drawMode.defaultStyle
	}
	project:write(table.save(data))
	project:close()	
	
	editor.log:push("project saved")
	if self.saveFrom then
		local source=self.saveFrom
		self.saveFrom=nil
		system:copyProject(source)
	end
	editor.interface:reset()
	editor.interface.system:updateProj()
end


function system:newProject()
	system:createSaveProjectFrame()
	editor.createTime=os.date("%c")
	system:newScene()

end

function system:loadProject()

	if not editor.loadProject then
		system:createLoadProjectFrame()
		return
	end
	
	local file = love.filesystem.newFile(editor.loadProject ..".proj", "r")
	if not file then 
		editor.loadProject = nil
		system:newProject()
		return
	end

	local data = loadstring(file:read())()
	if not data then
		editor.loadProject = nil
		system:newProject()
		return
	end
	editor.currentProject=data.projectName
	editor.currentScene=data.currentScene
	system:loadScene(editor.currentScene..".scene")

	--editor.keyconf=data.keyconf
	--editor:keyBound()
	editor.createTime=data.createTime
	editor.lastEditTime=data.lastEditTime
	editor.groupIndex=data.groupIndex or 1
	editor.helper.drawMode.defaultStyle = data.colorstyle or editor.helper.drawMode.defaultStyle
	love.window.setMode(unpack(data.windowMode))
	
	editor.interface.layout=data.layout
	editor.interface.visible=data.visible
	editor.interface:reset()
	editor.loadProject=nil

end

function system:newScene()
	if editor.currentScene=="default" then
		system:clear()
		return
	end
	system:saveScene()
	system:clear()

	editor.currentScene="default"
	editor.interface.system:updateProj()

	--system:saveScene()
end



function system:saveScene()
	if editor.currentProject=="default" then
		editor.log:push("need to create a project")
		return
	end

	if editor.currentScene=="default" then
		system:createSaveSceneFrame()
		return
	end

	local file = love.filesystem.newFile(editor.currentProject.."/scenes/"..editor.currentScene..".scene","w")
	file:write(table.save(editor.system.undoStack[editor.system.undoIndex].world))
	file:close()
	editor.interface.system:updateProj()
	system:saveProject()
	editor.log:push("scene saved")
end

function system:loadScene(name,remainMode)
	if string.sub(name,-6,-1)~=".scene" then name=name..".scene" end
	local file = love.filesystem.newFile(editor.currentProject.."/scenes/"..name,"r")
	if not file then return end

	local data = loadstring(file:read())()
	local world = love.physics.newWorld(0, 0, false)
	editor.world=world
	editor.helper.createWorld(editor.world,data)
	editor.linearDamping=data.world.linearDamping
	editor.angularDamping=data.world.angularDamping
	editor.selector.selection=nil
	editor.currentScene=string.sub(name,1,-7)
	editor.interface.system:updateProj()
	if not remainMode then editor:changeMode("body") end
	editor.log:push("scene loaded")
	
end

function system:createSaveSceneFrame()
	local ui=editor.LoveFrames
	local frame =ui.Create("frame")
	frame:SetName("save the scene")
	frame:SetSize(300,80)
	frame:CenterWithinArea(0,0,w(),h())
	local input = ui.Create("textinput",frame)
	input:SetSize(280,30)
	input:SetPos(10,40)
	input:SetFocus(true)
	input.OnEnter=function()
		editor.currentScene=input:GetText()
		system:saveScene()
		input:Remove()
		frame:Remove()
	end
end

function system:createSaveProjectFrame()
	local ui=editor.LoveFrames
	local frame =ui.Create("frame")
	frame:SetName("save the project")
	frame:SetSize(300,80)
	frame:CenterWithinArea(0,0,w(),h())
	local input = ui.Create("textinput",frame)
	input:SetSize(280,30)
	input:SetPos(10,40)
	input:SetFocus(true)
	input.OnEnter=function()
		editor.currentProject=input:GetText()
		system:saveProject()
		input:Remove()
		frame:Remove()
	end
	editor.log:push("project saved")
end


function system:createLoadProjectFrame()
	local ui=editor.LoveFrames
	local files = love.filesystem.getDirectoryItems("")
	for i=#files,1,-1 do
		if string.sub(files[i],-5,-1)~=".proj" then
			table.remove(files, i)
		end
	end
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
				love.filesystem.remove( b:GetText() )
				list:Remove()
				frame:Remove()
				system:createLoadProjectFrame()
			else
				editor.loadProject=string.sub(b:GetText(),1,-6)
				system:loadProject()
				list:Remove()
				frame:Remove()
			end
		end
	end
end


return function(parent) 
	editor=parent
	return system 
end



