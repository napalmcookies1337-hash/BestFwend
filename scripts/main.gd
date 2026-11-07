extends Node2D
## The sandbox: the room, the play world and the HUD. Owns room-wide actions such as
## slow motion, gravity and cleaning up, and routes keyboard shortcuts.

const BASE_GRAVITY := 1960.0
const SLOWMO_SCALE := 0.3
## Nodes in this group are swept away by Clean Up (spawned objects, severed limbs).
const DEBRIS_GROUP := &"debris"

var room: Room
var world: Node2D
var hud: Hud
var slowmo := false
var gravity := Vector2(0, BASE_GRAVITY)


func _ready() -> void:
	room = Room.new()
	add_child(room)
	world = Node2D.new()
	world.name = "World"
	add_child(world)
	hud = Hud.new()
	hud.name = "Hud"
	add_child(hud)
	hud.set_base_gravity(BASE_GRAVITY)
	hud.respawn_pressed.connect(respawn)
	hud.clean_up_pressed.connect(clean_up)
	hud.slowmo_toggled.connect(set_slowmo)
	hud.gravity_chosen.connect(set_gravity)
	set_gravity(gravity)
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


## The Buddy arrives in Milestone 2; until then this only says so.
func respawn() -> void:
	Events.notification_posted.emit("Your fwend moves in next milestone.")


func clean_up() -> void:
	room.clear_decals()
	for node in get_tree().get_nodes_in_group(DEBRIS_GROUP):
		node.queue_free()
	Events.room_cleaned.emit()
	Events.notification_posted.emit("Squeaky clean.")
