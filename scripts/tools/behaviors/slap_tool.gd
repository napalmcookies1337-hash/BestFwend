extends ToolBehavior
## Slap: a hard open-handed smack from the side you clicked on. Stings, rarely bleeds.


func press(at: Vector2) -> void:
	var part := part_at(at)
	sandbox.fx.add(0.25, _print(at))
	Sfx.play(&"smack", 0.0, 1.15)
	if part == null:
		return
	var side := signf(part.global_position.x - at.x)
	if side == 0.0:
		side = 1.0
	var direction := Vector2(side, -0.35).normalized()
	var force := float(param("force", 1750.0)) * power()
	part.linear_velocity += direction * force * 0.8
	buddy().take_hit({"part": part.part_name, "force": force, "source": &"slap", "bleed": false,
			"normal": -direction, "position": at})
	buddy().notice(&"slap", part.part_name)
	sandbox.add_shake(6.0)


static func _print(at: Vector2) -> Callable:
	return func(canvas: CanvasItem, t: float) -> void:
		var color := Color(1.0, 0.35, 0.35, 0.8 * (1.0 - t))
		canvas.draw_circle(at, 26.0 + t * 20.0, color)
		for finger in 4:
			var tip := at + Vector2(-24 + finger * 16, -40 - t * 10)
			canvas.draw_line(at + Vector2(-18 + finger * 12, -14), tip, color, 12.0, true)
