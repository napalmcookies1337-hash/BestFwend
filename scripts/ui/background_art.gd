class_name BackgroundArt
extends RefCounted
## Paints each room's backdrop over the full 1920 x 1080 room, floor at y = 880.
## Purely visual: every room has the same walls. Big props stay clear of the
## money panel (top left), the room buttons (top right) and the toolbar (bottom).

const SIZE := Vector2(1920, 1080)
const FLOOR := 880.0
const INK := Art.INK


static func draw(canvas: CanvasItem, room_id: String) -> void:
	match room_id:
		"kitchen":
			_kitchen(canvas)
		"backyard":
			_backyard(canvas)
		"lab":
			_lab(canvas)
		"dungeon":
			_dungeon(canvas)
		"space":
			_space(canvas)
		_:
			_bedroom(canvas)
	# Soft shadow where wall meets floor, for every room.
	canvas.draw_rect(Rect2(0, FLOOR, SIZE.x, 12), Color(0, 0, 0, 0.2))


# --- Rooms -------------------------------------------------------------------

static func _bedroom(canvas: CanvasItem) -> void:
	var trim := Color("f1e3cf")
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE.x, FLOOR)), Color("3d5a80"))
	var x := 0.0
	while x < SIZE.x:
		canvas.draw_rect(Rect2(x, 0, 30, FLOOR), Color("43638c"))
		x += 60.0
	_window(canvas, Rect2(1300, 170, 380, 300), trim, Color("9fd8ff"), Color("ffd6a0"))
	# A poster and a shelf with a plant.
	var origin := Transform2D.IDENTITY
	Art.shape(canvas, origin, Art.rect(250, 190, Vector2(560, 330)), trim, 4.0, false)
	_gradient(canvas, Rect2(450, 250, 220, 160), Color("ffb36b"), Color("ff7a8a"))
	Art.flat(canvas, origin, PackedVector2Array([Vector2(450, 410), Vector2(530, 300), Vector2(590, 370), Vector2(630, 320), Vector2(670, 410)]), Color("5b3f7a"))
	Art.flat(canvas, origin, Art.circle(20, Vector2(610, 290)), Color("fff1b0"))
	Art.shape(canvas, origin, Art.rect(300, 18, Vector2(960, 520)), Color("8a5a3b"), 4.0)
	Art.shape(canvas, origin, Art.round_rect(50, 46, 6, Vector2(900, 488)), Color("d96c4a"), 4.0)
	for leaf in 5:
		var tip := Vector2(900, 460) + Vector2.from_angle(-PI / 2 + (leaf - 2) * 0.45) * 52.0
		Art.stroke(canvas, origin, Vector2(900, 466), tip, 9.0, Color("5fb36b"), 3.0)
	for book in 4:
		Art.shape(canvas, origin, Art.rect(22, 70 - book * 6, Vector2(990 + book * 26, 476 + book * 3)), [Color("e8534a"), Color("6ec6ff"), Color("ffd23f"), Color("7fe0a8")][book], 3.0, false)
	_planks(canvas, Color("8a5a3b"), Color("74492f"))
	canvas.draw_rect(Rect2(0, FLOOR - 26, SIZE.x, 26), trim)


static func _kitchen(canvas: CanvasItem) -> void:
	var origin := Transform2D.IDENTITY
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE.x, FLOOR)), Color("d8eedf"))
	# Tiled lower wall.
	canvas.draw_rect(Rect2(0, 500, SIZE.x, FLOOR - 500), Color("fbfbf7"))
	var tile := 60.0
	var y := 500.0
	while y < FLOOR:
		canvas.draw_line(Vector2(0, y), Vector2(SIZE.x, y), Color("cdd9d2"), 3.0)
		y += tile
	var x := 0.0
	while x < SIZE.x:
		canvas.draw_line(Vector2(x, 500), Vector2(x, FLOOR), Color("cdd9d2"), 3.0)
		x += tile
	canvas.draw_rect(Rect2(0, 488, SIZE.x, 16), Color("e8604c"))
	_window(canvas, Rect2(980, 170, 320, 250), Color("ffffff"), Color("9fd8ff"), Color("e0f4ff"))
	for side: float in [-1.0, 1.0]:
		var curtain := Rect2(1140 + side * 190 - 50, 150, 100, 300)
		_checks(canvas, curtain, Color("e8604c"), Color("fff4ee"), 25.0)
		canvas.draw_rect(curtain, INK, false, 4.0)
	canvas.draw_rect(Rect2(900, 142, 480, 14), Color("8a5a3b"))
	# Cabinets and counter on the left.
	Art.shape(canvas, origin, Art.rect(620, 210, Vector2(470, 265)), Color("c98a4b"), 4.0)
	for door in 4:
		var door_x := 237.5 + door * 155.0
		canvas.draw_rect(Rect2(door_x - 66, 176, 132, 178), Color("b47a40"), false, 4.0)
		Art.shape(canvas, origin, Art.circle(7, Vector2(door_x + 48 * (1 if door % 2 == 0 else -1), 300)), Color("e6b33e"), 3.0)
	Art.shape(canvas, origin, Art.rect(660, 26, Vector2(470, 640)), Color("8fa3b8"), 4.0)
	Art.shape(canvas, origin, Art.rect(620, 228, Vector2(470, 766)), Color("c98a4b"), 4.0)
	for drawer in 3:
		Art.shape(canvas, origin, Art.rect(170, 26, Vector2(260 + drawer * 210, 700)), Color("b47a40"), 3.0, false)
	Art.shape(canvas, origin, Art.round_rect(90, 70, 10, Vector2(330, 596)), Color("e8604c"), 4.0)
	Art.shape(canvas, origin, Art.rect(110, 10, Vector2(330, 562)), Color("8fa3b8"), 3.0, false)
	# Fridge on the right.
	Art.shape(canvas, origin, Art.round_rect(230, 480, 22, Vector2(1610, 640)), Color("f4f6f8"), 4.0)
	canvas.draw_line(Vector2(1495, 560), Vector2(1725, 560), INK, 4.0)
	Art.stroke(canvas, origin, Vector2(1520, 470), Vector2(1520, 530), 8.0, Color("b8c0cc"), 3.0)
	Art.stroke(canvas, origin, Vector2(1520, 600), Vector2(1520, 700), 8.0, Color("b8c0cc"), 3.0)
	for magnet: Array in [[Vector2(1620, 470), Color("ff6464")], [Vector2(1670, 510), Color("6ec6ff")], [Vector2(1640, 640), Color("ffd23f")]]:
		Art.shape(canvas, origin, Art.circle(12, magnet[0]), magnet[1], 3.0)
	# Checkered floor.
	_checks(canvas, Rect2(0, FLOOR, SIZE.x, SIZE.y - FLOOR), Color("3a3550"), Color("e9e5dc"), 80.0)
	canvas.draw_rect(Rect2(0, FLOOR - 22, SIZE.x, 22), Color("f3efe7"))


static func _backyard(canvas: CanvasItem) -> void:
	var origin := Transform2D.IDENTITY
	_gradient(canvas, Rect2(Vector2.ZERO, Vector2(SIZE.x, FLOOR)), Color("74c3ff"), Color("d9f1ff"))
	Art.flat(canvas, origin, Art.circle(80, Vector2(1150, 190), 40), Color(1.0, 0.95, 0.6, 0.35))
	Art.shape(canvas, origin, Art.circle(56, Vector2(1150, 190), 40), Color("fff1a8"), 0.0)
	for cloud: Vector2 in [Vector2(600, 170), Vector2(900, 300), Vector2(1550, 420)]:
		for puff: Array in [[Vector2(-50, 10), 38.0], [Vector2(0, -12), 52.0], [Vector2(55, 8), 40.0], [Vector2(10, 22), 36.0]]:
			Art.flat(canvas, origin, Art.circle(puff[1], cloud + puff[0], 28), Color("ffffff"))
	for hill: Array in [[Vector2(300, 760), Vector2(520, 220)], [Vector2(1100, 790), Vector2(700, 230)], [Vector2(1750, 760), Vector2(480, 200)]]:
		Art.flat(canvas, origin, Art.ellipse(hill[1].x, hill[1].y, hill[0], 48), Color("8cd17d"))
	# Fence.
	canvas.draw_rect(Rect2(0, 640, SIZE.x, 18), Color("d9c4a0"))
	canvas.draw_rect(Rect2(0, 760, SIZE.x, 18), Color("d9c4a0"))
	var post := 30.0
	while post < SIZE.x:
		var picket := PackedVector2Array([Vector2(post - 22, FLOOR), Vector2(post - 22, 590), Vector2(post, 560), Vector2(post + 22, 590), Vector2(post + 22, FLOOR)])
		Art.shape(canvas, origin, picket, Color("f6ead2"), 4.0)
		post += 64.0
	# Tree.
	Art.shape(canvas, origin, Art.rect(70, 420, Vector2(300, 670)), Color("8a5a3b"), 4.0)
	for leaf: Array in [[Vector2(220, 380), 110.0], [Vector2(380, 360), 120.0], [Vector2(300, 270), 130.0], [Vector2(230, 480), 80.0], [Vector2(390, 470), 90.0]]:
		Art.shape(canvas, origin, Art.circle(leaf[1], leaf[0], 40), Color("4fae5e"), 4.0)
	for apple: Vector2 in [Vector2(250, 330), Vector2(360, 420), Vector2(310, 230), Vector2(410, 300)]:
		Art.shape(canvas, origin, Art.circle(13, apple, 16), Color("ff5d5d"), 3.0)
	# Grass.
	canvas.draw_rect(Rect2(0, FLOOR, SIZE.x, SIZE.y - FLOOR), Color("5cb85c"))
	var stripe := 0.0
	while stripe < SIZE.x:
		canvas.draw_rect(Rect2(stripe, FLOOR, 120, SIZE.y - FLOOR), Color("53ab53"))
		stripe += 240.0
	var tuft := 10.0
	while tuft < SIZE.x:
		for blade in 3:
			canvas.draw_line(Vector2(tuft + blade * 8, FLOOR + 6), Vector2(tuft + blade * 8 - 6 + blade * 6, FLOOR - 16), Color("3f9a45"), 4.0, true)
		tuft += 46.0


static func _lab(canvas: CanvasItem) -> void:
	var origin := Transform2D.IDENTITY
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE.x, FLOOR)), Color("dfe7ee"))
	var tile := 120.0
	var x := 0.0
	while x < SIZE.x:
		canvas.draw_line(Vector2(x, 0), Vector2(x, FLOOR), Color("c8d3dd"), 3.0)
		x += tile
	var y := 0.0
	while y < FLOOR:
		canvas.draw_line(Vector2(0, y), Vector2(SIZE.x, y), Color("c8d3dd"), 3.0)
		y += tile
	# Whiteboard full of science.
	Art.shape(canvas, origin, Art.rect(520, 300, Vector2(560, 360)), Color("ffffff"), 5.0, false)
	canvas.draw_rect(Rect2(300, 506, 520, 12), Color("9aa3b5"))
	var scribbles := [
		[Vector2(340, 260), Vector2(420, 250), Vector2(460, 290), Vector2(520, 240), Color("3b6fd6")],
		[Vector2(340, 330), Vector2(400, 350), Vector2(470, 320), Vector2(560, 360), Color("d64545")],
		[Vector2(600, 260), Vector2(660, 300), Vector2(700, 250), Vector2(780, 280), Color("3b9b5a")],
	]
	for line: Array in scribbles:
		canvas.draw_polyline(PackedVector2Array([line[0], line[1], line[2], line[3]]), line[4], 5.0, true)
	canvas.draw_arc(Vector2(680, 410), 50, PI, TAU, 20, Color("3b6fd6"), 5.0, true)
	canvas.draw_line(Vector2(620, 410), Vector2(740, 410), Color("3b6fd6"), 4.0)
	canvas.draw_line(Vector2(360, 470), Vector2(560, 400), Color("d64545"), 4.0)
	# Shelf of bubbling flasks.
	Art.shape(canvas, origin, Art.rect(460, 20, Vector2(1180, 520)), Color("9aa3b5"), 4.0)
	var liquids := [Color("7be08f"), Color("ff7ab6"), Color("58c4ff"), Color("ffd23f")]
	for flask in 4:
		var base := Vector2(1010 + flask * 110, 508)
		var glass := PackedVector2Array([base + Vector2(-38, 0), base + Vector2(-10, -60), base + Vector2(-10, -100),
				base + Vector2(10, -100), base + Vector2(10, -60), base + Vector2(38, 0)])
		Art.shape(canvas, origin, glass, Color(0.92, 0.97, 1.0), 4.0, false)
		var liquid := PackedVector2Array([base + Vector2(-34, -4), base + Vector2(-20, -34), base + Vector2(20, -34), base + Vector2(34, -4)])
		Art.flat(canvas, origin, liquid, liquids[flask])
		for bubble in 3:
			Art.flat(canvas, origin, Art.circle(4.0 + bubble, base + Vector2(-6 + bubble * 8, -46 - bubble * 22), 10), Color(liquids[flask], 0.7))
	# Hazard stripes and a polished floor.
	_hazard(canvas, Rect2(0, FLOOR - 30, SIZE.x, 30))
	canvas.draw_rect(Rect2(0, FLOOR, SIZE.x, SIZE.y - FLOOR), Color("aeb8c4"))
	canvas.draw_rect(Rect2(0, FLOOR + 40, SIZE.x, 18), Color(1, 1, 1, 0.25))


static func _dungeon(canvas: CanvasItem) -> void:
	var origin := Transform2D.IDENTITY
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE.x, FLOOR)), Color("2a2630"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var row := 0
	var y := 0.0
	while y < FLOOR:
		var x := -60.0 if row % 2 == 0 else 0.0
		while x < SIZE.x:
			var shade := Color("4a4552").darkened(rng.randf_range(0.0, 0.25))
			canvas.draw_rect(Rect2(x + 4, y + 4, 112, 52), shade)
			canvas.draw_rect(Rect2(x + 4, y + 4, 112, 8), shade.lightened(0.12))
			x += 120.0
		y += 60.0
		row += 1
	# Hanging chains.
	for chain_x: float in [880.0, 1040.0]:
		for link in 9:
			var center := Vector2(chain_x, 20 + link * 30)
			var radii := Vector2(9, 16) if link % 2 == 0 else Vector2(4, 16)
			Art.shape(canvas, origin, Art.ellipse(radii.x, radii.y, center, 16), Color("6c6878"), 3.0, false)
	# Torches with warm glow.
	for torch_x: float in [480.0, 1440.0]:
		for glow in 5:
			Art.flat(canvas, origin, Art.circle(220.0 - glow * 36.0, Vector2(torch_x, 330), 40), Color(1.0, 0.6, 0.2, 0.06))
		Art.shape(canvas, origin, PackedVector2Array([Vector2(torch_x - 22, 360), Vector2(torch_x + 22, 360), Vector2(torch_x + 12, 410), Vector2(torch_x - 12, 410)]), Color("6c6878"), 4.0)
		Art.shape(canvas, origin, Art.rect(16, 70, Vector2(torch_x, 430)), Color("7a4e2d"), 4.0)
		ToolArt.flame(canvas, Transform2D(0.0, Vector2.ONE * 0.75, 0.0, Vector2(torch_x, 318)), 3.0, 0.0)
	# Moss at the bottom of the wall.
	for moss in 14:
		Art.flat(canvas, origin, Art.ellipse(rng.randf_range(30, 70), rng.randf_range(10, 18), Vector2(rng.randf_range(0, SIZE.x), FLOOR - rng.randf_range(4, 20)), 20), Color(0.35, 0.55, 0.3, 0.6))
	# Stone slab floor.
	canvas.draw_rect(Rect2(0, FLOOR, SIZE.x, SIZE.y - FLOOR), Color("3a3640"))
	var slab_x := 0.0
	while slab_x < SIZE.x:
		canvas.draw_rect(Rect2(slab_x + 3, FLOOR + 3, 234, 94), Color("55505e"))
		canvas.draw_rect(Rect2(slab_x + 123, FLOOR + 103, 234, 94), Color("4d4856"))
		slab_x += 240.0


static func _space(canvas: CanvasItem) -> void:
	var origin := Transform2D.IDENTITY
	canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE.x, FLOOR)), Color("1b2236"))
	# Wall panels with rivets.
	var panel_x := 0.0
	while panel_x < SIZE.x:
		var panel_y := 0.0
		while panel_y < FLOOR:
			canvas.draw_rect(Rect2(panel_x + 6, panel_y + 6, 228, 208), Color("252e48"))
			canvas.draw_rect(Rect2(panel_x + 6, panel_y + 6, 228, 6), Color("33405f"))
			for corner: Vector2 in [Vector2(20, 20), Vector2(220, 20), Vector2(20, 200), Vector2(220, 200)]:
				canvas.draw_circle(Vector2(panel_x, panel_y) + corner, 5.0, Color("4a5878"))
			panel_y += 220.0
		panel_x += 240.0
	# Porthole onto space with a ringed planet.
	var center := Vector2(960, 360)
	Art.flat(canvas, origin, Art.circle(250, center, 64), Color("6c7a99"))
	Art.flat(canvas, origin, Art.circle(232, center, 64), INK)
	Art.flat(canvas, origin, Art.circle(222, center, 64), Color("070914"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for star in 70:
		var spot := center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 215.0
		canvas.draw_circle(spot, rng.randf_range(1.0, 3.0), Color(1, 1, 1, rng.randf_range(0.4, 1.0)))
	var planet := center + Vector2(50, 30)
	var ring := Art.moved(Art.ellipse(150, 34, Vector2.ZERO, 48), Transform2D(-0.3, planet))
	Art.flat(canvas, origin, ring, Color("ffcf7a"))
	Art.flat(canvas, origin, Art.moved(Art.ellipse(120, 22, Vector2.ZERO, 48), Transform2D(-0.3, planet)), Color("070914"))
	Art.shape(canvas, origin, Art.circle(90, planet, 48), Color("e8834a"), 0.0)
	for band in 3:
		var stripe := Art.rect(200, 10, planet + Vector2(0, -40 + band * 32))
		for piece in Geometry2D.intersect_polygons(Art.circle(90, planet, 48), stripe):
			Art.flat(canvas, origin, piece, Color("c9663a"))
	var front := Art.moved(Art.ellipse(150, 34, Vector2.ZERO, 48), Transform2D(-0.3, planet))
	for piece in Geometry2D.clip_polygons(front, Art.circle(90, planet, 48)):
		var lower := true
		for point in piece:
			lower = lower and (point - planet).rotated(0.3).y > -2.0
		if lower:
			Art.flat(canvas, origin, piece, Color("ffcf7a"))
	for bolt in 12:
		canvas.draw_circle(center + Vector2.from_angle(TAU * bolt / 12.0) * 241.0, 6.0, Color("9aa6c2"))
	# Glowing light strips and a metal grate floor.
	for strip_y: float in [130.0, FLOOR - 40.0]:
		canvas.draw_rect(Rect2(0, strip_y - 10, SIZE.x, 20), Color(0.3, 0.9, 1.0, 0.15))
		canvas.draw_rect(Rect2(0, strip_y - 4, SIZE.x, 8), Color("6ff0ff"))
	canvas.draw_rect(Rect2(0, FLOOR, SIZE.x, SIZE.y - FLOOR), Color("2d3550"))
	var grate := 0.0
	while grate < SIZE.x:
		canvas.draw_line(Vector2(grate, FLOOR), Vector2(grate, SIZE.y), Color("1f2538"), 6.0)
		grate += 28.0
	canvas.draw_rect(Rect2(0, FLOOR, SIZE.x, 6), Color("6ff0ff"))


# --- Shared pieces -----------------------------------------------------------

static func _window(canvas: CanvasItem, window: Rect2, trim: Color, sky_top: Color, sky_bottom: Color) -> void:
	canvas.draw_rect(window.grow(22), INK)
	canvas.draw_rect(window.grow(18), trim)
	_gradient(canvas, window, sky_top, sky_bottom)
	canvas.draw_circle(window.position + Vector2(window.size.x * 0.74, window.size.y * 0.3), 34, Color("fff4c2"))
	canvas.draw_rect(Rect2(window.get_center().x - 7, window.position.y, 14, window.size.y), trim)
	canvas.draw_rect(Rect2(window.position.x, window.get_center().y - 7, window.size.x, 14), trim)
	canvas.draw_rect(Rect2(window.position.x - 30, window.end.y + 18, window.size.x + 60, 22), trim.darkened(0.08))


static func _gradient(canvas: CanvasItem, area: Rect2, top: Color, bottom: Color) -> void:
	var steps := 16
	for index in steps:
		var band := Rect2(area.position.x, area.position.y + area.size.y * index / steps, area.size.x, area.size.y / steps + 1)
		canvas.draw_rect(band, top.lerp(bottom, float(index) / (steps - 1)))


static func _planks(canvas: CanvasItem, floor_color: Color, seam: Color) -> void:
	canvas.draw_rect(Rect2(0, FLOOR, SIZE.x, SIZE.y - FLOOR), floor_color)
	var plank_height := 38.0
	var row := 0
	var y := FLOOR + plank_height
	while y < SIZE.y:
		canvas.draw_line(Vector2(0, y), Vector2(SIZE.x, y), seam, 4)
		var offset := 0.0 if row % 2 == 0 else 160.0
		var x := offset
		while x < SIZE.x:
			canvas.draw_line(Vector2(x, y - plank_height), Vector2(x, y), seam, 4)
			x += 320.0
		y += plank_height
		row += 1


static func _checks(canvas: CanvasItem, area: Rect2, dark: Color, light: Color, cell: float) -> void:
	canvas.draw_rect(area, light)
	var row := 0
	var y := area.position.y
	while y < area.end.y:
		var column := row % 2
		var x := area.position.x + column * cell
		while x < area.end.x:
			canvas.draw_rect(Rect2(x, y, minf(cell, area.end.x - x), minf(cell, area.end.y - y)), dark)
			x += cell * 2.0
		y += cell
		row += 1


static func _hazard(canvas: CanvasItem, area: Rect2) -> void:
	canvas.draw_rect(area, Color("ffd23f"))
	var x := area.position.x - area.size.y
	while x < area.end.x:
		var stripe := PackedVector2Array([Vector2(x, area.end.y), Vector2(x + area.size.y, area.position.y),
				Vector2(x + area.size.y + 26, area.position.y), Vector2(x + 26, area.end.y)])
		canvas.draw_colored_polygon(stripe, INK)
		x += 52.0
