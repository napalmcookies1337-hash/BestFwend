extends ToolBehavior
## Freeze Ray: freezes the Buddy solid. It falls over like a statue, can't move,
## and hits on it hurt more until it thaws. Fire thaws it early. Uses def.duration.


func press(at: Vector2) -> void:
	sandbox.fx.add(0.4, Fx.ring(at, 120.0, Color(0.75, 0.92, 1.0, 0.9), 10.0))
	sandbox.fx.add(0.4, Fx.sparks(at, 12, 120.0, Color("dff4ff"), randi()))
	Sfx.play(&"freeze", -2.0)
	var part := part_near(at, 60.0)
	if part != null:
		buddy().freeze(def.duration * power())
