extends Node2D
## The sandbox: the room, the Buddy, the Hand and the HUD. Owns room-wide actions
## such as respawning, slow motion, gravity and cleaning up, and routes shortcuts.

const BASE_GRAVITY := 1960.0
const SLOWMO_SCALE := 0.3
## Nodes in this group are swept away by Clean Up (spawned objects, severed limbs).
const DEBRIS_GROUP := &"debris"

var room: Room
var world: Node2D
var buddy: Buddy
var blood: Blood
var grabber: Grabber
var hud: Hud
var slowmo := false
var gravity := Vector2(0, BASE_GRAVITY)


func _ready() -> void:
	room = Room.new()
	add_child(room)
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	blood = Blood.new()
	blood.decals = room.decals
	blood.bounds = room.interior()
	add_child(blood)
	grabber = Grabber.new()
	grabber.name = "Grabber"
	grabber.bounds = room.interior()
	add_child(grabber)
	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)
	hud.set_base_gravity(BASE_GRAVITY)
	hud.respawn_pressed.connect(respawn)
	hud.clean_up_pressed.connect(clean_up)
	hud.slowmo_toggled.connect(set_slowmo)
	hud.gravity_chosen.connect(set_gravity)
	set_gravity(gravity)
	_spawn_buddy()
	if not Game.load_notice.is_empty():
		Events.notification_posted.emit.call_deferred(Game.load_notice)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


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


## Replaces the Buddy with a fresh, whole one at the spawn point.
func respawn() -> void:
	if buddy != null:
		if grabber.held_buddy == buddy:
			grabber.forget()
		buddy.queue_free()
		buddy = null
	_spawn_buddy(true)
	Events.buddy_respawned.emit()


func clean_up() -> void:
	room.clear_decals()
	blood.clear()
	for node in get_tree().get_nodes_in_group(DEBRIS_GROUP):
		if node == grabber.held:
			grabber.forget()
		node.queue_free()
	Events.room_cleaned.emit()
	Events.notification_posted.emit("Squeaky clean.")


func spawn_test_ball(at: Vector2) -> TestBall:
	var ball := TestBall.new()
	ball.position = at.clamp(Vector2(60, 60), room.interior().end - Vector2(60, 60))
	world.add_child(ball)
	return ball


func _spawn_buddy(respawned := false) -> void:
	buddy = Buddy.new()
	buddy.bounds = room.interior()
	buddy.build(room.spawn_point(), Color(Game.profile.buddy_color))
	if respawned:
		buddy.set_meta(&"respawned", true)
	buddy.lost.connect(_on_buddy_lost)
	world.add_child(buddy)


func _on_buddy_lost() -> void:
	respawn.call_deferred()
