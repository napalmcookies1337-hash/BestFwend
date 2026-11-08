class_name BlackHole
extends Node2D
## Pulls every loose body toward it for a few seconds, swallows small debris,
## then collapses with an outward burst. The Buddy is never swallowed, just
## stretched, spun and hurt.

const RADIUS := 950.0
const PULL := 5200.0
const SWIRL := 0.35
const EAT_RADIUS := 55.0
const BUDDY_DPS := 6.0
const BURST := 1800.0

var sandbox: Node
var duration := 4.5
var age := 0.0
var _query := PhysicsShapeQueryParameters2D.new()
var _hurt_tick := 0.0
var _noticed := false


func setup(owner_sandbox: Node, at: Vector2, seconds: float) -> void:
	sandbox = owner_sandbox
	name = "BlackHole"
	global_position = at
	duration = seconds
	z_index = 4
	add_to_group(&"debris")
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	_query.shape = circle
	_query.collision_mask = Layers.BUDDY | Layers.OBJECTS


func _physics_process(delta: float) -> void:
	age += delta
	if age >= duration:
		_collapse()
		return
	var strength := minf(age / 0.4, 1.0)
	_query.transform = Transform2D(0.0, global_position)
	var touched_buddy: Buddy = null
	for hit in get_world_2d().direct_space_state.intersect_shape(_query, 64):
		var body := hit["collider"] as RigidBody2D
		if body == null:
			continue
		var offset := global_position - body.global_position
		var distance := maxf(offset.length(), 30.0)
		if distance < EAT_RADIUS and body is WorldObject:
			body.queue_free()
			continue
		var pull := offset / distance * PULL * strength * clampf(1.0 - distance / RADIUS, 0.0, 1.0) * (1.0 + 300.0 / distance)
		var swirl := offset.orthogonal().normalized() * pull.length() * SWIRL
		body.apply_central_force((pull + swirl) * body.mass)
		if body is BuddyPart and not (body as BuddyPart).detached:
			touched_buddy = body.get_parent() as Buddy
	if touched_buddy != null:
		if not _noticed:
			_noticed = true
			touched_buddy.notice(&"black_hole")
		_hurt_tick += delta
		if _hurt_tick >= 0.5 and touched_buddy.torso.global_position.distance_to(global_position) < 260.0:
			_hurt_tick = 0.0
			touched_buddy.take_hit({"part": &"torso", "force": 0.0, "damage": BUDDY_DPS * 0.5,
					"source": &"black_hole", "bleed": false, "quiet": true, "position": touched_buddy.torso.global_position})
	queue_redraw()


func _collapse() -> void:
	set_physics_process(false)
	_query.transform = Transform2D(0.0, global_position)
	for hit in get_world_2d().direct_space_state.intersect_shape(_query, 64):
		var body := hit["collider"] as RigidBody2D
		if body != null:
			var away := (body.global_position - global_position).normalized()
			body.linear_velocity += away * BURST * clampf(1.0 - body.global_position.distance_to(global_position) / RADIUS, 0.2, 1.0)
	sandbox.fx.add(0.5, Fx.ring(global_position, 420.0, Color(0.7, 0.5, 1.0, 0.9), 18.0))
	Sfx.play(&"boom", -6.0, 0.6)
	queue_free()


func _draw() -> void:
	var grow := minf(age / 0.4, 1.0) * (1.0 - clampf((age - duration + 0.3) / 0.3, 0.0, 1.0))
	if grow <= 0.01:
		return
	# Faint swirling arms reaching out to what it pulls.
	for arm in 4:
		var angle := age * 2.5 + TAU * arm / 4.0
		draw_arc(Vector2.ZERO, 260.0 * grow, angle, angle + PI * 0.7, 24, Color(0.62, 0.38, 1.0, 0.18), 10.0, true)
	ToolArt.black_hole(self, Transform2D(0.0, Vector2.ONE * 3.6, 0.0, Vector2.ZERO), 5.0, age, grow)
