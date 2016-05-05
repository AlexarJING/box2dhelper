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


function interface:init()
	ui=editor.LoveFrames
	interface.system=require "ui/system"(editor)
	interface.build= require "ui/build"(editor)
	interface.help=require "ui/help"(editor)
	interface.about=require "ui/about"(editor)
	interface.history=require "ui/history"(editor)
	interface.property= require "ui/property"(editor)
	interface.unit = require "ui/unit"(editor)
	interface.world = require "ui/world"(editor)
	interface.joint=require "ui/joint"(editor)
	interface.fileMenu= require "ui/fileMenu"(editor)
	interface.editMenu= require "ui/editMenu"(editor)

	interface.system:create()
	interface.build:create()
	interface.joint:create()
	interface.unit:create()
	interface.history:create()
	interface.fileMenu:create()
	interface.editMenu:create()
end

function interface:update(dt)
	self.property:update()
	self.unit:update()
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


return function(parent) 
	editor=parent
	return interface
end