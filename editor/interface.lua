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
	log=true,
	info=true,
	scene=true,
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
	self.layout= {
	build={interface.build.frame:GetPos()},
	joint={interface.joint.frame:GetPos()},
	unit={interface.unit.frame:GetPos()},
	history={interface.history.frame:GetPos()},
	scene={interface.scene.frame:GetPos()},
	}	
	return self.layout
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

	editor.bg:init()
end

function interface:resetVisible()
 	editor.bg.visible=interface.visible.bg
	editor.log.visible=interface.visible.log
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
	editor.bg:init()
end

function interface:setVisible(tag,toggle)
	interface.visible[tag]=toggle
	if tag~="system" then
		interface.layoutMenu.options[tag].toggle=toggle
	end
	editor.interface:resetVisible()

end

function interface:resetView()
	for k,v in pairs(editor.helper.visible) do
		interface.viewMenu.options[tag].toggle=v
	end
	interface.viewMenu.options.bloom.toggle=editor.enableBloom
end


function interface:setView(tag,toggle)
	interface.viewMenu.options[tag].toggle=toggle
	editor.helper.visible[tag]=toggle
end

return function(parent) 
	editor=parent
	return interface
end