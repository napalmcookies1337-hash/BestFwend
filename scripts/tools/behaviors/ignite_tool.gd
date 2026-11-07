extends ToolBehavior
## Ignite: sets the Buddy on fire. It runs around screaming while it burns.
## Uses def.duration.


func press(at: Vector2) -> void:
	sandbox.fx.add(0.4, Fx.flash(at, 46.0, Color(1.0, 0.55, 0.15, 0.85)))
	sandbox.fx.add(0.5, Fx.sparks(at, 10, 110.0, Color("ffb02e"), randi()))
	Sfx.play(&"fwoosh", -2.0)
	var part := part_near(at, 60.0)
	if part == null:
		sandbox.room.decals.scorch(at, 14.0)
		return
	buddy().ignite(def.duration)
