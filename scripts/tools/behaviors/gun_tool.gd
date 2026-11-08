extends ToolBehavior
## Pistol: shoots whatever is under the crosshair. Hold to keep firing at
## def.use_interval. Misses leave bullet holes. params: "damage", "force".

var _since_shot := 0.0
var _last := Vector2.ZERO
var _aim := Vector2.RIGHT


func press(at: Vector2) -> void:
	_last = at
	fire(at)


func hold(at: Vector2, delta: float) -> void:
	if at.distance_to(_last) > 2.0:
		_aim = (at - _last).normalized()
	_last = at
	_since_shot += delta
	if def.use_interval > 0.0 and _since_shot >= def.use_interval:
		fire(at)


func fire(at: Vector2) -> void:
	_since_shot = 0.0
	Sfx.play(&"bang", -2.0)
	sandbox.add_shake(4.0)
	sandbox.fx.add(0.08, Fx.flash(at, 30.0, Color(1.0, 0.9, 0.5, 0.9)))
	var body := sandbox.grabber.body_at(at)
	# The bullet comes from in front of the screen, so it pushes a little in the
	# direction you're sweeping the gun, plus a random wobble.
	var direction := (_aim + Vector2(randf_range(-0.4, 0.4), randf_range(-0.6, 0.2))).normalized()
	var force := float(param("force", 900.0)) * power()
	if body == null:
		if sandbox.room.interior().has_point(at):
			sandbox.room.decals.hole(at)
			sandbox.fx.add(0.3, Fx.sparks(at, 6, 80.0, Color("ffd27a"), randi()))
		return
	body.linear_velocity += direction * force
	if body is BuddyPart and not (body as BuddyPart).detached:
		var part := body as BuddyPart
		buddy().take_hit({"part": part.part_name, "force": force, "damage": float(param("damage", 12.0)) * power(),
				"source": &"pistol", "normal": -direction, "position": at})


func draw_cursor(canvas: CanvasItem, at: Vector2) -> void:
	var color := Color(1, 0.25, 0.25)
	canvas.draw_arc(at, 20.0, 0.0, TAU, 32, Color(0, 0, 0, 0.6), 6.0, true)
	canvas.draw_arc(at, 20.0, 0.0, TAU, 32, color, 3.0, true)
	for direction: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		canvas.draw_line(at + direction * 10.0, at + direction * 30.0, color, 3.0)
