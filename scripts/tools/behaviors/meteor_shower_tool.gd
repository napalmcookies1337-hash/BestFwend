extends ToolBehavior
## Meteor Shower: the sky goes red and flaming rocks rain down around where you
## click for a few seconds. params: "count", "spread"; uses the tool's duration.


func press(at: Vector2) -> void:
	var count := int(param("count", 14))
	var spread := float(param("spread", 900.0))
	var seconds := def.duration if def.duration > 0.0 else 4.0
	sandbox.fx.add(seconds + 0.5, _red_sky(seconds))
	Sfx.play(&"whistle", -2.0, 0.6)
	for index in count:
		var wait := 0.3 + randf() * seconds
		var x := clampf(at.x + randf_range(-spread / 2.0, spread / 2.0), 80.0, Room.SIZE.x - 80.0)
		sandbox.get_tree().create_timer(wait, false).timeout.connect(func() -> void: _drop(x))


func _drop(x: float) -> void:
	var slant := randf_range(-0.35, 0.35)
	var velocity := Vector2(sin(slant), cos(slant)) * randf_range(1500.0, 2100.0)
	var start := Vector2(x - velocity.x * 0.3, 60.0)
	var rock := sandbox.spawn_object(&"meteor", start, velocity, power())
	rock.rotation = velocity.angle() - PI / 2
	if randf() < 0.4:
		Sfx.play(&"whoosh", -8.0, 0.7)


static func _red_sky(seconds: float) -> Callable:
	return func(canvas: CanvasItem, t: float) -> void:
		var total := seconds + 0.5
		var age := t * total
		var alpha := 0.22 * minf(age / 0.4, 1.0) * clampf((total - age) / 0.5, 0.0, 1.0)
		canvas.draw_rect(Rect2(-Vector2.ONE * 200.0, Room.SIZE + Vector2.ONE * 400.0), Color(0.9, 0.25, 0.1, alpha))
