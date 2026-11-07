class_name DecalLayer
extends Node2D
## Stains that stay on the room's walls and floor: blood now, scorch marks later.
## Painted into one half-resolution image, so thousands of splats cost nothing to
## draw. Only Clean Up wipes it.

const SCALE := 2
const BRUSH_SIZES := [2, 3, 4, 6, 8, 11, 14, 18, 24]
const SHADES := [Color("8a0c1a"), Color("a3121f"), Color("6e0a15")]

var image: Image
var texture: ImageTexture
## Brushes by shade, then by size: soft-edged circles.
var _brushes: Array = []
var _dirty := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	name = "Decals"
	_rng.randomize()
	var size := Vector2i(Room.SIZE) / SCALE
	image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	texture = ImageTexture.create_from_image(image)
	for shade: Color in SHADES:
		var brush_set: Array[Image] = []
		for radius: int in BRUSH_SIZES:
			brush_set.append(_make_brush(radius, shade))
		_brushes.append(brush_set)


## A splat of roughly `radius` world pixels at `at`, with a few satellite drops.
func splat(at: Vector2, radius: float) -> void:
	_stamp(at, radius)
	var satellites := _rng.randi_range(2, 5)
	for _index in satellites:
		var offset := Vector2.from_angle(_rng.randf() * TAU) * radius * _rng.randf_range(0.8, 1.8)
		_stamp(at + offset, radius * _rng.randf_range(0.15, 0.4))


## A single round drop.
func drop(at: Vector2, radius: float) -> void:
	_stamp(at, radius)


func clear() -> void:
	image.fill(Color(0, 0, 0, 0))
	_dirty = true


## How many sample points (every 8th image pixel) are stained. For tests.
func stained_samples() -> int:
	var count := 0
	for y in range(0, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			if image.get_pixel(x, y).a > 0.1:
				count += 1
	return count


func is_stained(at: Vector2) -> bool:
	var pixel := Vector2i(at / SCALE)
	if not Rect2i(Vector2i.ZERO, image.get_size()).has_point(pixel):
		return false
	return image.get_pixelv(pixel).a > 0.1


func _process(_delta: float) -> void:
	if _dirty:
		texture.update(image)
		_dirty = false
		queue_redraw()


func _draw() -> void:
	draw_texture_rect(texture, Rect2(Vector2.ZERO, Room.SIZE), false)


func _stamp(at: Vector2, radius: float) -> void:
	var image_radius := radius / SCALE
	var size_index := 0
	for index in BRUSH_SIZES.size():
		if BRUSH_SIZES[index] <= image_radius:
			size_index = index
	var brush: Image = _brushes[_rng.randi() % _brushes.size()][size_index]
	var center := Vector2i(at / SCALE)
	var half := brush.get_width() / 2
	image.blend_rect(brush, Rect2i(Vector2i.ZERO, brush.get_size()), center - Vector2i(half, half))
	_dirty = true


static func _make_brush(radius: int, shade: Color) -> Image:
	var size := radius * 2 + 2
	var brush := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) / 2.0
	for y in size:
		for x in size:
			var distance := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var alpha := clampf(radius - distance + 0.5, 0.0, 1.0) * 0.92
			if alpha > 0.0:
				brush.set_pixel(x, y, Color(shade, alpha))
	return brush
