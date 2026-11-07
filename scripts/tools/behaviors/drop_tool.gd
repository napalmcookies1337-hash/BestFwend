extends ToolBehavior
## Anvil, Mini-Nuke: falls out of the sky (against gravity) above where you click.
## params: "kind", "speed" (starting fall speed), "whistle".

const DROP_MARGIN := 80.0


func press(at: Vector2) -> void:
	var gravity := sandbox.gravity
	var down := gravity.normalized() if gravity.length() > 1.0 else Vector2.DOWN
	var area := sandbox.room.interior().grow(-DROP_MARGIN)
	# Start at the far wall against gravity, in line with the click.
	var start := at
	if absf(down.y) >= absf(down.x):
		start.y = area.position.y if down.y > 0.0 else area.end.y
	else:
		start.x = area.position.x if down.x > 0.0 else area.end.x
	var object := sandbox.spawn_object(StringName(param("kind", "anvil")), start, down * float(param("speed", 300.0)))
	object.rotation = down.angle()
	sandbox.fx.add(0.8, _target(at.clamp(area.position, area.end), down))
	if param("whistle", false):
		Sfx.play(&"whistle", -2.0)
	else:
		Sfx.play(&"swish", -6.0, 0.6)


static func _target(at: Vector2, down: Vector2) -> Callable:
	return func(canvas: CanvasItem, t: float) -> void:
		var color := Color(1.0, 0.3, 0.3, 0.7 * (1.0 - t))
		canvas.draw_arc(at, 40.0 - t * 16.0, 0.0, TAU, 32, color, 5.0, true)
		canvas.draw_line(at - down.orthogonal() * 52.0, at + down.orthogonal() * 52.0, color, 3.0)
