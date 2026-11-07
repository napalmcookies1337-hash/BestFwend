class_name ToolSlot
extends Button
## One toolbar button. Shows a tool's icon and hotkey, or a lock for an empty slot.

const SLOT_SIZE := Vector2(96, 96)

var tool_id := ""
var hotkey := 0


func setup(id: String, key_number: int, tooltip: String) -> void:
	tool_id = id
	hotkey = key_number
	tooltip_text = tooltip
	disabled = id.is_empty()


func _ready() -> void:
	custom_minimum_size = SLOT_SIZE
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	toggled.connect(func(_on: bool) -> void: queue_redraw())


func _draw() -> void:
	var center := size / 2
	if tool_id.is_empty():
		ToolArt.draw_icon(self, "locked", center, size.x * 0.5, UiTheme.MUTED.darkened(0.35))
		return
	var color := UiTheme.TEXT if not button_pressed else Color("ffe2c2")
	ToolArt.draw_icon(self, tool_id, center, size.x * 0.66, color)
	if hotkey > 0:
		var font := get_theme_default_font()
		draw_string(font, Vector2(9, 26), str(hotkey), HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
				UiTheme.TEXT_DARK if button_pressed else UiTheme.MUTED)
