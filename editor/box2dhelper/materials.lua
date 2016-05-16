local materialMode={}
local mat={}
materialMode.materialType=mat

mat.wood={ --实心木料
	name="wood",
	density=0.8,  --密度 水密度为1
	friction=0.7, --0~1 粗糙程度，0为无摩擦，1为完全受阻
	restitution=0.3, --0~1 弹性 0为不回弹，1为完全回弹
	hardness=5, --硬度大的碰到硬度小的 小的碎裂并且产生碎片
}

mat.wood_shell={ --木质外壳
	name="wood_shell",
	density=0.3,
	friction=0.4, 
	restitution=0.1,
	hardness=1,
}

mat.plastic={ --实心塑料
	name="plastic",
	density=0.9,  
	friction=0.3, 
	restitution=0.2, 
	hardness=6, 
}


mat.plastic_shell={ --塑料外壳
	name="plastic_shell",
	density=0.3,  
	friction=0.3, 
	restitution=0.1, 
	hardness=2, 
}

mat.ruber={ --实心橡胶
	name="ruber",
	density=2,  
	friction=0.9, 
	restitution=0.1, 
	hardness=4, 
}

mat.ruber={ --空心橡胶
	name="plastic",
	density=0.3,  
	friction=0.9, 
	restitution=0.7, 
	hardness=10,  --软性材料
}

mat.steel={ --实心钢
	name="steel",
	density=8,  
	friction=0.1, 
	restitution=0.1, 
	hardness=9, 
}

mat.steel_shell={ --空心钢
	name="steel_shell",
	density=0.8,  
	friction=0.1, 
	restitution=0.1, 
	hardness=5, 
}

mat.aluminum_shell={ --空心铝
	name="aluminum_shell",
	density=0.6,  
	friction=0.1, 
	restitution=0.1, 
	hardness=4, 
}

mat.aluminum={ --实心铝
	name="aluminum",
	density=6,  
	friction=0.1, 
	restitution=0.1, 
	hardness=7, 
}


mat.lead_shell={ --空心铅
	name="lead_shell",
	density=1,  
	friction=0.3, 
	restitution=0.1, 
	hardness=2, 
}

mat.lead={ --实心铅
	name="lead",
	density=10,  
	friction=0.3, 
	restitution=0.1, 
	hardness=5, 
}

mat.water={ --实心铅
	name="water",
	density=1,  
	friction=0.1, 
	restitution=0, 
	hardness=10, 
}

mat.magnet={ --钢磁体
	name="magnet",
	density=8,  
	friction=0.1, 
	restitution=0.1, 
	hardness=9, 
}

function materialMode.setMaterial(fixture,material)
	helper.setProperty(fixture,"material",material)

	local mat=materialMode.materialType[material]
	fixture:setDensity(mat.density)
	fixture:setFriction(mat.friction)
	fixture:setRestitution(mat.restitution)
	helper.setProperty(fixture,"hardness",mat.hardness)


end

return function(parent) helper=parent;helper.materialMode=materialMode end