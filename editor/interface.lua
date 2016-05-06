local interface={}
local editor
local ui
interface.visible={
	system=true,
	build=true,
	joint=true,
	unit=true,
	history=true,
	property=true,
	bg=true,
	log=true
}

interface.layout={}


function interface:init()
	ui=editor.LoveFrames
	--ui.config["DEBUG"]=true
	interface.system=require "ui/system"(editor)
	interface.build= require "ui/build"(editor)
	interface.help=require "ui/help"(editor)
	interface.about=require "ui/about"(editor)
	interface.history=require "ui/history"(editor)
	interface.property= require "ui/property"(editor)
	interface.unit = require "ui/unit"(editor)
	interface.world = require "ui/world"(editor)
	interface.joint=require "ui/joint"(editor)
	interface.info= require "ui/info"(editor)
	interface.scene= require "ui/scene"(editor)

	interface.fileMenu= require "ui/fileMenu"(editor)
	interface.editMenu= require "ui/editMenu"(editor)
	interface.modeMenu= require "ui/modeMenu"(editor)
	interface.layoutMenu= require "ui/layoutMenu"(editor)
	interface.viewMenu= require "ui/viewMenu"(editor)

	interface.system:create()
	interface.build:create()
	interface.joint:create()
	interface.unit:create()
	interface.history:create()
	interface.info:create()
	interface.scene:create()

	interface.fileMenu:create()
	interface.editMenu:create()
	interface.modeMenu:create()
	interface.layoutMenu:create()
	interface.viewMenu:create()
end

function interface:update(dt)
	self.property:update()
	self.info:update()
	ui.update(dt)
end



function interface:isHover()
	if ui.util.GetHover() and love.mouse.isDown(1) then
		self.hover=true
	elseif not ui.util.GetHover() and not love.mouse.isDown(1) then
		self.hover=false
	end
	if ui.inputobject then self.hover=true end
	return self.hover
end

function interface:getLayout()
	return {
	build={interface.build.frame:GetPos()},
	joint={interface.joint.frame:GetPos()},
	unit={interface.unit.frame:GetPos()},
	history={interface.history.frame:GetPos()},
	scene={interface.scene.frame:GetPos()},
	}	
end

function interface:resetLayout()
	interface.system.list:SetPos(0, 0)
	interface.system.list:SetSize(editor.W, 30)

	interface.info.panel:SetPos(0, editor.H-30)
	interface.info.panel:SetSize(editor.W, 30)

	interface.build.frame:SetPos(unpack(self.layout.build))
	interface.joint.frame:SetPos(unpack(self.layout.joint))
	interface.unit.frame:SetPos(unpack(self.layout.unit))
	interface.history.frame:SetPos(unpack(self.layout.history))
	interface.scene.frame:SetPos(unpack(self.layout.scene))

end


return function(parent) 
	editor=parent
	return interface
end