local fMode={} --to edit fixture type and collision
local editor

function fMode:new()

end



function fMode:click(key)
	if key=="l" then
		local selectFixtures={}
		for i,body in ipairs(editor.world:getBodyList()) do
			for i,fix in ipairs(body:getFixtureList()) do
				if fix:testPoint( editor.mouseX, editor.mouseY ) then
					table.insert(selectFixtures, fix)
				end
			end
		end
		self.selection=#selectFixtures==0 and nil or selectFixtures
		self.selectedIndex=1
		self.selectedFixture=self.selection and self.selection[self.selectedIndex] or nil
		editor.selector.selection= self.selectedFixture and {self.selectedFixture} or nil
	else
		if self.selection then
			self.selectedIndex=self.selectedIndex+1
			if not self.selection[self.selectedIndex] then self.selectedIndex=1 end
			self.selectedFixture=self.selection[self.selectedIndex]
			editor.selector.selection={self.selectedFixture}
			editor.selector.selection= self.selectedFixture and {self.selectedFixture} or nil
		end
	end
end

local fixColor={255, 0, 255, 255}

function fMode:draw()
	if not self.selectedFixture then return end
	editor.helper.drawFixture(self.selectedFixture,fixColor)
end

return function(parent) 
	editor=parent
	return fMode 
end