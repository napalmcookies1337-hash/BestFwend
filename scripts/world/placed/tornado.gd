class_name Tornado
extends Node2D
## A twister that drifts across the floor for a few seconds, sucking everything
## nearby up its funnel and whirling it round, then spits it all out.

const RADIUS := 300.0
const HEIGHT := 760.0
const LIFT := 4600.0
const SWIRL := 3400.0
const DRIFT := 260.0
const BUDDY_DPS := 10.0

var sandbox: Sandbox
var duration := 6.0
var power := 1.0
var age := 0.0
var _direction := 1.0
var _query := PhysicsShapeQueryParameters2D.new()
var _hurt_tick := 0.0


func setup(owner_sandbox: Sandbox, at: Vector2, seconds: float, power_scale: float) -> void:
	sandbox = owner_sandbox
	name = "Tornado"
	duration = seconds
	power = power_scale
	global_position = Vector2(at.x, Room.FLOOR_Y)
	_direction = -1.0 if at.x > Room.SIZE.x / 2 else 1.0
	z_index = 5
	add_to_group(&"debris")
	var box := RectangleShape2D.new()
	box.size = Vector2(RADIUS * 2.0, HEIGHT)
	_query.shape = box
	_query.collision_mask = Layers.BUDDY | Layers.OBJECTS


func _physics_process(delta: float) -> void:
	age += delta
	if age >= duration:
		_spit_out()
		return
	var strength := minf(age / 0.5, 1.0) * power
	global_position.x += _direction * DRIFT * delta
	if global_position.x < 200.0 or global_position.x > Room.SIZE.x - 200.0:
		_direction = signf(Room.SIZE.x / 2 - global_position.x)
	_query.transform = Transform2D(0.0, global_position + Vector2(0, -HEIGHT / 2))
	var hurt: Dictionary = {}
	for hit in get_world_2d().direct_space_state.intersect_shape(_query, 64):
		var body := hit["collider"] as RigidBody2D
		if body == null:
			continue
		var offset := body.global_position.x - global_position.x
		var height := clampf((global_position.y - body.global_position.y) / HEIGHT, 0.0, 1.0)
		# The funnel widens as it rises; pull toward the centre line, lift, and spin.
		var width := lerpf(RADIUS * 0.4, RADIUS, height)
		var inward := -offset / maxf(width, 1.0) * SWIRL * 0.8
		var spin := SWIRL * (1.0 - absf(offset) / RADIUS) * (1.0 if sin(age * 9.0 + height * 6.0) > 0.0 else -1.0)
		var lift := LIFT * (1.0 - height * 0.9)
		body.apply_central_force(Vector2(inward + spin, -lift) * strength * body.mass)
		body.angular_velocity = lerpf(body.angular_velocity, 14.0 * _direction, 0.05)
		if body is BuddyPart and not (body as BuddyPart).detached:
			var victim := body.get_parent() as Buddy
			if victim.state == Buddy.State.STANDING or victim.state == Buddy.State.GETTING_UP:
				victim.launch(victim.torso.linear_velocity + Vector2(0, -300))
			hurt[victim] = true
	_hurt_tick += delta
	if _hurt_tick >= 0.5:
		_hurt_tick = 0.0
		for victim: Buddy in hurt:
			victim.show_face(&"scream", 0.6)
			victim.take_hit({"part": &"torso", "force": 0.0, "damage": BUDDY_DPS * 0.5 * power,
					"source": &"tornado", "bleed": false, "quiet": true, "position": victim.torso.global_position})
	if randf() < delta * 2.0:
		Sfx.play(&"whoosh", -8.0, randf_range(0.5, 0.7))
	queue_redraw()


func _spit_out() -> void:
	set_physics_process(false)
	_query.transform = Transform2D(0.0, global_position + Vector2(0, -HEIGHT / 2))
	for hit in get_world_2d().direct_space_state.intersect_shape(_query, 64):
		var body := hit["collider"] as RigidBody2D
		if body != null:
			body.linear_velocity += Vector2(randf_range(-1, 1), randf_range(-0.6, 0.2)).normalized() * 2200.0 * power
	Sfx.play(&"fwoosh", 0.0, 0.6)
	sandbox.add_shake(14.0)
	queue_free()


func _draw() -> void:
	var grow := minf(age / 0.5, 1.0) * (1.0 - clampf((age - duration + 0.4) / 0.4, 0.0, 1.0))
	if grow <= 0.01:
		return
	# Dust kicked up at the base.
	for puff in 8:
		var angle := age * 5.0 + TAU * puff / 8.0
		draw_circle(Vector2(cos(angle) * 140.0, -14.0 + sin(angle) * 12.0), 38.0 * grow, Color(0.6, 0.55, 0.5, 0.35))
	# The funnel: lots of see-through bands, wide at the top, snaking as it spins,
	# so whatever it has caught still shows inside it.
	var bands := 26
	for band in bands:
		var t := float(band) / (bands - 1)
		var y := -HEIGHT * (1.0 - t) * grow
		var radius := lerpf(RADIUS * 1.05, 34.0, pow(t, 0.8)) * grow
		var sway := sin(age * 2.6 + t * 4.5) * 60.0 * (1.0 - t) + sin(age * 7.0 + t * 11.0) * 8.0
		var center := Vector2(sway, y)
		var shade := Color(0.78, 0.81, 0.88).darkened(0.25 * t)
		shade.a = 0.42
		draw_colored_polygon(Art.ellipse(radius, 20.0 + 6.0 * (1.0 - t), center, 28), shade)
		var front := Art.ellipse(radius, 20.0 + 6.0 * (1.0 - t), center, 28)
		front.append(front[0])
		draw_polyline(front, Color(Art.INK, 0.35), 2.0, true)
		# Wind streaks whipping round.
		var streak := fmod(age * 3.0 + t * 7.0, 1.0)
		var from := center + Vector2(cos(streak * TAU) * radius, sin(streak * TAU) * 14.0)
		draw_line(from, from + Vector2(-radius * 0.35 * signf(sin(streak * TAU) + 0.01), 0), Color(1, 1, 1, 0.55), 3.0, true)
