class_name Art
extends RefCounted
## The vector drawing kit behind every tool and object. Each shape gets a dark ink
## outline, a base fill, a shadow on its lower right and a highlight on its upper
## left, so all the art shares one cel-shaded look and one light direction.
##
## Shapes are point lists in design units; `xf` places, scales and rotates them.
## Outline widths are in screen pixels.

const INK := Color("1e1426")
const SHADOW := 0.24
const SHINE := 0.38


## A filled, outlined, shaded polygon.
static func shape(canvas: CanvasItem, xf: Transform2D, points: PackedVector2Array, fill: Color,
		outline := 3.0, shaded := true) -> void:
	var placed := xf * points
	if outline > 0.0:
		for outer in Geometry2D.offset_polygon(placed, outline, Geometry2D.JOIN_ROUND):
			_fill(canvas, outer, INK)
	_fill(canvas, placed, fill)
	if shaded:
		shade(canvas, placed, fill)


## Shadow and highlight crescents for an already-placed polygon.
static func shade(canvas: CanvasItem, placed: PackedVector2Array, fill: Color, strength := 1.0) -> void:
	var box := bounds(placed)
	var reach := clampf(minf(box.size.x, box.size.y) * 0.16, 1.5, 14.0)
	for dark in Geometry2D.clip_polygons(placed, shifted(placed, Vector2(-reach, -reach))):
		_fill(canvas, dark, fill.darkened(SHADOW * strength))
	for inner in Geometry2D.offset_polygon(placed, -reach * 0.55):
		for light in Geometry2D.clip_polygons(inner, shifted(inner, Vector2(reach * 0.6, reach * 0.6))):
			_fill(canvas, light, fill.lightened(SHINE * strength))


## A flat fill with no outline or shading, for details painted on top of a shape.
static func flat(canvas: CanvasItem, xf: Transform2D, points: PackedVector2Array, fill: Color) -> void:
	_fill(canvas, xf * points, fill)


## A line with an ink outline. Width is in design units.
static func stroke(canvas: CanvasItem, xf: Transform2D, from: Vector2, to: Vector2, width: float,
		fill: Color, outline := 3.0) -> void:
	var scale := xf.get_scale().x
	var a := xf * from
	var b := xf * to
	if outline > 0.0:
		canvas.draw_line(a, b, INK, width * scale + outline * 2.0, true)
		canvas.draw_circle(a, (width * scale) / 2.0 + outline, INK)
		canvas.draw_circle(b, (width * scale) / 2.0 + outline, INK)
	canvas.draw_line(a, b, fill, width * scale, true)
	canvas.draw_circle(a, width * scale / 2.0, fill)
	canvas.draw_circle(b, width * scale / 2.0, fill)


## A polyline in design units, without outline.
static func line(canvas: CanvasItem, xf: Transform2D, points: PackedVector2Array, width: float, fill: Color) -> void:
	canvas.draw_polyline(xf * points, fill, width * xf.get_scale().x, true)


static func circle(radius: float, center := Vector2.ZERO, count := 36) -> PackedVector2Array:
	return ellipse(radius, radius, center, count)


static func ellipse(rx: float, ry: float, center := Vector2.ZERO, count := 36) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		var angle := TAU * index / count
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	return points


static func rect(width: float, height: float, center := Vector2.ZERO) -> PackedVector2Array:
	var half := Vector2(width, height) / 2.0
	return PackedVector2Array([center - half, center + Vector2(half.x, -half.y), center + half, center + Vector2(-half.x, half.y)])


static func round_rect(width: float, height: float, radius: float, center := Vector2.ZERO) -> PackedVector2Array:
	var r := minf(radius, minf(width, height) / 2.0)
	var half := Vector2(width, height) / 2.0 - Vector2(r, r)
	var corners := [Vector2(half.x, half.y), Vector2(-half.x, half.y), Vector2(-half.x, -half.y), Vector2(half.x, -half.y)]
	var points := PackedVector2Array()
	for corner in 4:
		for step in 7:
			var angle := PI / 2 * corner + PI / 2 * step / 6.0
			points.append(center + corners[corner] + Vector2(cos(angle), sin(angle)) * r)
	return points


## A vertical capsule `length` tall (caps included).
static func capsule(radius: float, length: float, center := Vector2.ZERO) -> PackedVector2Array:
	var half := maxf(length / 2.0 - radius, 0.0)
	var points := PackedVector2Array()
	for step in 13:
		points.append(center + Vector2(0, -half) + Vector2.from_angle(PI + PI * step / 12.0) * radius)
	for step in 13:
		points.append(center + Vector2(0, half) + Vector2.from_angle(PI * step / 12.0) * radius)
	return points


static func star(tips: int, outer: float, inner: float, center := Vector2.ZERO, spin := -PI / 2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in tips * 2:
		var radius := outer if index % 2 == 0 else inner
		points.append(center + Vector2.from_angle(spin + PI * index / tips) * radius)
	return points


static func moved(points: PackedVector2Array, xf: Transform2D) -> PackedVector2Array:
	return xf * points


static func shifted(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result


static func bounds(points: PackedVector2Array) -> Rect2:
	var box := Rect2(points[0], Vector2.ZERO)
	for point in points:
		box = box.expand(point)
	return box


## Where `child` sits inside `parent`: Transform2D(rotation, scale, 0, offset) in design units.
static func place(parent: Transform2D, offset: Vector2, rotation := 0.0, scale := 1.0) -> Transform2D:
	return parent * Transform2D(rotation, Vector2(scale, scale), 0.0, offset)


static func _fill(canvas: CanvasItem, points: PackedVector2Array, fill: Color) -> void:
	if points.size() >= 3:
		canvas.draw_colored_polygon(points, fill)
