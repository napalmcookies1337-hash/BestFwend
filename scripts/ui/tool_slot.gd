class_name ToolSlot
extends Button
## One toolbar button. Shows a tool's icon and hotkey. A tool you don't own yet
## shows dimmed with a lock and its price; clicking it opens the shop.

const SLOT_SIZE := Vector2(96, 96)

var tool_id := ""
var hotkey := 0
## Owned (or free) and ready to use.
var usable := false
var price := 0


func setup(id: String, key_number: int, tooltip: String, is_usable := true, tool_price := 0) -> void:
	tool_id = id
	hotkey = key_number
	tooltip_text = tooltip
	usable = is_usable
	price = tool_price
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
	if usable:
		ToolArt.draw_icon(self, tool_id, center, size.x * 0.66, Color.WHITE)
	else:
		# Dimmed tool with a small lock and its price.
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		ToolArt.draw_icon(self, tool_id, center + Vector2(0, -6), size.x * 0.56, Color.WHITE)
		draw_rect(Rect2(Vector2.ZERO, size), Color(UiTheme.PANEL, 0.55))
		ToolArt.draw_icon(self, "locked", Vector2(size.x - 20, 22), 26.0, UiTheme.MUTED)
		var font := get_theme_default_font()
		var text := Fmt.grouped(price)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string_outline(font, Vector2((size.x - width) / 2, size.y - 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 4, UiTheme.INK)
		draw_string(font, Vector2((size.x - width) / 2, size.y - 9), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiTheme.MONEY)
	if hotkey > 0 and usable:
		var font := get_theme_default_font()
		draw_string(font, Vector2(9, 26), str(hotkey), HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
				UiTheme.TEXT_DARK if button_pressed else UiTheme.MUTED)
