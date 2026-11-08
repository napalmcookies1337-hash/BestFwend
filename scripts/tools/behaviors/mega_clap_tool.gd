extends ToolBehavior
## Mega Clap: two giant gloves slam together where you click and crush whatever
## is caught between them. params: "force", "damage", "reach".

const CLAP_TIME := 0.18


func press(at: Vector2) -> void:
	var reach := Vector2(float(param("reach", 170.0)), 150.0) * sqrt(power())
	sandbox.fx.add(CLAP_TIME + 0.25, _hands(at, reach.x))
	sandbox.get_tree().create_timer(CLAP_TIME, false).timeout.connect(func() -> void: _crush(at, reach))


func _crush(at: Vector2, reach: Vector2) -> void:
	Sfx.play(&"smack", 2.0, 0.7)
	Sfx.play(&"crunch", 0.0, 0.8)
	sandbox.add_shake(24.0)
	sandbox.fx.add(0.35, Fx.ring(at, 220.0, Color(1, 0.9, 0.5, 0.9), 16.0))
	sandbox.fx.add(0.4, Fx.sparks(at, 20, 260.0, Color("ffcf3a"), randi()))
	var area := Rect2(at - reach, reach * 2.0)
	for someone in sandbox.buddies():
		var struck: BuddyPart = null
		for part in someone.part_list:
			if area.has_point(part.global_position):
				part.kick_squash(Vector2.RIGHT, 6000.0)
				part.linear_velocity = Vector2(0, randf_range(-900.0, -300.0))
				if struck == null or part == someone.head:
					struck = part
		if struck != null:
			someone.take_hit({"part": struck.part_name, "force": float(param("force", 4200.0)) * power(),
					"damage": float(param("damage", 48.0)) * power(), "source": &"mega_clap", "position": struck.global_position})
	for object in sandbox.objects:
		if object is RigidBody2D and is_instance_valid(object) and area.has_point(object.global_position):
			(object as RigidBody2D).linear_velocity = Vector2(0, -900)


static func _hands(at: Vector2, reach: float) -> Callable:
	return func(canvas: CanvasItem, t: float) -> void:
		var close := minf(t / 0.42, 1.0)
		var gap := lerpf(reach + 260.0, 60.0, close * close)
		if t > 0.85:
			return
		ToolArt.glove_open(canvas, Transform2D(PI / 2, Vector2.ONE * 2.2, 0.0, at + Vector2(-gap, 0)), 5.0)
		ToolArt.glove_open(canvas, Transform2D(-PI / 2, Vector2.ONE * 2.2, 0.0, at + Vector2(gap, 0)), 5.0)
