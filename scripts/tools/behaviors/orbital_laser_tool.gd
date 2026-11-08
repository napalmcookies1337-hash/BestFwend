extends ToolBehavior
## Orbital Laser: hold to fire a beam from space straight down through the
## cursor. It cooks whatever it touches, sets it alight and scorches the floor.
## params: "dps", "width".

const TICK := 0.08

var _tick := 0.0
var _age := 0.0
var _beam_x := 0.0
var _query := PhysicsShapeQueryParameters2D.new()
var _scorch_tick := 0.0


func press(at: Vector2) -> void:
	_age = 0.0
	_beam_x = at.x
	var box := RectangleShape2D.new()
	box.size = Vector2(float(param("width", 70.0)), Room.FLOOR_Y)
	_query.shape = box
	_query.collision_mask = Layers.BUDDY | Layers.OBJECTS
	Sfx.play(&"laser", 0.0)
	sandbox.fx.add(0.25, Fx.screen_flash(Color(0.6, 1.0, 1.0, 0.5)))


func hold(at: Vector2, delta: float) -> void:
	_age += delta
	# The beam lags the cursor a little, like it's being steered from orbit.
	_beam_x = lerpf(_beam_x, at.x, minf(delta * 10.0, 1.0))
	sandbox.add_shake(5.0)
	_tick += delta
	_scorch_tick += delta
	if _scorch_tick >= 0.12:
		_scorch_tick = 0.0
		sandbox.room.decals.scorch(Vector2(_beam_x + randf_range(-20, 20), Room.FLOOR_Y - 4), 30.0)
	if _tick < TICK:
		return
	_tick = 0.0
	if randf() < 0.4:
		Sfx.play(&"laser", -10.0, randf_range(0.9, 1.1))
	_query.transform = Transform2D(0.0, Vector2(_beam_x, Room.FLOOR_Y / 2))
	var hurt: Dictionary = {}
	for hit in sandbox.get_world_2d().direct_space_state.intersect_shape(_query, 32):
		var body := hit["collider"] as RigidBody2D
		if body == null:
			continue
		body.linear_velocity += Vector2(signf(body.global_position.x - _beam_x) * 200.0, -120.0)
		if body is BuddyPart and not (body as BuddyPart).detached:
			var victim := body.get_parent() as Buddy
			if not hurt.has(victim):
				hurt[victim] = body
	for victim: Buddy in hurt:
		var part: BuddyPart = hurt[victim]
		victim.ignite(3.0)
		victim.take_hit({"part": part.part_name, "force": 600.0, "damage": float(param("dps", 60.0)) * TICK * power(),
				"source": &"orbital_laser", "bleed": false, "mark": BuddyPart.Mark.SOOT, "position": part.global_position})
		victim.show_face(&"scream", 0.4)


func release(_at: Vector2) -> void:
	_age = 0.0


func draw_cursor(canvas: CanvasItem, at: Vector2) -> void:
	if sandbox.tools.active != self:
		super.draw_cursor(canvas, at)
		return
	var width := float(param("width", 70.0)) * (1.0 + 0.15 * sin(_age * 50.0))
	var top := Vector2(_beam_x, -40.0)
	var bottom := Vector2(_beam_x, Room.FLOOR_Y)
	canvas.draw_line(top, bottom, Color(0.3, 0.9, 1.0, 0.25), width * 2.2)
	canvas.draw_line(top, bottom, Color(0.45, 0.95, 1.0, 0.7), width)
	canvas.draw_line(top, bottom, Color(1, 1, 1, 0.95), width * 0.35)
	canvas.draw_circle(bottom, width * 1.1, Color(1.0, 0.9, 0.6, 0.6))
	canvas.draw_circle(bottom, width * 0.55, Color(1, 1, 1, 0.9))
