class_name Buddy
extends Node2D
## The fwend: six jointed rigid parts, a motor that gets it up, balances it and
## waddles it around, and a view that draws it. Keep this node at the origin;
## the parts move, not the Buddy.
##
## "Up" is always against gravity, so it stands on whichever wall gravity points at.

## Flew out of the room or the simulation broke. The sandbox respawns it.
signal lost

enum State { RAGDOLL, GETTING_UP, STANDING, GRABBED }

## name: [kind, radius, capsule length, mass, offset from torso, pick priority]
const PARTS := {
	&"leg_l": [BuddyPart.Kind.CAPSULE, 18.0, 58.0, 0.8, Vector2(-26, 62), 1],
	&"leg_r": [BuddyPart.Kind.CAPSULE, 18.0, 58.0, 0.8, Vector2(26, 62), 1],
	&"torso": [BuddyPart.Kind.CIRCLE, 58.0, 0.0, 3.0, Vector2(0, 0), 0],
	&"head": [BuddyPart.Kind.CIRCLE, 60.0, 0.0, 1.6, Vector2(0, -92), 3],
	&"arm_l": [BuddyPart.Kind.CAPSULE, 15.0, 62.0, 0.5, Vector2(-58, 10), 2],
	&"arm_r": [BuddyPart.Kind.CAPSULE, 15.0, 62.0, 0.5, Vector2(58, 10), 2],
}
## [part joined to the torso, pivot offset from torso, lower angle limit, upper angle limit]
const JOINTS := [
	[&"head", Vector2(0, -48), -0.45, 0.45],
	[&"arm_l", Vector2(-54, -12), -2.8, 2.8],
	[&"arm_r", Vector2(54, -12), -2.8, 2.8],
	[&"leg_l", Vector2(-26, 40), -1.3, 1.3],
	[&"leg_r", Vector2(26, 40), -1.3, 1.3],
]

## How hard joints pull separated parts back together each step (0 = engine default).
const JOINT_BIAS := 0.4
## Bend limits are enforced here instead of by the engine: Godot's 2D joint angle
## limits keep adding energy, so a resting Buddy never settles. When a limb bends
## past its limit, both bodies' spins are nudged so it eases back, at this rate.
const LIMIT_RATE := 18.0
## Share of the correction taken by the limb (the torso takes the rest).
const LIMIT_SHARE := {&"head": 0.5, &"arm_l": 0.85, &"arm_r": 0.85, &"leg_l": 0.8, &"leg_r": 0.8}
# Lying on the ground, round parts would roll for ages; this is the extra drag.
const GROUND_SPIN_DRAG := 4.0
const GROUND_SLIDE_DRAG := 1.5
const MAX_SPEED := 6000.0
const MAX_SPIN := 40.0
## How far outside the room a part may get before the Buddy counts as lost.
const ESCAPE_MARGIN := 300.0

# Getting up.
const RECOVER_DELAY := 0.6
const CALM_SPEED := 80.0
const CALM_SPIN := 2.5
const NEAR_GROUND := 170.0
const GETUP_TIME := 0.8
const GETUP_GIVE_UP := 3.0
const MIN_GRAVITY_TO_STAND := 100.0

# Standing: a spring holds the torso at hip height and steering keeps parts upright.
const HOVER_HEIGHT := 86.0
const GROUND_PROBE := 90.0
const HOVER_FREQUENCY := 2.2
const HOVER_DAMPING := 0.6
const TURN_RATE := 14.0
const MAX_TURN := 9.0
const TURN_BLEND := 22.0
const FALL_TILT := 1.0
const AIRBORNE_FALL_TIME := 0.3
## A hit this hard (px/s of velocity change) knocks a standing Buddy over.
const KNOCKDOWN_DV := 520.0

# Wandering.
const WALK_SPEED := 150.0
const WALK_GAIN := 8.0
const STEP_RATE := 10.0
const LEG_SWING := 0.4
const WADDLE := 0.09
const WALK_MIN := 250.0
const WALK_MAX := 700.0
const WALK_GIVE_UP := 6.0
const IDLE_MIN := 1.5
const IDLE_MAX := 4.5
const WANDER_MARGIN := 150.0

# Reporting hits.
const HIT_EVENT_DV := 320.0
const HIT_COOLDOWN := 0.15
const HURT_DV := 750.0
const HURT_TIME := 0.7

var state := State.RAGDOLL
var parts: Dictionary = {}
var part_list: Array[BuddyPart] = []
var torso: BuddyPart
var head: BuddyPart
var joints: Array[PinJoint2D] = []
var total_mass := 0.0
## The room interior, for wandering and the lost check.
var bounds := Rect2(0, 0, 1920, 880)
var color := Color("ffa646")
## Where the eyes look, in world space.
var look_target := Vector2.ZERO
var view: BuddyView

var ground_hit := false
var ground_distance := INF
var stand_strength := 0.0
var walk_direction := 0.0
var walk_phase := 0.0
var hurt_time := 0.0
var held_part: StringName = &""

var _rng := RandomNumberGenerator.new()
var _calm_time := 0.0
var _state_time := 0.0
var _airborne_time := 0.0
var _idle_time := 0.0
var _walk_target := Vector2.ZERO
var _walk_time := 0.0
var _hit_cooldowns: Dictionary = {}
## [part a, local anchor on a, part b, local anchor on b] per joint, to measure stretch.
var _anchors: Array = []
## [limb, lower, upper, limb's share of the correction] per joint.
var _limits: Array = []
var _probe := PhysicsRayQueryParameters2D.new()


## Builds the body with the torso at `at`. Call before adding to the tree.
func build(at: Vector2, body_color: Color, rng_seed: int = 0) -> void:
	name = "Buddy"
	color = body_color
	if rng_seed != 0:
		_rng.seed = rng_seed
	else:
		_rng.randomize()
	for id: StringName in PARTS:
		var spec: Array = PARTS[id]
		var part := BuddyPart.new()
		part.setup(id, spec[0], spec[1], spec[2], spec[3], spec[5])
		part.position = at + spec[4]
		part.impacted.connect(_on_part_impacted)
		add_child(part)
		parts[id] = part
		part_list.append(part)
		total_mass += part.mass
	torso = parts[&"torso"]
	head = parts[&"head"]
	for spec: Array in JOINTS:
		var limb: BuddyPart = parts[spec[0]]
		var pivot: Vector2 = at + spec[1]
		var joint := PinJoint2D.new()
		joint.name = "Joint_" + String(spec[0])
		joint.position = pivot
		joint.disable_collision = true
		joint.bias = JOINT_BIAS
		add_child(joint)
		joint.node_a = joint.get_path_to(torso)
		joint.node_b = joint.get_path_to(limb)
		joints.append(joint)
		_anchors.append([torso, pivot - torso.position, limb, pivot - limb.position])
		_limits.append([limb, spec[2], spec[3], LIMIT_SHARE[spec[0]]])
	view = BuddyView.new()
	view.buddy = self
	add_child(view)
	look_target = at + Vector2(0, 200)
	_idle_time = _rng.randf_range(IDLE_MIN, IDLE_MAX)


func _ready() -> void:
	var excluded: Array[RID] = []
	for part in part_list:
		excluded.append(part.get_rid())
	_probe.exclude = excluded
	_probe.collision_mask = Layers.GROUND


func gravity() -> Vector2:
	var space := get_world_2d().space
	var strength: float = PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY)
	var direction: Vector2 = PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR)
	return direction * strength


func is_walking() -> bool:
	return state == State.STANDING and walk_direction != 0.0


## How far a limb has drifted from its joint on the torso. The view draws limbs
## shifted by this, so brief joint stretch at high speed never shows as a gap.
func joint_gap(part: BuddyPart) -> Vector2:
	for anchor: Array in _anchors:
		if anchor[2] == part:
			return (anchor[0] as BuddyPart).to_global(anchor[1]) - part.to_global(anchor[3])
	return Vector2.ZERO


## The worst joint separation in pixels. Near zero means the body is holding together.
func joint_stretch() -> float:
	var worst := 0.0
	for anchor: Array in _anchors:
		var a: BuddyPart = anchor[0]
		var b: BuddyPart = anchor[2]
		# Anchors were measured with every part unrotated, so they're already local.
		var gap := (a.to_global(anchor[1]) - b.to_global(anchor[3])).length()
		worst = maxf(worst, gap)
	return worst


func on_grabbed(part: BuddyPart) -> void:
	held_part = part.part_name
	_set_state(State.GRABBED)


func on_released() -> void:
	held_part = &""
	_set_state(State.RAGDOLL)


## For tests and debugging: puts every part's velocity to `velocity`.
func launch(velocity: Vector2) -> void:
	for part in part_list:
		part.linear_velocity = velocity
	if state != State.GRABBED:
		_set_state(State.RAGDOLL)


func _physics_process(delta: float) -> void:
	if not _is_intact():
		set_physics_process(false)
		lost.emit()
		return
	_state_time += delta
	hurt_time = maxf(hurt_time - delta, 0.0)
	for key: StringName in _hit_cooldowns.keys():
		_hit_cooldowns[key] = maxf(_hit_cooldowns[key] - delta, 0.0)
	_cap_speeds()
	_enforce_limits()
	var g := gravity()
	_probe_ground(g)
	match state:
		State.RAGDOLL:
			_update_ragdoll(delta, g)
		State.GETTING_UP:
			stand_strength = minf(stand_strength + delta / GETUP_TIME, 1.0)
			_balance(delta, g)
			if stand_strength >= 1.0 and _tilt(g) < 0.25:
				_set_state(State.STANDING)
			elif _state_time > GETUP_GIVE_UP or g.length() < MIN_GRAVITY_TO_STAND:
				_set_state(State.RAGDOLL)
		State.STANDING:
			stand_strength = 1.0
			_update_wander(delta, g)
			_balance(delta, g)
			_check_fall(delta, g)
		State.GRABBED:
			pass


func _enforce_limits() -> void:
	for limit: Array in _limits:
		var limb: BuddyPart = limit[0]
		var bend := angle_difference(torso.rotation, limb.rotation)
		var excess := 0.0
		if bend > limit[2]:
			excess = bend - limit[2]
		elif bend < limit[1]:
			excess = bend - limit[1]
		if excess == 0.0:
			continue
		var relative_spin := limb.angular_velocity - torso.angular_velocity
		var wanted := -excess * LIMIT_RATE
		# Only push back; never slow a limb that is already returning faster.
		if (excess > 0.0 and relative_spin <= wanted) or (excess < 0.0 and relative_spin >= wanted):
			continue
		var correction := wanted - relative_spin
		var share: float = limit[3]
		limb.angular_velocity += correction * share
		torso.angular_velocity -= correction * (1.0 - share)


func _update_ragdoll(delta: float, g: Vector2) -> void:
	for part in part_list:
		if part.get_contact_count() > 0:
			part.angular_velocity *= maxf(1.0 - GROUND_SPIN_DRAG * delta, 0.0)
			part.linear_velocity *= maxf(1.0 - GROUND_SLIDE_DRAG * delta, 0.0)
	var calm :=torso.linear_velocity.length() < CALM_SPEED and absf(torso.angular_velocity) < CALM_SPIN
	var grounded := ground_hit or ground_distance < NEAR_GROUND or _touching_anything()
	if calm and grounded and g.length() >= MIN_GRAVITY_TO_STAND:
		_calm_time += delta
	else:
		_calm_time = 0.0
	if _calm_time >= RECOVER_DELAY:
		_set_state(State.GETTING_UP)


func _balance(delta: float, g: Vector2) -> void:
	var up := -g.normalized()
	var side := Vector2(-up.y, up.x)
	var upright := up.angle() + PI / 2
	var s := stand_strength
	if ground_hit:
		var omega := TAU * HOVER_FREQUENCY
		var error := HOVER_HEIGHT - ground_distance
		var up_speed := torso.linear_velocity.dot(up)
		var accel := g.length() + omega * omega * error - 2.0 * HOVER_DAMPING * omega * up_speed
		accel = clampf(accel, 0.0, g.length() * 3.0)
		torso.apply_central_force(up * accel * total_mass * s)

	var desired_side := walk_direction * WALK_SPEED
	var side_speed := torso.linear_velocity.dot(side)
	if ground_hit:
		torso.apply_central_force(side * (desired_side - side_speed) * WALK_GAIN * total_mass * s)

	var swing := 0.0
	var waddle := 0.0
	if is_walking():
		walk_phase += delta * STEP_RATE
		swing = sin(walk_phase) * LEG_SWING
		waddle = sin(walk_phase) * WADDLE
	else:
		walk_phase = 0.0
	_steer(torso, upright + waddle, s, delta)
	_steer(head, upright - waddle * 0.6, s * 0.8, delta)
	_steer(parts[&"leg_l"], upright + swing, s, delta)
	_steer(parts[&"leg_r"], upright - swing, s, delta)


func _steer(part: BuddyPart, target_angle: float, strength: float, delta: float) -> void:
	var error := angle_difference(part.rotation, target_angle)
	var desired := clampf(error * TURN_RATE, -MAX_TURN, MAX_TURN)
	var blend := clampf(TURN_BLEND * delta, 0.0, 1.0) * strength
	part.angular_velocity = lerpf(part.angular_velocity, desired, blend)


func _update_wander(delta: float, g: Vector2) -> void:
	var up := -g.normalized()
	var side := Vector2(-up.y, up.x)
	if walk_direction == 0.0:
		_idle_time -= delta
		if _idle_time <= 0.0:
			_pick_walk_target(side)
		return
	_walk_time += delta
	var remaining := (_walk_target - torso.global_position).dot(side)
	if absf(remaining) < 25.0 or signf(remaining) != walk_direction or _walk_time > WALK_GIVE_UP:
		walk_direction = 0.0
		_idle_time = _rng.randf_range(IDLE_MIN, IDLE_MAX)


func _pick_walk_target(side: Vector2) -> void:
	var area := bounds.grow(-WANDER_MARGIN)
	var distance := _rng.randf_range(WALK_MIN, WALK_MAX) * (1.0 if _rng.randf() < 0.5 else -1.0)
	var target := torso.global_position + side * distance
	target = target.clamp(area.position, area.end)
	var along := (target - torso.global_position).dot(side)
	if absf(along) < WALK_MIN * 0.5:
		target = torso.global_position - side * distance
		target = target.clamp(area.position, area.end)
		along = (target - torso.global_position).dot(side)
	if absf(along) < 40.0:
		_idle_time = _rng.randf_range(IDLE_MIN, IDLE_MAX)
		return
	_walk_target = target
	walk_direction = signf(along)
	_walk_time = 0.0


func _check_fall(delta: float, g: Vector2) -> void:
	if g.length() < MIN_GRAVITY_TO_STAND or _tilt(g) > FALL_TILT:
		_set_state(State.RAGDOLL)
		return
	_airborne_time = 0.0 if ground_hit else _airborne_time + delta
	if _airborne_time > AIRBORNE_FALL_TIME:
		_set_state(State.RAGDOLL)


func _tilt(g: Vector2) -> float:
	var upright := (-g.normalized()).angle() + PI / 2
	return absf(angle_difference(torso.rotation, upright))


func _probe_ground(g: Vector2) -> void:
	ground_hit = false
	ground_distance = INF
	if g.length() < 1.0:
		return
	_probe.from = torso.global_position
	_probe.to = torso.global_position + g.normalized() * (HOVER_HEIGHT + GROUND_PROBE)
	var hit := get_world_2d().direct_space_state.intersect_ray(_probe)
	if hit.is_empty():
		return
	ground_distance = (hit["position"] - torso.global_position).length()
	ground_hit = ground_distance <= HOVER_HEIGHT + GROUND_PROBE


func _touching_anything() -> bool:
	for part in part_list:
		if part.get_contact_count() > 0:
			return true
	return false


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	_state_time = 0.0
	_calm_time = 0.0
	_airborne_time = 0.0
	walk_direction = 0.0
	if new_state == State.RAGDOLL or new_state == State.GRABBED:
		stand_strength = 0.0
	if new_state == State.GETTING_UP:
		stand_strength = 0.0
	if new_state == State.STANDING:
		_idle_time = _rng.randf_range(IDLE_MIN * 0.5, IDLE_MAX * 0.5)


func _cap_speeds() -> void:
	for part in part_list:
		if part.linear_velocity.length() > MAX_SPEED:
			part.linear_velocity = part.linear_velocity.limit_length(MAX_SPEED)
		part.angular_velocity = clampf(part.angular_velocity, -MAX_SPIN, MAX_SPIN)


func _is_intact() -> bool:
	var room := bounds.grow(ESCAPE_MARGIN)
	for part in part_list:
		var at := part.global_position
		if is_nan(at.x) or is_nan(at.y) or not room.has_point(at):
			return false
	return true


func _on_part_impacted(part: BuddyPart, delta_v: float, normal: Vector2, at: Vector2, collider: Object) -> void:
	if delta_v >= KNOCKDOWN_DV and (state == State.STANDING or state == State.GETTING_UP):
		_set_state(State.RAGDOLL)
	if delta_v >= HURT_DV:
		hurt_time = HURT_TIME
	if delta_v < HIT_EVENT_DV or _hit_cooldowns.get(part.part_name, 0.0) > 0.0:
		return
	_hit_cooldowns[part.part_name] = HIT_COOLDOWN
	var source := &"object"
	if collider is StaticBody2D:
		source = &"wall"
	Events.buddy_hit.emit({
		"part": part.part_name,
		"force": delta_v,
		"normal": normal,
		"source": source,
		"damage": 0.0,
		"position": at,
	})
