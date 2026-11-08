extends ToolBehavior
## Airstrike: a siren, then a line of missiles screams down across the room,
## centred on where you click. params: "count", "spread", "delay".


func press(at: Vector2) -> void:
	var count := int(param("count", 7))
	var spread := float(param("spread", 1100.0))
	var delay := float(param("delay", 0.14))
	Sfx.play(&"siren", -2.0)
	sandbox.fx.add(0.8, _marker(at, spread))
	for index in count:
		var x := clampf(at.x - spread / 2.0 + spread * index / maxf(count - 1, 1), 80.0, Room.SIZE.x - 80.0)
		var wait := 0.6 + delay * index
		sandbox.get_tree().create_timer(wait, false).timeout.connect(func() -> void: _drop(x))


func _drop(x: float) -> void:
	var missile := sandbox.spawn_object(&"missile", Vector2(x + randf_range(-30, 30), 70.0), Vector2(randf_range(-80, 80), 2300.0), power())
	missile.rotation = PI / 2
	Sfx.play(&"whoosh", -6.0, 1.3)


static func _marker(at: Vector2, spread: float) -> Callable:
	return func(canvas: CanvasItem, t: float) -> void:
		var red := Color(1, 0.2, 0.2, 0.7 * (1.0 - t))
		var floor_y := Room.FLOOR_Y - 8.0
		canvas.draw_line(Vector2(at.x - spread / 2.0, floor_y), Vector2(at.x + spread / 2.0, floor_y), red, 8.0)
		for tick in 8:
			var x := at.x - spread / 2.0 + spread * tick / 7.0
			canvas.draw_line(Vector2(x, floor_y - 30), Vector2(x, floor_y), red, 4.0)
