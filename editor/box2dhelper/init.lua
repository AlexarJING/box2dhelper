
------------------------------------
local helper={}
local path=...
require(path.."/patch")
require(path.."/system")(helper)
require(path.."/draw")(helper)
require(path.."/data")(helper)
require(path.."/collision")(helper)
require(path.."/reaction")(helper)
require(path.."/materials")(helper)
require(path.."/script")(helper)

helper.world=nil
helper.visible=helper.drawMode.visible
helper.properties=helper.dataMode.properties

helper.update=helper.system.update
helper.draw=helper.drawMode.draw
helper.drawBody=helper.drawMode.drawBody
helper.drawTexture=helper.drawMode.drawTexture
helper.drawFixture=helper.drawMode.drawFixture
helper.drawContact=helper.drawMode.drawContact
helper.drawJoint=helper.drawMode.drawJoint

helper.getWorldData=helper.dataMode.getWorldData
helper.createWorld=helper.dataMode.createWorld

helper.getStatus=helper.dataMode.getStatus
helper.setStatus=helper.dataMode.setStatus

helper.setProperty=helper.dataMode.setProperty
helper.getProperty=helper.dataMode.getProperty
helper.removeProperty=helper.dataMode.removeProperty


helper.press=helper.reactMode.press
helper.click=helper.reactMode.click

helper.setMaterial=helper.materialMode.setMaterial

return helper