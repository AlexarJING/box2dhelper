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
	log=true,
	info=true,
	scene=true,
	grid=true,
}

interface.layout={
	build={10,100},
	joint={10,400},
	unit={100,100},
	history={100,400},
	property={1000,200},
	scene={300,100},
}


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
	interface.joint=require "ui/joint"(editor)
	interface.info= require "ui/info"(editor)
	interface.scene= require "ui/scene"(editor)
	interface.tutorial = require "ui/tutorial"(editor)
	interface.keyconfig = require "ui/keyconfig"(editor)
	interface.donate = require "ui/donate"(editor)

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
	interface.property:create()

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
	property={interface.property.frame:GetPos()}
	}	
end

function interface:resetLayout()
	interface.system.list:SetPos(0, 0)
	interface.system.list:SetSize(editor.W, 30)

	interface.info.panel:SetPos(0, editor.H-30)
	interface.info.panel:SetSize(editor.W, 30)


	for name,layout in pairs(self.layout) do
		interface[name].frame:SetPos(layout[1],layout[2])
	end
end

function interface:resetVisible()
	editor:resize()
	editor.interface.info.panel:SetVisible(interface.visible.info)
	editor.interface.build.frame:SetVisible(interface.visible.build)
	editor.interface.joint.frame:SetVisible(interface.visible.joint)
	editor.interface.history.frame:SetVisible(interface.visible.history)
	editor.interface.unit.frame:SetVisible(interface.visible.unit)
	editor.interface.scene.frame:SetVisible(interface.visible.scene)
	if editor.interface.property.frame then
		editor.interface.property.frame:SetVisible(interface.visible.property)
	end
	editor.interface.system.list:SetVisible(interface.visible.system)
	for k,v in pairs(interface.visible) do
		if k~="system" then
			interface.layoutMenu.options[k].toggle=v
		end
	end
end

function interface:setVisible(tag,toggle)
	interface.visible[tag]=toggle
	
	editor.interface:resetVisible()
end

function interface:resetView()
	for k,v in pairs(editor.helper.visible) do
		interface.viewMenu.options[k].toggle=v
	end
end

function interface:reset()
	self:resetVisible()
	self:resetView()
	self:resetLayout()
	self.system:updateProj()
	self.unit:create()
end


function interface:setView(tag,toggle)
	interface.viewMenu.options[tag].toggle=toggle
	editor.helper.visible[tag]=toggle

end

return function(parent) 
	editor=parent
	return interface
end