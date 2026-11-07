extends ToolBehavior
## Poke: a gentle jab with a finger. Nudges the part and annoys the Buddy.


func press(at: Vector2) -> void:
	var part := part_at(at)
	sandbox.fx.add(0.18, _jab(at))
	if part == null:
		return
	var push := (part.global_position - at).normalized()
	if push == Vector2.ZERO:
		push = Vector2.RIGHT
	part.linear_velocity += push * float(param("push", 380.0)) * def.strength
	part.kick_squash(push, 900.0)
	buddy().notice(&"poke", part.part_name)
	Sfx.play(&"pop", -4.0, 1.3)


static func _jab(at: Vector2) -> Callable:
	return func(canvas: CanvasItem, t: float) -> void:
		var reach := sin(t * PI) * 18.0
		ToolArt.draw_icon(canvas, "poke", at + Vector2(22 - reach, 26 - reach), 44.0, Color.WHITE)
