extends ToolBehavior
## Rocket Pack: straps a rocket to your fwend. It rockets around the room out of
## control for a few seconds, then explodes in fireworks. Click the Buddy.


func press(at: Vector2) -> void:
	var part := part_near(at, 80.0)
	if part == null:
		return
	var victim := owner_of(part)
	var pack := RocketPack.new()
	sandbox.world.add_child(pack)
	pack.setup(sandbox, victim, power())
	Sfx.play(&"fuse", -4.0)
