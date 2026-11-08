extends ToolBehavior
## Ball, Brick, Grenade: the object appears in your hand. Drag and let go to throw,
## or just click to drop it. params: "kind".


func press(at: Vector2) -> void:
	var object := sandbox.spawn_object(StringName(param("kind", "ball")), at, Vector2.ZERO, power())
	sandbox.grabber.hold(object, object.global_position, MOUSE_BUTTON_LEFT)
	Sfx.play(&"pop", -8.0, 0.8)
