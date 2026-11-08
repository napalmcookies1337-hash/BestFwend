class_name DevPanel
extends PanelContainer
## Developer tools for testing purchases, unlocks and progression. Debug builds
## only (F10); the exported game never shows it.

var buttons: Dictionary = {}


func _ready() -> void:
	name = "DevPanel"
	custom_minimum_size = Vector2(420, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	var title := Label.new()
	title.text = "Developer tools  [F10]"
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)
	var note := Label.new()
	note.text = "These change your save. Use Play.bat ++ --sandbox\nto try things on a throwaway save."
	note.add_theme_font_size_override("font_size", 15)
	note.add_theme_color_override("font_color", UiTheme.MUTED)
	box.add_child(note)
	_add(box, "+$$$ 10,000", func() -> void: Game.earn(10000, &"dev"))
	_add(box, "+$$$ 1,000,000", func() -> void: Game.earn(1000000, &"dev"))
	_add(box, "Unlock every tool (incl. prestige)", Game.unlock_all_tools)
	_add(box, "Max every owned tool's upgrades", Game.max_upgrades)
	_add(box, "Unlock every look", Game.unlock_all_looks)
	_add(box, "Unlock every achievement", Game.unlock_all_achievements)
	_add(box, "Earn enough to prestige", Game.ready_prestige)
	_add(box, "Unlock a random prestige weapon", func() -> void:
		var weapon := Game.unlock_prestige_weapon()
		if not weapon.is_empty():
			Events.item_unlocked.emit(&"prestige_tool", StringName(weapon)))
	_add(box, "Max out everything", Game.max_everything)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(hide)
	box.add_child(close)
	set_anchors_preset(Control.PRESET_CENTER_LEFT)
	offset_left = 24
	offset_right = 24
	offset_top = 0
	offset_bottom = 0
	grow_vertical = Control.GROW_DIRECTION_BOTH


func _add(box: VBoxContainer, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(func() -> void:
		action.call()
		Game.save_now()
		Events.notification_posted.emit("Debug: %s." % text.to_lower()))
	box.add_child(button)
	buttons[text] = button
