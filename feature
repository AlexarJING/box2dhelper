features list

1. body creation (with basic fixture)
	circle
	rectangle
	polygon
	edge
	line
	freeline
2. soft body creation
	circle
	rectangle
	polygon
	rope
3. functional body
	water particle(circle)
	explosive circle
3. joint creation
	weld
	rope
	distance
	prismatic
	revolute
	pully
	wheel
	gear
4. body and fixture edition
	redo and undo
	single and multi selection
	delect body delect joint
	move
	copy and paste
	rotate
	scale(circle)
	vertex transform (polygon)
	combine bodies to one
	divide one body to 1 body 1 fixture
	toggle body type
5. unit management
	save unit
	load unit
	preview unit
6. property and userdata
	view and edit property of body/shape/fixture/joint
	view and edit userdata of body/fixture 
		with a form userdata={[1]={prop="example",value=123}} 
		value in type of userdata will not saved but can by used in current run.
	set matirial of fixture.
7. fixture binding contact callback
	all the contact callbacks are binded to fixture userdata.
	and by now we have buildin contact functions.

	makeFrag  			making frags/sparks on collide or rub
	reverse 			reverse all binding motor force when hit
	explosion 			will explode on hit.
	destoryOnHit 		will destroy on hit
	oneWay 				a one way wall let passing only from one side
	buoyancy 			bodies in the field will be affected by buoyancy and resistance.
	magnetField     	bodies in the field will be affected by magnet force(N/S and "steel")
	crashable			will crash on hit that harder then the threshold
	embed				will embed into another body on hit that harder then the threshold
8. body binding reactions.
	all the reaction (userinput key or mouse) binded to body userdata
	and by now we have buildin reaction functions

	fire 		will fire a body alone the body angle
	jet  		will take force alone the body and throw some particles behind.
	roll		will take angular torque to body
	jump		will jump up when landing. also key binding to jump left or right.
	anticount	will destroy when the anticount end up.
	turnToMouse will always facing to the mouse like sunflower...
	balancer	will take torque when the body angle is offside from 0. works with jump.


1. UI rebuild

2. Project management

3. scene mangement

