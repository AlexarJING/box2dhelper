local helper={}
local path=...
require(path.."/system")(helper)
require(path.."/draw")(helper)
require(path.."/data")(helper)
require(path.."/collision")(helper)
require(path.."/reaction")(helper)
helper.world=nil
helper.visible=helper.drawMode.visible
helper.properties=helper.dataMode.properties

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
return helper