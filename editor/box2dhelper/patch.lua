local ref = {}
local _newWorld = love.physics.newWorld
function love.physics.newWorld(...)
	ref = {}
	return _newWorld(...)
end
local function add(j)
	table.insert(ref, j)
	return j
end

local _gearjoint =  love.physics.newGearJoint
love.physics.newGearJoint=function(...)
	return add(_gearjoint(...))
end
local _ropejoint = love.physics.newRopeJoint
love.physics.newRopeJointt=function(...)
	return add( _ropejoint(...))
end
local _weldjoint = love.physics.newWeldJoint
love.physics.newWeldJoint=function(...)
	return add(_weldjoint(...))
end
local _mousejoint = love.physics.newMouseJoint
love.physics.newMouseJoint=function(...)
	return add(_mousejoint(...))
end
local _wheeljoint = love.physics.newWheelJoint
love.physics.newWheelJoint=function(...)
	return add(_wheeljoint (...))
end
local _pulleyjoint = love.physics.newPulleyJoint
love.physics.newPulleyJoint=function(...)
	return add(_pulleyjoint(...))
end
local _distancejoint = love.physics.newDistanceJoint
love.physics.newDistanceJoint=function(...)
	return add(_distancejoint(...))
end
local _frictionjoint = love.physics.newFrictionJoint
love.physics.newFrictionJoint=function(...)
	return add(_frictionjoint(...))
end
local _revolutejoint = love.physics.newRevoluteJoint
love.physics.newRevoluteJoint=function(...)
	return add(_revolutejoint(...))
end
local _prismaticjoint = love.physics.newPrismaticJoint
love.physics.newPrismaticJoint=function(...)
	return add(_prismaticjoint(...))
end


