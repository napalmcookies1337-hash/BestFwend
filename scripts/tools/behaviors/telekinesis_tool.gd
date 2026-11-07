extends ToolBehavior
## Telekinesis: hold to lift everything near the cursor (the whole Buddy, objects,
## loose limbs) and carry it around. Let go to fling it. params: "radius".

const FREQUENCY := 3.0
const DAMPING := 0.8
const GATHER := 0.6

var captured: Array[RigidBody2D] = []
var _offsets: Dictionary = {}
var _lifted_buddy: Buddy
var _last := Vector2.ZERO
var _velocity := Vector2.ZERO
var _phase := 0.0


func press(at: Vector2) -> void:
	captured.clear()
	_offsets.clear()
	_lifted_buddy = null
	_last = at
	_velocity = Vector2.ZERO
	var radius := float(param("radius", 240.0))
	var circle := CircleShape2D.new()
	circle.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, at)
	query.collision_mask = Layers.BUDDY | Layers.OBJECTS
	for hit in sandbox.get_world_2d().direct_space_state.intersect_shape(query, 48):
		var body := hit["collider"] as RigidBody2D
		if body == null or body == sandbox.grabber.held:
			continue
		if body is BuddyPart and not (body as BuddyPart).detached:
			_lifted_buddy = body.get_parent() as Buddy
			continue
		_capture(body, at)
	if _lifted_buddy != null:
		for part in _lifted_buddy.part_list:
			_capture(part, at)
		_lifted_buddy.levitate(true)
	if not captured.is_empty():
		Sfx.play(&"hum", -8.0, 1.6)


func _capture(body: RigidBody2D, at: Vector2) -> void:
	if captured.has(body):
		return
	captured.append(body)
	_offsets[body] = (body.global_position - at) * GATHER


func hold(at: Vector2, delta: float) -> void:
	_phase += delta
	_velocity = _velocity.lerp((at - _last) / maxf(delta, 0.0001), 0.4)
	_last = at
	var gravity := sandbox.gravity
	var omega := TAU * FREQUENCY
	for body in captured:
		if not is_instance_valid(body):
			continue
		var target: Vector2 = at + _offsets[body]
		var accel := (target - body.global_position) * omega * omega - (body.linear_velocity - _velocity) * 2.0 * DAMPING * omega
		accel = accel.limit_length(16000.0) - gravity
		body.apply_central_force(accel * body.mass)


func release(_at: Vector2) -> void:
	for body in captured:
		if is_instance_valid(body):
			body.linear_velocity = body.linear_velocity.limit_length(Grabber.MAX_THROW_SPEED)
	if is_instance_valid(_lifted_buddy):
		_lifted_buddy.levitate(false, _lifted_buddy.torso.linear_velocity)
	captured.clear()
	_lifted_buddy = null


func draw_cursor(canvas: CanvasItem, at: Vector2) -> void:
	var glow := Color(0.75, 0.45, 1.0, 0.55)
	var radius := float(param("radius", 240.0))
	if sandbox.tools.active == self:
		canvas.draw_arc(at, 30.0 + sin(_phase * 8.0) * 6.0, 0.0, TAU, 32, glow, 6.0, true)
		for body in captured:
			if is_instance_valid(body):
				canvas.draw_arc(body.global_position, 40.0, _phase * 4.0, _phase * 4.0 + PI * 1.4, 16, glow, 5.0, true)
	else:
		canvas.draw_arc(at, radius, 0.0, TAU, 64, Color(glow, 0.18), 3.0, true)
		ToolArt.draw_icon(canvas, def.id, at + Vector2(34, 34), 46.0, Color.WHITE)
