class_name ToolIcon
extends Control
## A tool's icon as a UI element, for the shop.

var tool_id := ""
var dimmed := false


func _init(id: String = "", icon_size := 96.0) -> void:
	tool_id = id
	custom_minimum_size = Vector2.ONE * icon_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_tool(id: String, is_dimmed: bool) -> void:
	tool_id = id
	dimmed = is_dimmed
	modulate = Color(0.45, 0.42, 0.5) if dimmed else Color.WHITE
	queue_redraw()


func _draw() -> void:
	if not tool_id.is_empty():
		ToolArt.draw_icon(self, tool_id, size / 2.0, minf(size.x, size.y) * 0.82, Color.WHITE)
