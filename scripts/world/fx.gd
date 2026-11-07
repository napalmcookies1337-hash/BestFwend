class_name Fx
extends Node2D
## Short-lived visual effects drawn above everything in the room: flashes,
## shockwaves, lightning bolts, sparks. Each effect is a draw function called with
## its progress (0 to 1) until its time runs out.

var _effects: Array = []


func _ready() -> void:
	name = "Fx"
	z_index = 30


## Adds an effect: `painter` is called as painter.call(self, progress) each frame.
func add(seconds: float, painter: Callable) -> void:
	_effects.append([0.0, seconds, painter])


func count() -> int:
	return _effects.size()


func clear() -> void:
	_effects.clear()
	queue_redraw()


func _process(delta: float) -> void:
	if _effects.is_empty():
		return
	for index in range(_effects.size() - 1, -1, -1):
		_effects[index][0] += delta
		if _effects[index][0] >= _effects[index][1]:
			_effects.remove_at(index)
	queue_redraw()


func _draw() -> void:
	for effect: Array in _effects:
		var painter: Callable = effect[2]
		if painter.is_valid():
			painter.call(self, clampf(effect[0] / effect[1], 0.0, 1.0))


# Shared painters.

static func flash(at: Vector2, radius: float, color: Color) -> Callable:
	return func(canvas: CanvasItem, t: float) -> void:
		var faded := color
		faded.a *= 1.0 - t
		canvas.draw_circle(at, radius * (0.6 + t * 0.6), faded)


static func ring(at: Vector2, radius: float, color: Color, width: float) -> Callable:
	return func(canvas: CanvasItem, t: float) -> void:
		var faded := color
		faded.a *= 1.0 - t
		canvas.draw_arc(at, radius * (0.2 + t), 0.0, TAU, 48, faded, width * (1.0 - t * 0.6), true)


static func screen_flash(color: Color) -> Callable:
	return func(canvas: CanvasItem, t: float) -> void:
		var faded := color
		faded.a *= (1.0 - t) * (1.0 - t)
		canvas.draw_rect(Rect2(-Vector2.ONE * 200.0, Room.SIZE + Vector2.ONE * 400.0), faded)


static func bolt(from: Vector2, to: Vector2, seed_value: int) -> Callable:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector2Array([from])
	var segments := 12
	for index in range(1, segments):
		var along := from.lerp(to, float(index) / segments)
		points.append(along + Vector2(rng.randf_range(-36.0, 36.0), rng.randf_range(-10.0, 10.0)))
	points.append(to)
	return func(canvas: CanvasItem, t: float) -> void:
		if fmod(t * 6.0, 1.0) > 0.75:
			return
		canvas.draw_polyline(points, Color(0.55, 0.75, 1.0, 0.5 * (1.0 - t)), 22.0, true)
		canvas.draw_polyline(points, Color(1, 1, 1, 1.0 - t * 0.5), 6.0, true)


static func sparks(at: Vector2, count: int, speed: float, color: Color, seed_value: int) -> Callable:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var directions: Array[Vector2] = []
	for index in count:
		directions.append(Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.4, 1.0))
	return func(canvas: CanvasItem, t: float) -> void:
		var faded := color
		faded.a *= 1.0 - t
		for direction in directions:
			var tip := at + direction * speed * t
			canvas.draw_line(tip - direction * 18.0, tip, faded, 4.0, true)


static func smoke(at: Vector2, radius: float, seed_value: int) -> Callable:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var puffs: Array = []
	for index in 8:
		puffs.append([Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.2, 0.7), rng.randf_range(0.4, 0.8)])
	return func(canvas: CanvasItem, t: float) -> void:
		for puff: Array in puffs:
			var center: Vector2 = at + puff[0] * (1.0 + t) + Vector2(0, -60.0 * t)
			canvas.draw_circle(center, radius * float(puff[1]) * (0.5 + t * 0.6), Color(0.25, 0.22, 0.24, 0.55 * (1.0 - t)))
