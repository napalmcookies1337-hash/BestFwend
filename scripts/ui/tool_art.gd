class_name ToolArt
extends RefCounted
## Draws tool icons and held weapons as vector shapes. Icons are drawn in a
## 10 x 10 unit box around `center`; `color` tints the Hand and the lock.

const INK := Color("1e1426")
const METAL := Color("b8bec9")
const WOOD := Color("c58b4a")
const RED := Color("e8534a")


static func draw_icon(canvas: CanvasItem, tool_id: String, center: Vector2, size: float, color: Color) -> void:
	var u := size / 10.0
	var c := center
	match tool_id:
		"hand":
			_draw_hand(canvas, c, size, color)
		"locked":
			_draw_lock(canvas, c, size, color)
		"poke":
			_stroke(canvas, [c + Vector2(-3, 4) * u, c + Vector2(3, -4) * u], 2.2 * u, Color("ffc9a0"))
			_disc(canvas, c + Vector2(-3, 4) * u, 2.4 * u, Color("ffc9a0"))
		"slap":
			_disc(canvas, c + Vector2(0, 1) * u, 3.2 * u, Color("ffc9a0"))
			for finger in 4:
				_stroke(canvas, [c + Vector2(-2.2 + finger * 1.5, 0) * u, c + Vector2(-2.6 + finger * 1.7, -4.2) * u], 1.3 * u, Color("ffc9a0"))
			_stroke(canvas, [c + Vector2(3.6, -3) * u, c + Vector2(4.6, -4) * u], 0.5 * u, RED)
		"tickle":
			_stroke(canvas, [c + Vector2(-4, 4) * u, c + Vector2(3.5, -3.5) * u], 0.5 * u, Color("f2f2f2"))
			for barb in 6:
				var along := c + Vector2(-2.5 + barb * 1.0, 2.5 - barb * 1.0) * u
				_stroke(canvas, [along, along + Vector2(-1.8, -0.6) * u], 0.8 * u, Color("8fd3ff"))
				_stroke(canvas, [along, along + Vector2(0.6, 1.8) * u], 0.8 * u, Color("8fd3ff"))
		"pin":
			_stroke(canvas, [c + Vector2(0, -3) * u, c + Vector2(0, 4.5) * u], 0.9 * u, METAL)
			_disc(canvas, c + Vector2(0, -3.2) * u, 2.0 * u, METAL)
		"ball":
			_disc(canvas, c, 3.6 * u, RED)
			_stroke(canvas, [c + Vector2(-2, -1.5) * u, c + Vector2(-0.8, -2.6) * u], 0.7 * u, Color(1, 1, 1, 0.7))
		"brick":
			_box(canvas, Rect2(c + Vector2(-4.2, -2.2) * u, Vector2(8.4, 4.4) * u), Color("b5503c"))
			_stroke(canvas, [c + Vector2(-4, 0) * u, c + Vector2(4, 0) * u], 0.35 * u, Color("7a3324"))
		"anvil":
			_poly(canvas, [Vector2(-4.5, -2), Vector2(4, -2), Vector2(2.8, -0.5), Vector2(1.4, -0.3),
					Vector2(1.6, 1.6), Vector2(3, 2.4), Vector2(-3, 2.4), Vector2(-1.6, 1.6), Vector2(-1.4, -0.3),
					Vector2(-4.8, -1)], c, u, Color("5a5f6e"))
		"bat":
			canvas.draw_set_transform(c, -0.8, Vector2.ONE)
			_draw_bat(canvas, u * 0.95, Vector2(0, 4) * u)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"katana":
			canvas.draw_set_transform(c, -0.8, Vector2.ONE)
			_draw_katana(canvas, u * 0.95, Vector2(0, 4) * u)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"grenade":
			_disc(canvas, c + Vector2(0, 0.8) * u, 3.0 * u, Color("4f6b2e"))
			_box(canvas, Rect2(c + Vector2(-1, -3.8) * u, Vector2(2, 1.6) * u), METAL)
			_stroke(canvas, [c + Vector2(1, -3) * u, c + Vector2(3, -2) * u], 0.5 * u, METAL)
		"dynamite":
			_box(canvas, Rect2(c + Vector2(-1.4, -3) * u, Vector2(2.8, 6.4) * u), Color("d23b3b"))
			_stroke(canvas, [c + Vector2(0, -3) * u, c + Vector2(1.4, -4.6) * u], 0.4 * u, INK)
			_disc(canvas, c + Vector2(1.6, -4.8) * u, 0.8 * u, Color("ffd23f"))
		"landmine":
			_box(canvas, Rect2(c + Vector2(-4, -0.5) * u, Vector2(8, 2.6) * u), Color("5d6650"))
			_box(canvas, Rect2(c + Vector2(-1.3, -1.6) * u, Vector2(2.6, 1.2) * u), METAL)
			_disc(canvas, c + Vector2(2.6, 0.6) * u, 0.5 * u, RED)
		"pistol":
			_poly(canvas, [Vector2(-4, -2.2), Vector2(4, -2.2), Vector2(4, -0.4), Vector2(-0.6, -0.4),
					Vector2(-1.2, 3.4), Vector2(-3.6, 3.4), Vector2(-2.8, -0.4), Vector2(-4, -0.4)], c, u, Color("3c4150"))
		"rocket":
			canvas.draw_set_transform(c, -0.7, Vector2.ONE)
			_poly(canvas, [Vector2(-1.2, 3.5), Vector2(-1.2, -2.2), Vector2(0, -4.4), Vector2(1.2, -2.2), Vector2(1.2, 3.5)], Vector2.ZERO, u, Color("d9dde3"))
			_poly(canvas, [Vector2(-1.2, 1.5), Vector2(-2.6, 3.8), Vector2(-1.2, 3.5)], Vector2.ZERO, u, RED)
			_poly(canvas, [Vector2(1.2, 1.5), Vector2(2.6, 3.8), Vector2(1.2, 3.5)], Vector2.ZERO, u, RED)
			canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"mini_nuke":
			_poly(canvas, [Vector2(-2.4, -4), Vector2(2.4, -4), Vector2(2.4, 2), Vector2(0, 4.4), Vector2(-2.4, 2)], c, u, Color("e9d24a"))
			_disc(canvas, c + Vector2(0, -0.6) * u, 1.3 * u, INK)
		"lightning":
			_poly(canvas, [Vector2(1, -4.6), Vector2(-2.6, 0.6), Vector2(-0.2, 0.6), Vector2(-1.2, 4.6),
					Vector2(2.8, -1), Vector2(0.4, -1), Vector2(1.8, -4.6)], c, u, Color("ffe066"))
		"ignite":
			_poly(canvas, [Vector2(0, -4.6), Vector2(2.8, -0.4), Vector2(2.4, 2.6), Vector2(0, 4.2),
					Vector2(-2.4, 2.6), Vector2(-2.8, -0.4), Vector2(-1, -1.6)], c, u, Color("ff8a1f"))
			_poly(canvas, [Vector2(0, -1), Vector2(1.3, 1.4), Vector2(0, 3), Vector2(-1.3, 1.4)], c, u, Color("ffd23f"))
		"freeze":
			for arm in 3:
				var direction := Vector2.from_angle(PI / 2 + arm * PI / 3)
				_stroke(canvas, [c - direction * 4.2 * u, c + direction * 4.2 * u], 0.8 * u, Color("bfe9ff"))
		"black_hole":
			_disc(canvas, c, 4.0 * u, Color(0.45, 0.25, 0.85))
			_disc(canvas, c, 2.6 * u, Color(0.03, 0.0, 0.06))
		"telekinesis":
			canvas.draw_arc(c, 3.8 * u, 0.0, TAU, 32, Color(0.75, 0.45, 1.0), 0.9 * u, true)
			canvas.draw_arc(c, 2.2 * u, 0.6, TAU - 0.6, 24, Color(0.85, 0.65, 1.0), 0.7 * u, true)
			_disc(canvas, c, 0.9 * u, Color(0.9, 0.8, 1.0))
		_:
			var font := ThemeDB.fallback_font
			var font_size := int(size * 0.6)
			var text := tool_id.left(1).to_upper()
			var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			canvas.draw_string(font, c + Vector2(-text_size.x / 2, text_size.y / 3), text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## The bat or katana in the hand, drawn with the grip at the origin pointing up (-y).
static func draw_weapon(canvas: CanvasItem, tool_id: String) -> void:
	if tool_id == "katana":
		_draw_katana(canvas, 17.0, Vector2.ZERO)
	else:
		_draw_bat(canvas, 17.0, Vector2.ZERO)


static func _draw_bat(canvas: CanvasItem, u: float, grip: Vector2) -> void:
	var shape := PackedVector2Array([Vector2(-0.35, 0), Vector2(-0.35, -3), Vector2(-0.9, -8.4),
			Vector2(-0.6, -9), Vector2(0.6, -9), Vector2(0.9, -8.4), Vector2(0.35, -3), Vector2(0.35, 0)])
	_outlined(canvas, shape, grip, u, WOOD)
	_disc(canvas, grip, 0.6 * u, Color("8a5a2b"))


static func _draw_katana(canvas: CanvasItem, u: float, grip: Vector2) -> void:
	_outlined(canvas, PackedVector2Array([Vector2(-0.3, -1.6), Vector2(-0.3, -9.4), Vector2(0.4, -10),
			Vector2(0.35, -1.6)]), grip, u, Color("e9eef5"))
	_outlined(canvas, PackedVector2Array([Vector2(-1.1, -1.7), Vector2(1.1, -1.7), Vector2(1.1, -1.2),
			Vector2(-1.1, -1.2)]), grip, u, Color("c9a24a"))
	_outlined(canvas, PackedVector2Array([Vector2(-0.35, -1.2), Vector2(0.35, -1.2), Vector2(0.35, 1.4),
			Vector2(-0.35, 1.4)]), grip, u, Color("2b2b33"))


static func _outlined(canvas: CanvasItem, shape: PackedVector2Array, origin: Vector2, u: float, fill: Color) -> void:
	var outer := PackedVector2Array()
	var middle := Vector2.ZERO
	for point in shape:
		middle += point
	middle /= shape.size()
	for point in shape:
		outer.append(origin + (point + (point - middle).normalized() * 0.3) * u)
	canvas.draw_colored_polygon(outer, INK)
	var inner := PackedVector2Array()
	for point in shape:
		inner.append(origin + point * u)
	canvas.draw_colored_polygon(inner, fill)


static func _disc(canvas: CanvasItem, at: Vector2, radius: float, fill: Color) -> void:
	canvas.draw_circle(at, radius + maxf(radius * 0.18, 2.0), INK)
	canvas.draw_circle(at, radius, fill)


static func _box(canvas: CanvasItem, rect: Rect2, fill: Color) -> void:
	canvas.draw_rect(rect.grow(maxf(rect.size.y * 0.1, 2.0)), INK)
	canvas.draw_rect(rect, fill)


static func _stroke(canvas: CanvasItem, points: Array, width: float, fill: Color) -> void:
	canvas.draw_line(points[0], points[1], INK, width + maxf(width * 0.5, 3.0), true)
	canvas.draw_line(points[0], points[1], fill, width, true)


static func _poly(canvas: CanvasItem, points: Array, center: Vector2, u: float, fill: Color) -> void:
	var shape := PackedVector2Array()
	for point: Vector2 in points:
		shape.append(point)
	_outlined(canvas, shape, center, u, fill)


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
