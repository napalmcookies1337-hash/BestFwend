extends Node2D
## Draws the app icon (your fwend's face, a little battered) and saves it to
## res://icon.png. Needs a real window: res://tests/icon_render.tscn

const SIZE := 256
const ORANGE := Color("ffa646")


func _ready() -> void:
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_window().size = Vector2i(SIZE, SIZE)
	RenderingServer.set_default_clear_color(Color("231d31"))
	queue_redraw()
	_capture.call_deferred()


func _capture() -> void:
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	image.save_png(ProjectSettings.globalize_path("res://icon.png"))
	print("icon saved")
	get_tree().quit()


func _draw() -> void:
	var scale_by := get_viewport_rect().size.x / SIZE
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_by)
	# A rounded tile in the game's UI colour, so it reads on any desktop.
	draw_rect(Rect2(0, 0, SIZE, SIZE), Color(0, 0, 0, 0))
	Art.flat(self, Transform2D.IDENTITY, Art.round_rect(SIZE, SIZE, 46, Vector2(SIZE / 2, SIZE / 2)), Color("2b2540"))
	var xf := Transform2D(0.0, Vector2(128, 132)).scaled_local(Vector2.ONE * 0.92)
	Art.shape(self, xf, Art.circle(104, Vector2.ZERO, 48), ORANGE, 9.0)
	# Blood splat on the cheek.
	var splat := Art.star(9, 20, 12, Vector2(58, 30), 0.3)
	Art.flat(self, xf, splat, Color("a3121f"))
	Art.flat(self, xf, Art.circle(5, Vector2(76, 58), 12), Color("a3121f"))
	# Big eyes, one bigger: a little dazed.
	for eye: Array in [[Vector2(-36, -22), 30.0], [Vector2(34, -26), 26.0]]:
		var center: Vector2 = eye[0]
		var radius: float = eye[1]
		Art.shape(self, xf, Art.circle(radius, center, 28), Color.WHITE, 6.0, false)
		Art.flat(self, xf, Art.circle(radius * 0.45, center + Vector2(4, 4), 20), Art.INK)
		Art.flat(self, xf, Art.circle(radius * 0.16, center + Vector2(-2, -3), 12), Color.WHITE)
	# A wide grin with one tooth.
	var mouth := PackedVector2Array()
	for index in 13:
		var angle := lerpf(0.15, PI - 0.15, index / 12.0)
		mouth.append(Vector2(cos(angle) * 44, 30 + sin(angle) * 34))
	Art.shape(self, xf, mouth, Color("6b1f2a"), 6.0, false)
	Art.flat(self, xf, Art.rect(16, 12, Vector2(-8, 37)), Color.WHITE)
