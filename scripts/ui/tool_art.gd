class_name ToolArt
extends RefCounted
## Draws tool icons as vector shapes. Each tool gets a case here as it's added;
## anything without one falls back to its first letter.


static func draw_icon(canvas: CanvasItem, tool_id: String, center: Vector2, size: float, color: Color) -> void:
	match tool_id:
		"hand":
			_draw_hand(canvas, center, size, color)
		"locked":
			_draw_lock(canvas, center, size, color)
		_:
			var font := ThemeDB.fallback_font
			var font_size := int(size * 0.6)
			var text := tool_id.left(1).to_upper()
			var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			canvas.draw_string(font, center + Vector2(-text_size.x / 2, text_size.y / 3), text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


static func _draw_hand(canvas: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var unit := size / 10.0
	var outline := Color(0.1, 0.07, 0.12)
	var palm := center + Vector2(0, unit * 1.4)
	var fingers := [
		[Vector2(-2.4, -1.0), Vector2(-2.8, -4.2)],
		[Vector2(-0.8, -1.6), Vector2(-0.9, -5.0)],
		[Vector2(0.8, -1.6), Vector2(0.9, -4.8)],
		[Vector2(2.3, -1.0), Vector2(2.7, -3.6)],
		[Vector2(-2.6, 1.6), Vector2(-4.6, -0.2)],
	]
	for pass_index in 2:
		var width := unit * (2.0 if pass_index == 0 else 1.25)
		var paint := outline if pass_index == 0 else color
		for finger: Array in fingers:
			canvas.draw_line(palm + finger[0] * unit, palm + finger[1] * unit, paint, width, true)
			canvas.draw_circle(palm + finger[1] * unit, width / 2, paint)
		canvas.draw_circle(palm, unit * (3.3 if pass_index == 0 else 2.9), paint)


static func _draw_lock(canvas: CanvasItem, center: Vector2, size: float, color: Color) -> void:
	var unit := size / 10.0
	canvas.draw_arc(center + Vector2(0, -unit), unit * 2.2, PI, TAU, 16, color, unit * 0.9, true)
	var body := Rect2(center + Vector2(-unit * 3.2, -unit * 0.6), Vector2(unit * 6.4, unit * 4.6))
	canvas.draw_rect(body, color)
	canvas.draw_circle(center + Vector2(0, unit * 1.4), unit * 0.7, color.darkened(0.6))
