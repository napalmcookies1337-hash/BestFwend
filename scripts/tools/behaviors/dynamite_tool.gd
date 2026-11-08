extends ToolBehavior
## Sticky Dynamite: sticks to the Buddy part (or wall) you click. When it goes off,
## the part it was stuck to goes with it.


func press(at: Vector2) -> void:
	var part := part_at(at)
	if part == null and not sandbox.room.interior().has_point(at):
		return
	sandbox.stick_dynamite(at, part, power())
	Sfx.play(&"fuse", -6.0)
