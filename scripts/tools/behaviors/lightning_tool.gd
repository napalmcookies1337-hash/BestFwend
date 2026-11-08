extends ToolBehavior
## Lightning: a bolt from the ceiling. Strikes the Buddy if it's near the click
## (it attracts lightning, poor thing), otherwise scorches the floor below.
## params: "damage", "reach", "shock_seconds".


func press(at: Vector2) -> void:
	var part := part_near(at, float(param("reach", 140.0)))
	var target := at
	if part != null:
		target = part.global_position
	else:
		var down := sandbox.gravity.normalized() if sandbox.gravity.length() > 1.0 else Vector2.DOWN
		var query := PhysicsRayQueryParameters2D.create(at, at + down * 2000.0, Layers.GROUND)
		var hit := sandbox.get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			target = hit["position"]
		sandbox.room.decals.scorch(target, 26.0)
	var sky := Vector2(target.x + randf_range(-80.0, 80.0), 0.0)
	sandbox.fx.add(0.35, Fx.bolt(sky, target, randi()))
	sandbox.fx.add(0.15, Fx.screen_flash(Color(0.85, 0.9, 1.0, 0.55)))
	sandbox.fx.add(0.4, Fx.sparks(target, 14, 160.0, Color("bfe3ff"), randi()))
	sandbox.add_shake(12.0)
	Sfx.play(&"zap", 0.0)
	if part == null:
		return
	owner_of(part).shock(float(param("shock_seconds", 1.0)))
	owner_of(part).take_hit({"part": part.part_name, "force": 1200.0, "damage": float(param("damage", 30.0)) * power(),
			"source": &"lightning", "bleed": false, "mark": BuddyPart.Mark.SOOT, "position": target})
