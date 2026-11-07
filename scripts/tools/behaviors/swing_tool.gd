extends ToolBehavior
## Baseball Bat, Katana: hold the button and swipe through the Buddy. The faster
## the swipe, the harder the hit. A fast enough katana cut takes a limb off.
## params: "min_speed", "force_scale", "max_force", "reach", "sever_speed" (katana).

const PART_COOLDOWN := 0.25
const SAMPLE_SPACING := 18.0

var velocity := Vector2.ZERO
var _last := Vector2.ZERO
var _cooldowns: Dictionary = {}
var _query := PhysicsShapeQueryParameters2D.new()
var _angle := 0.0


func press(at: Vector2) -> void:
	_last = at
	velocity = Vector2.ZERO
	_cooldowns.clear()
	var circle := CircleShape2D.new()
	circle.radius = float(param("reach", 34.0))
	_query.shape = circle
	_query.collision_mask = Layers.BUDDY | Layers.OBJECTS


func hold(at: Vector2, delta: float) -> void:
	var moved := at - _last
	velocity = velocity.lerp(moved / maxf(delta, 0.0001), 0.5)
	if velocity.length() > 60.0:
		_angle = lerp_angle(_angle, velocity.angle() - PI / 2, 0.35)
	for key: Variant in _cooldowns.keys():
		_cooldowns[key] = _cooldowns[key] - delta
		if _cooldowns[key] <= 0.0:
			_cooldowns.erase(key)
	var speed := velocity.length()
	if speed >= float(param("min_speed", 650.0)):
		_sweep(_last, at, speed)
	_last = at


func _sweep(from: Vector2, to: Vector2, speed: float) -> void:
	var steps := maxi(int(from.distance_to(to) / SAMPLE_SPACING), 1)
	var space := sandbox.get_world_2d().direct_space_state
	for step in steps + 1:
		_query.transform = Transform2D(0.0, from.lerp(to, float(step) / steps))
		for hit in space.intersect_shape(_query, 8):
			var body := hit["collider"] as RigidBody2D
			if body == null or _cooldowns.has(body):
				continue
			_cooldowns[body] = PART_COOLDOWN
			_strike(body, to, speed)


func _strike(body: RigidBody2D, at: Vector2, speed: float) -> void:
	var direction := velocity.normalized()
	var force := minf(speed * float(param("force_scale", 1.0)), float(param("max_force", 4200.0))) * def.strength
	body.linear_velocity += direction * force * 0.75
	if not (body is BuddyPart) or (body as BuddyPart).detached:
		Sfx.play(&"thud", -6.0)
		return
	var part := body as BuddyPart
	var sever_speed := float(param("sever_speed", 0.0))
	var source := StringName(def.id)
	if sever_speed > 0.0 and speed >= sever_speed and Buddy.LIMBS.has(part.part_name):
		buddy().sever(part.part_name, direction * force * 0.6, source)
		Sfx.play(&"slice", 0.0)
		sandbox.add_shake(10.0)
		return
	buddy().take_hit({"part": part.part_name, "force": force, "source": source,
			"normal": -direction, "position": part.global_position.lerp(at, 0.5),
			"bleed": sever_speed > 0.0 or force > 2600.0})
	Sfx.play(&"slice" if sever_speed > 0.0 else &"smack", -2.0, 1.1 if sever_speed > 0.0 else 0.85)
	sandbox.add_shake(clampf(force / 300.0, 3.0, 14.0))


func draw_cursor(canvas: CanvasItem, at: Vector2) -> void:
	var swinging := sandbox.tools.active == self
	var angle := _angle if swinging else -0.6
	canvas.draw_set_transform(at, angle, Vector2.ONE)
	if swinging and velocity.length() > float(param("min_speed", 650.0)):
		canvas.draw_line(Vector2(0, -20), Vector2(0, -150), Color(1, 1, 1, 0.25), 40.0, true)
	ToolArt.draw_weapon(canvas, def.id)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
