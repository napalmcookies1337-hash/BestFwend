class_name Grabber
extends Node2D
## The Hand. Grabs any grabbable body under the cursor and pulls the grabbed point
## toward the cursor with a spring, so the rest of the Buddy dangles. Letting go
## throws with the drag speed, up to a cap.
##
## Left-click grabs while the Hand tool is selected; right-click always grabs.

const PICK_RADIUS := 14.0
## How snappy the pull is, in Hz, and how much it overshoots (1 = none).
const FREQUENCY := 4.5
const DAMPING := 0.7
const MAX_ACCEL := 26000.0
## Share of the pull applied straight to the torso when holding another part,
## so a limb leads the body without being torn off its joint.
const ROOT_SHARE := 0.55
const SPIN_DAMPING := 3.0
const MAX_THROW_SPEED := 5200.0
const THROW_BOOST := 1.1
const TARGET_MARGIN := 30.0
## Objects heavier than this feel heavy in the hand.
const HEAVY_MASS := 5.0
const HEAVY_MIN := 0.15
## How much of its weight the hand still holds up at its heaviest.
const HEAVY_SAG := 0.8
## A grab released this quickly, without moving the cursor, counts as a click.
const CLICK_TIME := 0.25
const CLICK_DRIFT := 14.0

## The room interior. The cursor target is kept inside it.
var bounds := Rect2(0, 0, 1920, 880)
var held: RigidBody2D
var held_offset := Vector2.ZERO
var held_buddy: Buddy
var held_button := MOUSE_BUTTON_NONE
var target := Vector2.ZERO
var target_velocity := Vector2.ZERO
## Tests steer the target directly instead of following the mouse.
var manual_target := false
var _last_target := Vector2.ZERO
var _press_point := Vector2.ZERO
var _held_time := 0.0
var _drift := 0.0
var _query := PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = PICK_RADIUS
	_query.shape = circle
	_query.collision_mask = Layers.GRABBABLE
	_query.collide_with_areas = false


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null:
		return
	if button.pressed:
		if held == null and press(button.button_index, get_global_mouse_position()):
			get_viewport().set_input_as_handled()
	elif held != null and button.button_index == held_button:
		release()
		get_viewport().set_input_as_handled()


## Returns true if the press grabbed something.
func press(button: MouseButton, at: Vector2) -> bool:
	var hand_selected := Game.profile.selected_tool == "hand"
	if button == MOUSE_BUTTON_RIGHT or (button == MOUSE_BUTTON_LEFT and hand_selected):
		if grab_at(at):
			held_button = button
			return true
	return false


func body_at(at: Vector2) -> RigidBody2D:
	_query.transform = Transform2D(0.0, at)
	var best: RigidBody2D = null
	var best_score := -INF
	for hit in get_world_2d().direct_space_state.intersect_shape(_query, 16):
		var body := hit["collider"] as RigidBody2D
		if body == null or not body.is_in_group(&"grabbable"):
			continue
		var score := -body.global_position.distance_to(at) * 0.01
		if body is BuddyPart:
			score += (body as BuddyPart).pick_priority
		if score > best_score:
			best_score = score
			best = body
	return best


func grab_at(at: Vector2) -> bool:
	var body := body_at(at)
	if body == null:
		return false
	_take(body, at)
	return true


## Puts `body` straight into the hand, as if `button` had grabbed it at `at`.
## Tools that spawn something to throw use this.
func hold(body: RigidBody2D, at: Vector2, button: MouseButton) -> void:
	if held != null:
		release()
	_take(body, at)
	held_button = button


func _take(body: RigidBody2D, at: Vector2) -> void:
	held = body
	held_offset = body.to_local(at)
	target = at
	_last_target = at
	_press_point = at
	_held_time = 0.0
	_drift = 0.0
	target_velocity = Vector2.ZERO
	held_buddy = null
	if body is BuddyPart and not (body as BuddyPart).detached:
		held_buddy = body.get_parent() as Buddy
	if held_buddy != null:
		held_buddy.on_grabbed(body as BuddyPart)
		Events.buddy_grabbed.emit((body as BuddyPart).part_name)


func release() -> void:
	if held == null:
		return
	if is_instance_valid(held):
		var bodies: Array = held_buddy.part_list if is_instance_valid(held_buddy) else [held]
		for body: RigidBody2D in bodies:
			# Hand upgrades ("Strong Arm") throw harder.
			var arm := Game.tool_power("hand")
			body.linear_velocity = (body.linear_velocity * THROW_BOOST * arm).limit_length(MAX_THROW_SPEED * sqrt(arm))
		if is_instance_valid(held_buddy):
			var part_name := (held as BuddyPart).part_name
			held_buddy.on_released(held.linear_velocity)
			Events.buddy_released.emit(part_name, held.linear_velocity)
			if _held_time <= CLICK_TIME and _drift <= CLICK_DRIFT:
				held_buddy.on_clicked(part_name)
	held = null
	held_buddy = null
	held_button = MOUSE_BUTTON_NONE


## Drops whatever is held without throwing, when it's about to be freed.
func forget() -> void:
	held = null
	held_buddy = null
	held_button = MOUSE_BUTTON_NONE


func _process(_delta: float) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var shape := Input.CURSOR_ARROW
	if held != null:
		shape = Input.CURSOR_DRAG
	elif Game.profile.selected_tool == "hand" and body_at(get_global_mouse_position()) != null:
		shape = Input.CURSOR_POINTING_HAND
	if Input.get_current_cursor_shape() != shape:
		Input.set_default_cursor_shape(shape)


func _physics_process(delta: float) -> void:
	if held == null:
		return
	if not is_instance_valid(held):
		forget()
		return
	if not manual_target:
		target = get_global_mouse_position()
	target = target.clamp(bounds.position + Vector2.ONE * TARGET_MARGIN, bounds.end - Vector2.ONE * TARGET_MARGIN)
	target_velocity = target_velocity.lerp((target - _last_target) / delta, 0.5)
	_last_target = target
	_held_time += delta
	_drift = maxf(_drift, target.distance_to(_press_point))

	var point := held.to_global(held_offset)
	var lever := point - held.global_position
	var point_velocity := held.linear_velocity + Vector2(-held.angular_velocity * lever.y, held.angular_velocity * lever.x)
	var omega := TAU * FREQUENCY
	var accel := (target - point) * omega * omega - (point_velocity - target_velocity) * 2.0 * DAMPING * omega
	accel = accel.limit_length(MAX_ACCEL)
	var space := get_world_2d().space
	var gravity: Vector2 = PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR) \
			* float(PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY))
	if held_buddy != null and is_instance_valid(held_buddy):
		var mass := held_buddy.total_mass
		# The whole weight hangs from the grabbed point, so everything else dangles.
		# Only the chasing part of the pull is shared with the torso.
		held.apply_force(-gravity * mass, lever)
		if held == held_buddy.torso:
			held.apply_force(accel * mass, lever)
		else:
			held.apply_force(accel * mass * (1.0 - ROOT_SHARE), lever)
			held_buddy.torso.apply_central_force(accel * mass * ROOT_SHARE)
	else:
		# Heavy things lag behind the cursor and sag a little, so an anvil feels like
		# an anvil. heft is 1 for light objects and falls toward HEAVY_MIN.
		var heft := clampf(HEAVY_MASS / held.mass, HEAVY_MIN, 1.0)
		var pull := accel.limit_length(MAX_ACCEL * heft) * sqrt(heft)
		var support := gravity * held.gravity_scale * lerpf(HEAVY_SAG, 1.0, heft)
		held.apply_force((pull - support) * held.mass, lever)
	held.angular_velocity *= maxf(1.0 - SPIN_DAMPING * delta, 0.0)
