extends ToolBehavior
## Land Shark: a shark fin cuts through the floor toward your fwend, then the
## shark bursts out, chomps a limb clean off and dives back in. Click anywhere
## on the floor to release it.


func press(at: Vector2) -> void:
	var shark := LandShark.new()
	shark.setup(sandbox, at.x, power())
	sandbox.world.add_child(shark)
	Sfx.play(&"swish", -4.0, 0.5)
