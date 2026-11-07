class_name ToolUser
extends Node2D
## Runs the selected tool. Left-click with anything but the Hand goes here (the
## Hand and right-click belong to the Grabber). Each tool's behavior is made once
## and kept, so tools can remember things between clicks.

var sandbox: Sandbox
var behaviors: Dictionary = {}
var active: ToolBehavior
var cursor := Vector2.ZERO
## Tests move the cursor directly instead of following the mouse.
var manual_cursor := false


func _ready() -> void:
	name = "Tools"
	z_index = 40
	Events.tool_selected.connect(func(_id: StringName) -> void: release_all())


func current() -> ToolBehavior:
	var tool_id := Game.profile.selected_tool
	if tool_id == "hand":
		return null
	return behavior_for(tool_id)


func behavior_for(tool_id: String) -> ToolBehavior:
	if behaviors.has(tool_id):
		return behaviors[tool_id]
	var def := ToolCatalog.get_tool(tool_id)
	if def == null or def.behavior == null:
		return null
	var behavior: ToolBehavior = def.behavior.new()
	behavior.def = def
	behavior.sandbox = sandbox
	behaviors[tool_id] = behavior
	return behavior


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not manual_cursor:
		cursor = get_global_mouse_position()
	if button.pressed:
		if active == null and press(cursor):
			get_viewport().set_input_as_handled()
	elif active != null:
		release(cursor)
		get_viewport().set_input_as_handled()


## Uses the selected tool at `at`. Returns true if a tool took the click.
func press(at: Vector2) -> bool:
	var behavior := current()
	if behavior == null or not Game.can_use_tool(behavior.def.id):
		return false
	cursor = at
	Events.tool_used.emit(StringName(behavior.def.id), at)
	if behavior.def.targeting == ToolDef.Targeting.HOLD or behavior.def.targeting == ToolDef.Targeting.DRAG:
		active = behavior
		behavior.press(at)
	else:
		# One-shot tools are done on press; anything they put in the Hand is
		# released by the Grabber when the button comes up.
		behavior.press(at)
		behavior.release(at)
	return true


func release(at: Vector2) -> void:
	if active == null:
		return
	var behavior := active
	active = null
	behavior.release(at)


func release_all() -> void:
	if active != null:
		release(cursor)


func _physics_process(delta: float) -> void:
	if not manual_cursor and is_inside_tree():
		cursor = get_global_mouse_position()
		# Catch a release that happened over a menu.
		if active != null and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			release(cursor)
	if active != null:
		active.hold(cursor, delta)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var behavior := current()
	if behavior != null:
		behavior.draw_cursor(self, cursor)
