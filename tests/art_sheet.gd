extends Node2D
## Draws every tool icon, room object and held weapon on one screen and saves it to
## tests/shots/art_sheet.png, for reviewing the art. Needs a real window.

const OUT := "res://tests/shots/"
const BIG := 118.0
const SMALL := 63.0


func _ready() -> void:
	get_window().size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(OUT)
	queue_redraw()
	_capture.call_deferred()


func _capture() -> void:
	for _i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "art_sheet.png"))
	print("art sheet saved")
	get_tree().quit()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color("231d31"))
	var font := ThemeDB.fallback_font
	var tools := ToolCatalog.all()
	# Big icons, 11 per row.
	for index in tools.size():
		var column := index % 11
		var row := index / 11
		var center := Vector2(95 + column * 172, 95 + row * 200)
		draw_rect(Rect2(center - Vector2(78, 78), Vector2(156, 156)), Color("3a3150"))
		ToolArt.draw_icon(self, tools[index].id, center, BIG, Color.WHITE)
		draw_string(font, center + Vector2(-78, 98), tools[index].display_name, HORIZONTAL_ALIGNMENT_CENTER, 156, 18, Color("f6f0e6"))
	# Toolbar-size icons on the real slot colour.
	for index in tools.size():
		var center := Vector2(60 + index * 86, 470)
		draw_rect(Rect2(center - Vector2(46, 46), Vector2(92, 92)), Color("3a3150"))
		ToolArt.draw_icon(self, tools[index].id, center, SMALL, Color.WHITE)
	draw_rect(Rect2(center_slot(), Vector2(92, 92)), Color("3a3150"))
	ToolArt.draw_icon(self, "locked", center_slot() + Vector2(46, 46), 46.0, Color("6c6480"))
	# Room objects at their real size on the wallpaper colour.
	draw_rect(Rect2(0, 560, 1920, 520), Color("3d5a80"))
	var spots := [Vector2(90, 680), Vector2(250, 680), Vector2(440, 680), Vector2(620, 680), Vector2(800, 680), Vector2(1010, 680)]
	var origin := Transform2D.IDENTITY
	ToolArt.ball(self, Art.place(origin, spots[0], 0.0, 36.0 / 42.0), 4.0)
	ToolArt.brick(self, Art.place(origin, spots[1]), 4.0)
	ToolArt.anvil(self, Art.place(origin, spots[2] + Vector2(5, -5), 0.0, 1.25), 4.0)
	ToolArt.grenade(self, Art.place(origin, spots[3] + Vector2(0, -5), 0.0, 0.62), 3.2)
	ToolArt.rocket(self, Art.place(origin, spots[4], PI / 2, 0.72), 3.2, 0.5)
	ToolArt.nuke(self, Art.place(origin, spots[5], -PI / 2, 1.1), 4.0)
	ToolArt.dynamite_stick(self, Art.place(origin, Vector2(1180, 690)), 4.0, 0.3, 0.3)
	ToolArt.landmine(self, Art.place(origin, Vector2(1320, 700), 0.0, 0.85), 4.0, true)
	ToolArt.pin_head(self, Art.place(origin, Vector2(1450, 690)), 3.5)
	ToolArt.black_hole(self, Transform2D(0.0, Vector2.ONE * 3.6, 0.0, Vector2(1700, 820)), 5.0, 0.6, 1.0)
	# Held weapons, grip at the cursor.
	draw_set_transform(Vector2(200, 1040), -0.5, Vector2.ONE)
	ToolArt.draw_weapon(self, "bat")
	draw_set_transform(Vector2(520, 1040), -0.5, Vector2.ONE)
	ToolArt.draw_weapon(self, "katana")
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ToolArt.flame(self, Transform2D(0.0, Vector2.ONE * 1.2, 0.0, Vector2(900, 950)), 4.0, 0.3)


func center_slot() -> Vector2:
	return Vector2(1830 - 46, 470 - 46)
