extends Node2D
## Draws every prestige weapon's icon, and what each one puts in the room, on one
## screen and saves it to tests/shots/prestige_sheet.png. Needs a real window.

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
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + "prestige_sheet.png"))
	print("prestige sheet saved")
	get_tree().quit()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1920, 1080), Color("231d31"))
	var font := ThemeDB.fallback_font
	var tools := ToolCatalog.all().filter(func(tool: ToolDef) -> bool: return tool.prestige)
	# Big icons, 8 per row.
	for index in tools.size():
		var center := Vector2(120 + (index % 8) * 230, 95 + (index / 8) * 200)
		draw_rect(Rect2(center - Vector2(78, 78), Vector2(156, 156)), Color("3a3150"))
		ToolArt.draw_icon(self, tools[index].id, center, BIG, Color.WHITE)
		draw_string(font, center + Vector2(-100, 98), tools[index].display_name, HORIZONTAL_ALIGNMENT_CENTER, 200, 18, Color("f6f0e6"))
	# Toolbar-size icons.
	for index in tools.size():
		var center := Vector2(60 + index * 100, 470)
		draw_rect(Rect2(center - Vector2(46, 46), Vector2(92, 92)), Color("3a3150"))
		ToolArt.draw_icon(self, tools[index].id, center, SMALL, Color.WHITE)
	# What they put in the room, at real size.
	draw_rect(Rect2(0, 540, 1920, 540), Color("3d5a80"))
	draw_rect(Rect2(0, 1000, 1920, 80), Color("8a5a3b"))
	var origin := Transform2D.IDENTITY
	ToolArt.giant_fist(self, Art.place(origin, Vector2(130, 680), 0.0, 1.7), 4.0)
	ToolArt.piano(self, Art.place(origin, Vector2(400, 680), 0.0, 2.3), 4.0)
	ToolArt.sawblade(self, Art.place(origin, Vector2(620, 640), 0.0, 0.7), 3.2)
	ToolArt.wrecking_ball(self, Art.place(origin, Vector2(780, 680), 0.0, 72.0 / 44.0), 4.0)
	ToolArt.cluster_bomb(self, Art.place(origin, Vector2(930, 640), 0.0, 0.62), 3.2)
	ToolArt.bomblet(self, Art.place(origin, Vector2(1010, 650), 0.0, 0.5), 3.0)
	ToolArt.rocket(self, Art.place(origin, Vector2(1090, 640), PI, 0.78), 3.2, 0.5)
	ToolArt.meteor(self, Art.place(origin, Vector2(1200, 640), 0.0, 0.9), 4.0, 0.3)
	ToolArt.chainsaw(self, Transform2D(-0.5, Vector2.ONE * 1.4, 0.0, Vector2(1370, 660)), 3.5)
	ToolArt.rocket(self, Transform2D(0.0, Vector2.ONE * 0.55, 0.0, Vector2(1520, 640)), 3.0, 0.5)
	ToolArt.flame(self, Transform2D(PI, Vector2.ONE * 0.5, 0.0, Vector2(1520, 684)), 2.0, 0.3)
	ToolArt.tornado(self, Transform2D(0.0, Vector2(4.4, 8.6), 0.0, Vector2(1720, 650)), 4.0, 0.4)
	ToolArt.shark(self, Transform2D(-0.4, Vector2.ONE * 1.6, 0.0, Vector2(300, 900)), 3.5, 1.0)
	var fin := PackedVector2Array([Vector2(574, 1004), Vector2(604, 954), Vector2(622, 1004)])
	draw_colored_polygon(fin, Color("7b8fa6"))
	draw_polyline(fin, Art.INK, 3.0, true)
	for width: float in [154.0, 70.0, 24.0]:
		draw_line(Vector2(900, 770), Vector2(900, 1000), Color(0.45, 0.95, 1.0, 0.25 if width > 100.0 else 0.8) if width > 30.0 else Color.WHITE, width)
