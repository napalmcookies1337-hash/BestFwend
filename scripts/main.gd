class_name Sandbox
extends Node2D
## The sandbox: the room, the Buddy, the Hand, the tools and the HUD. Owns
## room-wide actions (respawning, slow motion, gravity, cleaning up, explosions,
## screen shake) and routes shortcuts. Tools reach the world through this node.

const BASE_GRAVITY := 1960.0
const SLOWMO_SCALE := 0.3
## Nodes in this group are swept away by Clean Up (spawned objects, severed limbs).
const DEBRIS_GROUP := &"debris"
## Oldest loose objects disappear past this many.
const MAX_OBJECTS := 40
const MAX_PINS := 4
const MAX_BLACK_HOLES := 2
## An explosive this close to the Buddy makes it nervous.
const BOMB_NOTICE_RANGE := 450.0
const SHAKE_DECAY := 9.0
## Seconds between a shatter and the new Buddy arriving.
const SHATTER_RESPAWN := 2.5

var room: Room
var world: Node2D
var buddy: Buddy
var blood: Blood
var fx: Fx
var grabber: Grabber
var tools: ToolUser
var rewards: Rewards
var minigames: Minigames
var hud: Hud
var camera: Camera2D
var slowmo := false
var gravity := Vector2(0, BASE_GRAVITY)
var objects: Array[Node] = []
var shake := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	camera = Camera2D.new()
	camera.position = Room.SIZE / 2
	add_child(camera)
	camera.make_current()
	room = Room.new()
	add_child(room)
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	blood = Blood.new()
	blood.decals = room.decals
	blood.bounds = room.interior()
	add_child(blood)
	fx = Fx.new()
	add_child(fx)
	grabber = Grabber.new()
	grabber.name = "Grabber"
	grabber.bounds = room.interior()
	add_child(grabber)
	tools = ToolUser.new()
	tools.sandbox = self
	add_child(tools)
	rewards = Rewards.new()
	rewards.sandbox = self
	add_child(rewards)
	add_child(Tracker.new())
	minigames = Minigames.new()
	minigames.sandbox = self
	add_child(minigames)
	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)
	hud.set_base_gravity(BASE_GRAVITY)
	hud.respawn_pressed.connect(respawn)
	hud.clean_up_pressed.connect(clean_up)
	hud.slowmo_toggled.connect(set_slowmo)
	hud.gravity_chosen.connect(set_gravity)
	hud.minigame_requested.connect(func(minigame_id: StringName) -> void: minigames.start(minigame_id))
	hud.minigame_quit.connect(func() -> void:
		minigames.stop()
		hud.minigame_hud.hide_all())
	set_gravity(gravity)
	_spawn_buddy()
	Events.listen(self, Events.looks_changed, func(_kind: StringName) -> void: apply_looks())
	Events.progress_reset.connect(apply_looks)
	if not Game.load_notice.is_empty():
		Events.notification_posted.emit.call_deferred(Game.load_notice)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _process(delta: float) -> void:
	shake = maxf(shake - shake * SHAKE_DECAY * delta - delta * 2.0, 0.0)
	camera.offset = Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * shake


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("slowmo"):
		set_slowmo(not slowmo)
	elif event.is_action_pressed("respawn"):
		respawn()
	elif event.is_action_pressed("clean_up"):
		clean_up()
	elif event.is_action_pressed("toggle_fullscreen"):
		Game.set_setting("fullscreen", not Game.profile.settings["fullscreen"])
	elif event.is_action_pressed("dev_cash") and OS.is_debug_build():
		Game.earn(1000, &"dev")
	elif event.is_action_pressed("dev_ball") and OS.is_debug_build():
		spawn_test_ball(get_global_mouse_position())
	elif event.is_action_pressed("dev_unlock") and OS.is_debug_build():
		Game.unlock_all_tools()
		Events.notification_posted.emit("Debug: every tool unlocked.")
	else:
		for number in range(1, Controls.HOTBAR_SLOTS + 1):
			if event.is_action_pressed("tool_%d" % number):
				hud.select_hotbar(number)
				break


func set_slowmo(enabled: bool) -> void:
	slowmo = enabled
	Engine.time_scale = SLOWMO_SCALE if enabled else 1.0
	hud.set_slowmo_shown(enabled)
	Events.slowmo_changed.emit(enabled)


func set_gravity(value: Vector2) -> void:
	gravity = value
	var space := get_world_2d().space
	PhysicsServer2D.area_set_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY, value.length())
	if value.length() > 0.0:
		PhysicsServer2D.area_set_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, value.normalized())
	# Sleeping bodies don't notice a gravity change on their own.
	for body in get_tree().get_nodes_in_group(DEBRIS_GROUP):
		if body is RigidBody2D:
			(body as RigidBody2D).sleeping = false
	Events.gravity_changed.emit(value)


## Replaces the Buddy with a fresh, whole one at the spawn point. `reformed`
## means it's coming back after shattering, which it'll comment on.
func respawn(reformed := false) -> void:
	if buddy != null:
		if grabber.held != null and is_instance_valid(grabber.held) and grabber.held.get_parent() == buddy:
			grabber.forget()
		tools.release_all()
		buddy.queue_free()
		buddy = null
	_spawn_buddy(true, reformed)
	Events.buddy_respawned.emit()


func clean_up(quiet := false) -> void:
	room.clear_decals()
	blood.clear()
	fx.clear()
	tools.release_all()
	for node in get_tree().get_nodes_in_group(DEBRIS_GROUP):
		if node == grabber.held:
			grabber.forget()
		node.queue_free()
	objects.clear()
	if quiet:
		return
	Events.room_cleaned.emit()
	Events.notification_posted.emit("Squeaky clean.")


func spawn_test_ball(at: Vector2) -> TestBall:
	var ball := TestBall.new()
	ball.position = at.clamp(Vector2(60, 60), room.interior().end - Vector2(60, 60))
	world.add_child(ball)
	return ball


## Puts a WorldObject of `kind` into the room at `at`.
func spawn_object(kind: StringName, at: Vector2, velocity := Vector2.ZERO, power := 1.0) -> WorldObject:
	var object := WorldObject.new()
	object.setup(kind, self)
	object.power_scale = power
	object.position = at.clamp(Vector2(50, 50), room.interior().end - Vector2(50, 50))
	object.linear_velocity = velocity
	_track(object)
	world.add_child(object)
	if object.is_explosive():
		_warn_buddy(at)
	return object


func place_landmine(at: Vector2, power := 1.0) -> Landmine:
	var down := gravity.normalized() if gravity.length() > 1.0 else Vector2.DOWN
	var query := PhysicsRayQueryParameters2D.create(at, at + down * 2000.0, Layers.WALLS)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	var spot: Vector2 = hit.get("position", at)
	var up: Vector2 = hit.get("normal", -down)
	var mine := Landmine.new()
	mine.setup(self, up)
	mine.power_scale = power
	mine.position = spot
	_track(mine)
	world.add_child(mine)
	_warn_buddy(spot)
	return mine


func stick_dynamite(at: Vector2, part: BuddyPart, power := 1.0) -> StickyDynamite:
	var stick := StickyDynamite.new()
	stick.setup(self, at, part)
	stick.power_scale = power
	_track(stick)
	world.add_child(stick)
	_warn_buddy(at)
	return stick


## Nails `body` to the wall at `at`. Past MAX_PINS the oldest pin comes out.
func add_pin(at: Vector2, body: RigidBody2D) -> PinNail:
	var pins := get_tree().get_nodes_in_group(&"pins")
	if pins.size() >= MAX_PINS:
		pins[0].queue_free()
	var nail := PinNail.new()
	world.add_child(nail)
	nail.setup(at, body)
	if body is BuddyPart and not (body as BuddyPart).detached:
		(body.get_parent() as Buddy).notice(&"pinned")
	Sfx.play(&"clink", -4.0)
	return nail


## Removes a pin near `at`. Returns true if there was one.
func remove_pin_near(at: Vector2, reach := 36.0) -> bool:
	for nail in get_tree().get_nodes_in_group(&"pins"):
		if not nail.is_queued_for_deletion() and (nail as Node2D).global_position.distance_to(at) <= reach:
			nail.queue_free()
			Sfx.play(&"clink", -8.0, 0.8)
			return true
	return false


func spawn_black_hole(at: Vector2, seconds: float) -> BlackHole:
	var holes := get_tree().get_nodes_in_group(&"black_holes")
	if holes.size() >= MAX_BLACK_HOLES:
		holes[0].queue_free()
	var hole := BlackHole.new()
	hole.setup(self, at, seconds)
	hole.add_to_group(&"black_holes")
	world.add_child(hole)
	Sfx.play(&"hum", -4.0)
	return hole


## Blows up at `at`: pushes everything within `radius` outward (up to `power`
## px/s at the centre), hurts the Buddy by up to `damage`, may blow limbs off
## (`sever_chance` at point blank; `sever_target` always goes), sets off other
## explosives, and leaves a scorch mark.
func explode(at: Vector2, radius: float, power: float, damage: float, sever_chance: float,
		source := &"explosion", sever_target := &"") -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, at)
	query.collision_mask = Layers.BUDDY | Layers.OBJECTS
	var hit_buddy: Buddy = null
	var closest: BuddyPart = null
	var closest_distance := INF
	for hit in get_world_2d().direct_space_state.intersect_shape(query, 96):
		var body := hit["collider"] as RigidBody2D
		if body == null:
			continue
		var offset := body.global_position - at
		var falloff := _falloff(offset.length(), radius)
		var direction := offset.normalized() if offset.length() > 1.0 else Vector2.UP
		body.linear_velocity += direction * power * falloff
		body.angular_velocity += _rng.randf_range(-8.0, 8.0) * falloff
		if body is BuddyPart and not (body as BuddyPart).detached:
			hit_buddy = body.get_parent() as Buddy
			if offset.length() < closest_distance:
				closest_distance = offset.length()
				closest = body
	for other in get_tree().get_nodes_in_group(&"explosive"):
		if other is Node2D and (other as Node2D).global_position.distance_to(at) < radius * 0.8:
			other.call(&"prime", _rng.randf_range(0.1, 0.3))
	if hit_buddy != null:
		var falloff := _falloff(closest_distance, radius)
		var direction := (closest.global_position - at).normalized()
		for limb: StringName in Buddy.LIMBS:
			var part: BuddyPart = hit_buddy.parts.get(limb)
			if part == null:
				continue
			var limb_falloff := _falloff(part.global_position.distance_to(at), radius)
			if limb == sever_target or (limb_falloff > 0.35 and _rng.randf() < sever_chance * limb_falloff):
				hit_buddy.sever(limb, (part.global_position - at).normalized() * power * limb_falloff * 0.5, source)
		hit_buddy.take_hit({"part": closest.part_name, "force": power * falloff, "damage": damage * falloff,
				"source": &"explosion", "tool": source, "normal": direction, "position": closest.global_position})
		closest.add_mark(closest.to_local(at.lerp(closest.global_position, 0.7)), BuddyPart.Mark.SOOT, 20.0)
	room.decals.scorch(at.clamp(Vector2(20, 20), room.interior().end - Vector2(20, 20)), clampf(radius * 0.16, 20.0, 80.0))
	var big := radius > 600.0
	fx.add(0.18 if not big else 0.6, Fx.screen_flash(Color(1, 0.97, 0.85, 0.9 if big else 0.35)))
	fx.add(0.35, Fx.flash(at, radius * 0.45, Color(1.0, 0.75, 0.25, 0.95)))
	fx.add(0.5, Fx.ring(at, radius, Color(1, 0.9, 0.6, 0.8), 14.0))
	fx.add(0.6, Fx.sparks(at, 18, radius * 0.9, Color("ffcf4a"), _rng.randi()))
	fx.add(1.4, Fx.smoke(at, radius * 0.35, _rng.randi()))
	add_shake(clampf(radius / 18.0, 8.0, 60.0))
	Events.exploded.emit(at, radius)
	Sfx.play(&"big_boom" if big else &"boom", 0.0 if big else -2.0)


## Puts the equipped colour, skin and room on.
func apply_looks() -> void:
	room.set_background(Game.profile.background)
	if buddy != null:
		buddy.color = Color(Game.profile.buddy_color)
		buddy.skin_id = Game.profile.skin


func add_shake(amount: float) -> void:
	shake = maxf(shake, amount)


func _falloff(distance: float, radius: float) -> float:
	return clampf(1.0 - distance / radius, 0.0, 1.0)


func _warn_buddy(at: Vector2) -> void:
	if buddy != null and buddy.torso.global_position.distance_to(at) < BOMB_NOTICE_RANGE:
		buddy.notice(&"bomb_near")


func _track(node: Node) -> void:
	var alive: Array[Node] = []
	for item in objects:
		if is_instance_valid(item) and not item.is_queued_for_deletion():
			alive.append(item)
	objects = alive
	objects.append(node)
	while objects.size() > MAX_OBJECTS:
		var oldest: Node = objects.pop_front()
		if oldest == grabber.held:
			grabber.forget()
		oldest.queue_free()


func _spawn_buddy(respawned := false, reformed := false) -> void:
	buddy = Buddy.new()
	buddy.bounds = room.interior()
	buddy.build(room.spawn_point(), Color(Game.profile.buddy_color))
	buddy.skin_id = Game.profile.skin
	if respawned:
		buddy.set_meta(&"respawned", true)
	if reformed:
		buddy.set_meta(&"reformed", true)
	buddy.lost.connect(_on_buddy_lost)
	buddy.limb_lost.connect(_on_limb_lost)
	buddy.shattered.connect(_on_buddy_shattered)
	world.add_child(buddy)


func _on_limb_lost(limb: StringName, part: BuddyPart) -> void:
	if grabber.held == part:
		# The hand keeps the limb; the rest of the body drops.
		grabber.held_buddy = null
		buddy.on_released(buddy.torso.linear_velocity)
	Sfx.play(&"splat", 0.0, 0.8)
	blood.bleed(buddy.torso, buddy.stumps.back(), 2.5)
	blood.bleed(part, part.cut_at, 1.5)
	blood.spray(part.to_global(part.cut_at), 18.0)


func _on_buddy_lost() -> void:
	respawn.call_deferred()


## A frozen Buddy was knocked out: break it into ice chunks and bring a new one.
func _on_buddy_shattered() -> void:
	_shatter.call_deferred(buddy)


func _shatter(broken: Buddy) -> void:
	if broken == null or broken != buddy:
		return
	var center := broken.torso.global_position
	var chunks_per_part := {&"head": 4, &"torso": 5}
	for part in broken.part_list:
		var count: int = chunks_per_part.get(part.part_name, 2)
		for _index in count:
			var chunk := IceChunk.new()
			chunk.setup(broken.color, part.radius * _rng.randf_range(0.55, 0.85), _rng)
			chunk.position = part.global_position + Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * part.radius * 0.5
			var away := (chunk.position - center).normalized() if chunk.position.distance_to(center) > 1.0 else Vector2.UP
			chunk.linear_velocity = part.linear_velocity + away * _rng.randf_range(350.0, 900.0) + Vector2(0, -250)
			chunk.angular_velocity = _rng.randf_range(-12.0, 12.0)
			_track(chunk)
			world.add_child(chunk)
	fx.add(0.3, Fx.screen_flash(Color(0.8, 0.95, 1.0, 0.45)))
	fx.add(0.5, Fx.ring(center, 260.0, Color(0.85, 0.97, 1.0, 0.9), 12.0))
	fx.add(0.7, Fx.sparks(center, 26, 300.0, Color("e6f7ff"), _rng.randi()))
	add_shake(22.0)
	Sfx.play(&"shatter", 0.0)
	if grabber.held != null and is_instance_valid(grabber.held) and grabber.held.get_parent() == broken:
		grabber.forget()
	tools.release_all()
	broken.queue_free()
	buddy = null
	get_tree().create_timer(SHATTER_RESPAWN, false).timeout.connect(func() -> void:
		if buddy == null:
			respawn(true))
