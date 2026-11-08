extends ToolBehavior
## Rocket Launcher: a rocket flies in from the far side of the room toward where
## you click and explodes on contact. params: "speed".


func press(at: Vector2) -> void:
	var area := sandbox.room.interior().grow(-60.0)
	var target := at.clamp(area.position, area.end)
	var start := Vector2(area.position.x if target.x > Room.SIZE.x / 2 else area.end.x, clampf(target.y - 120.0, area.position.y, area.end.y))
	var direction := (target - start).normalized()
	var rocket := sandbox.spawn_object(&"rocket", start, direction * float(param("speed", 1500.0)), power())
	rocket.rotation = direction.angle()
	Sfx.play(&"whoosh", -2.0)
	sandbox.fx.add(0.25, Fx.flash(start, 50.0, Color(1.0, 0.7, 0.3, 0.8)))
