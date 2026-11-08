extends Node2D
## Draws every skin, colour and room on one screen and saves it to
## tests/shots/looks_sheet.png, for reviewing the art. Needs a real window.

const OUT := "res://tests/shots/"


func _ready() -> void:
	get_window().size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(OUT)
	queue_redraw()
	_capture.call_deferred()


func _capture() -> void:
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "looks_sheet.png"))
	print("looks sheet saved")
	get_tree().quit()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color("3a3150"))
	var font := ThemeDB.fallback_font
	var skins := Cosmetics.SKINS.keys()
	var colors := Cosmetics.COLORS.keys()
	for index in skins.size():
		var at := Vector2(100 + index * 190, 250)
		SkinArt.preview(self, Transform2D(0.0, Vector2.ONE * 0.62, 0.0, at), Cosmetics.color_of(colors[index % colors.size()]), skins[index])
		draw_string(font, at + Vector2(-90, 110), Cosmetics.SKINS[skins[index]]["name"], HORIZONTAL_ALIGNMENT_CENTER, 180, 18, Color.WHITE)
	for index in colors.size():
		var at := Vector2(80 + index * 160, 520)
		SkinArt.preview(self, Transform2D(0.0, Vector2.ONE * 0.4, 0.0, at), Cosmetics.color_of(colors[index]), "classic")
	var rooms := Cosmetics.ROOMS.keys()
	for index in rooms.size():
		var corner := Vector2(20 + index * 316, 640)
		draw_set_transform(corner, 0.0, Vector2.ONE * (300.0 / 1920.0))
		BackgroundArt.draw(self, rooms[index])
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_string(font, corner + Vector2(0, 190), Cosmetics.ROOMS[rooms[index]]["name"], HORIZONTAL_ALIGNMENT_CENTER, 300, 18, Color.WHITE)
	# One room large enough to judge the detail.
	draw_set_transform(Vector2(20, 860), 0.0, Vector2.ONE * 0.11)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
