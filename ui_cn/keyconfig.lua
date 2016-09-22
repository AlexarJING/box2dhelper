local editor
local ui
local interface
local keyconf={}

local keyOrder = {
	cancel=21,
	createCircle=1,
	createBox=2,
	createLine=3,
	createEdge=4,
	createPolygon=5,
	createFreeline=6,
	createText=7,
	createSoftRope=8,
	createSoftCircle=9,
	createSoftPolygon=10,
	createSoftBox=11,
	createWater=12,
	createBoom=13,
	createDistance=14,
	createRope=15,
	createWeld=16,
	createRevolute=17,
	createPrismatic=18,
	createWheel=19,
	createPully=20,
	selectAll=22,
	selectNone=23,
	alineHorizontal=24,
	alineVerticle=25,
	clear=26,
	removeBody=27,
	removeJoint=28,
	copy=29,
	paste=30,
	combine=31,
	divide=32,
	undo=33,
	redo=34,
	toggleBodyType=35,
	nextPropTab=36,
	bodyMode=37,
	fixtureMode=38,
	shapeMode=39,
	jointMode=40,
	test=41,
	pause=42,
	toggleMouse=43,
	reset=44,
	toggleSystem=45,
	toggleGrid=46,
	toggleBuild=47,
	toggleProperty=48,
	toggleUnit=49,
	toggleHistroy=50,	
	saveScene=51,
	saveUnit=52,
	saveProject=53,
	loadProject=54,
	openSaveFolder=55,
	comboSet = 56,
	teststd = 57,
	testpower = 58,
	testball = 59,
	testkey = 60,
	testscissor = 61,
	testgrab = 62,
	getConvex = 63,
	getConcave = 64,
	exportJson = 65
}



function keyconf:create()
	if self.frame then self.frame:Remove() end
	local frame =ui.Create("frame")
	self.frame=frame
	frame:SetName("按键设定")
	frame:SetSize(740,700)
	frame:CenterWithinArea(0,0,w(),h())


	self.lists = {}
	self.keyconf = editor.keyconf or require "editor/keyconf"
	self.keys = {}
	for action,key in pairs(self.keyconf) do
		--table.insert(self.keys, )
		self.keys[keyOrder[action]] = {action=action,key=key}
	end

	local index = 0
	for i = 1, 3 do
		local list = ui.Create("grid",self.frame)
		list:SetPos(10+(i-1)*250, 30)
		list:SetCellWidth(100)
		list:SetCellHeight(20)
		list:SetRows(22)
		list:SetColumns(2)
		list:SetItemAutoSize(true)
		table.insert(self.lists, list)
		for i = 1, 22 do
			index= index+1
			if not self.keys[index] then break end
			local key = ui.Create("textinput")
			key:SetText(self.keys[index].key)
			key:SetEditable(false)

			local action = ui.Create("button")
			action.posIndex = index
			action:SetText(self.keys[index].action)
			action.OnClick = function(obj)
				key:SetEditable(true)
				local _keyreleased = love.keyreleased
				love.keyreleased = function(keyinput)
					local pre = ""
					if love.keyboard.isDown("lctrl") then 
						pre = "ctrl+"
					elseif love.keyboard.isDown("lalt") then
						pre = "alt+"
					end
					keyinput = pre..keyinput
					local check = false
					for i,v in ipairs(self.keys) do
						if v.key==keyinput then
							check = true
							break
						end
					end
					if not check and keyinput~="escape" then
						editor.keyconf[action:GetText()] = keyinput
						editor:keyBound()
						self:create()
					end
					love.keyreleased=_keyreleased
					key:SetEditable(false)
				end
			end
			list:AddItem(action,i,1)
			list:AddItem(key,i,2)	
		end
	end

end



return function(parent) 
	editor=parent
	interface=editor.interface
	ui=editor.LoveFrames
	return keyconf
end