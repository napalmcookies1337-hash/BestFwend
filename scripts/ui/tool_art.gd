class_name ToolArt
extends RefCounted
## Every tool's look: toolbar icons, the objects tools put in the room, and the
## weapons held at the cursor. Drawn with Art in a 100 x 100 design box centred on
## the origin, light from the upper left. Objects in the room call the same
## functions as their icons, so they always match.

const INK := Art.INK
const GLOVE := Color("f7f4ff")
const CUFF := Color("ffd166")
const METAL := Color("b8c0cc")
const STEEL := Color("4b5262")
const WOOD := Color("c98a4b")
const RED := Color("e8473c")
const GOLD := Color("e6b33e")


## A toolbar or cursor icon `size` pixels across. `color` only tints the lock.
static func draw_icon(canvas: CanvasItem, tool_id: String, center: Vector2, size: float, color: Color) -> void:
	var xf := Transform2D(0.0, Vector2.ONE * size / 100.0, 0.0, center)
	var ink := clampf(size * 0.045, 1.6, 4.5)
	match tool_id:
		"hand": glove_open(canvas, xf, ink)
		"poke": glove_point(canvas, Art.place(xf, Vector2(4, 2), 0.35), ink)
		"slap": slap(canvas, xf, ink)
		"tickle": feather(canvas, Art.place(xf, Vector2.ZERO, 0.0, 1.05), ink)
		"pin": push_pin(canvas, Art.place(xf, Vector2(2, 0), 0.5), ink)
		"ball": ball(canvas, Art.place(xf, Vector2.ZERO, 0.0, 0.95), ink)
		"brick": brick_icon(canvas, xf, ink)
		"anvil": anvil(canvas, Art.place(xf, Vector2(3, -4), 0.0, 1.0), ink)
		"bat": bat(canvas, Art.place(xf, Vector2(2, 2), 0.78, 0.95), ink)
		"katana": katana(canvas, Art.place(xf, Vector2(0, 2), 0.78, 0.95), ink)
		"grenade": grenade(canvas, Art.place(xf, Vector2(0, 4), 0.0, 0.95), ink)
		"dynamite": dynamite_bundle(canvas, xf, ink, 0.0)
		"landmine": landmine(canvas, Art.place(xf, Vector2(0, 10), 0.0, 1.0), ink, true)
		"pistol": pistol(canvas, Art.place(xf, Vector2(2, 2), -0.12), ink)
		"rocket": rocket(canvas, Art.place(xf, Vector2(0, 0), 0.78, 0.9), ink, 0.0)
		"mini_nuke": nuke(canvas, Art.place(xf, Vector2(2, 0), -0.7, 0.84), ink)
		"lightning": lightning(canvas, xf, ink)
		"ignite": flame(canvas, xf, ink, 0.0)
		"freeze": snowflake(canvas, xf, ink)
		"black_hole": black_hole(canvas, xf, ink, 0.0, 1.0)
		"telekinesis": brain(canvas, xf, ink)
		"locked": padlock(canvas, Art.place(xf, Vector2.ZERO, 0.0, 0.8), ink, color)
		# Prestige weapons.
		"giant_fist": giant_fist(canvas, Art.place(xf, Vector2(0, 4), 0.0, 0.95), ink)
		"mega_clap": mega_clap(canvas, xf, ink)
		"slingshot": slingshot(canvas, xf, ink)
		"spin_cycle": spin_cycle(canvas, xf, ink)
		"wrecking_ball": wrecking_icon(canvas, xf, ink)
		"chainsaw": chainsaw(canvas, Art.place(xf, Vector2(2, 2), -0.6, 1.0), ink)
		"piano": piano(canvas, Art.place(xf, Vector2(0, 4), 0.0, 0.95), ink)
		"saw_launcher": saw_icon(canvas, xf, ink)
		"cluster_bomb": cluster_icon(canvas, xf, ink)
		"airstrike": airstrike(canvas, xf, ink)
		"rocket_pack": rocket_pack(canvas, xf, ink)
		"tornado": tornado(canvas, xf, ink, 0.0)
		"meteor_shower": meteor(canvas, Art.place(xf, Vector2(6, 8), -0.7, 0.85), ink, 0.0)
		"orbital_laser": orbital_laser(canvas, xf, ink)
		"land_shark": land_shark(canvas, xf, ink)
		_:
			Art.shape(canvas, xf, Art.circle(30), color, ink)


## The bat or katana in the hand: grip at the origin, pointing up (-y), at full size.
static func draw_weapon(canvas: CanvasItem, tool_id: String) -> void:
	var xf := Transform2D(0.0, Vector2.ONE * 1.7, 0.0, Vector2(0, -60))
	if tool_id == "katana":
		katana(canvas, xf, 4.0)
	else:
		bat(canvas, xf, 4.0)


# --- Hand tools --------------------------------------------------------------

static func glove_open(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	Art.shape(canvas, xf, _rotated(Art.capsule(8, 32, Vector2(0, 0)), -0.9, Vector2(-30, 8)), GLOVE, ink)
	for finger: Array in [[-18.0, -22.0, 30.0], [-6.0, -30.0, 40.0], [6.0, -30.0, 40.0], [18.0, -24.0, 32.0]]:
		Art.shape(canvas, xf, Art.capsule(7.5, finger[2], Vector2(finger[0], finger[1])), GLOVE, ink)
	Art.shape(canvas, xf, Art.round_rect(48, 42, 15, Vector2(0, 8)), GLOVE, ink)
	Art.line(canvas, xf, PackedVector2Array([Vector2(-12, 2), Vector2(-10, 12)]), 2.0, GLOVE.darkened(0.25))
	Art.line(canvas, xf, PackedVector2Array([Vector2(0, 4), Vector2(0, 14)]), 2.0, GLOVE.darkened(0.25))
	Art.line(canvas, xf, PackedVector2Array([Vector2(12, 2), Vector2(10, 12)]), 2.0, GLOVE.darkened(0.25))
	_cuff(canvas, xf, Vector2(0, 34), ink)


static func glove_point(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	Art.shape(canvas, xf, Art.capsule(8, 50, Vector2(-12, -22)), GLOVE, ink)
	Art.shape(canvas, xf, Art.round_rect(44, 38, 14, Vector2(2, 12)), GLOVE, ink)
	for row in 3:
		Art.shape(canvas, xf, Art.round_rect(28, 12, 6, Vector2(8, 0 + row * 11)), GLOVE, ink * 0.8)
	Art.shape(canvas, xf, _rotated(Art.capsule(7, 26, Vector2.ZERO), 1.25, Vector2(-10, 20)), GLOVE, ink)
	_cuff(canvas, xf, Vector2(2, 36), ink)


static func slap(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	Art.shape(canvas, xf, Art.star(8, 30, 15, Vector2(22, -22), 0.2), Color("ffcf3a"), ink)
	for arc in 3:
		var y := -10.0 + arc * 14.0
		Art.stroke(canvas, xf, Vector2(-48, y), Vector2(-36, y - 4), 4.0, Color.WHITE, ink * 0.7)
	glove_open(canvas, Art.place(xf, Vector2(4, 6), 0.45, 0.82), ink)


static func _cuff(canvas: CanvasItem, xf: Transform2D, at: Vector2, ink: float) -> void:
	Art.shape(canvas, xf, Art.round_rect(52, 15, 6, at), CUFF, ink)
	Art.line(canvas, xf, PackedVector2Array([at + Vector2(-20, -1), at + Vector2(20, -1)]), 2.0, CUFF.darkened(0.3))


static func feather(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var pink := Color("ff7eb6")
	var vane := PackedVector2Array()
	var steps := 14
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	# A broad, curving vane around a quill running from the lower left to the tip.
	var spine_points := PackedVector2Array()
	for step in steps + 1:
		var t := float(step) / steps
		var along := Vector2(-26, 34).lerp(Vector2(30, -44), t) + Vector2(-sin(t * PI) * 8.0, -sin(t * PI) * 4.0)
		spine_points.append(along)
		var width := sin(clampf(t * 1.1, 0.0, 1.0) * PI) * 24.0 * (0.55 + t * 0.45)
		var normal := Vector2(0.8, 0.6)
		left.append(along - normal * width)
		right.append(along + normal * width * 0.8)
	vane.append_array(left)
	right.reverse()
	vane.append_array(right)
	Art.shape(canvas, xf, vane, pink, ink)
	# Two notches where the vane splits, the classic feather look.
	for notch: int in [5, 10]:
		var root := spine_points[notch]
		Art.line(canvas, xf, PackedVector2Array([root + Vector2(-17, -4), root]), 2.6, pink.darkened(0.35))
	Art.stroke(canvas, xf, Vector2(-36, 46), spine_points[0], 3.6, Color("e9cfa2"), ink * 0.6)
	Art.line(canvas, xf, spine_points, 3.0, Color("fff3e0"))


static func push_pin(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-2.5, 10), Vector2(2.5, 10), Vector2(0, 48)]), METAL, ink * 0.8)
	Art.shape(canvas, xf, Art.ellipse(26, 9, Vector2(0, 10)), RED.darkened(0.15), ink)
	Art.shape(canvas, xf, Art.round_rect(26, 28, 6, Vector2(0, -6)), RED, ink)
	Art.shape(canvas, xf, Art.ellipse(22, 10, Vector2(0, -22)), RED.lightened(0.1), ink)


## The nail as seen in the room: a push-pin head from the front.
static func pin_head(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	Art.shape(canvas, xf, Art.circle(15), RED.darkened(0.1), ink)
	Art.shape(canvas, xf, Art.circle(9, Vector2(-1, -1)), RED.lightened(0.1), ink * 0.6)


# --- Throwables and melee ----------------------------------------------------

static func ball(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var outline := Art.circle(42)
	Art.shape(canvas, xf, outline, RED, ink, false)
	var band := Art.moved(Art.rect(110, 22), Transform2D(-0.45, Vector2.ZERO))
	for stripe in Geometry2D.intersect_polygons(outline, band):
		Art.flat(canvas, xf, stripe, Color("ffd23f"))
	Art.shade(canvas, xf * outline, RED, 0.8)
	Art.flat(canvas, xf, Art.ellipse(9, 6, Vector2(-17, -20)), Color(1, 1, 1, 0.75))


static func brick_icon(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var color := Color("c0583f")
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-42, -6), Vector2(-28, -22), Vector2(46, -22), Vector2(32, -6)]), color.lightened(0.2), ink, false)
	Art.shape(canvas, xf, PackedVector2Array([Vector2(32, -6), Vector2(46, -22), Vector2(46, 14), Vector2(32, 30)]), color.darkened(0.25), ink, false)
	brick(canvas, Art.place(xf, Vector2(-5, 12), 0.0, 0.95), ink)


static func brick(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var color := Color("c0583f")
	Art.shape(canvas, xf, Art.round_rect(78, 38, 4), color, ink)
	for speck: Vector2 in [Vector2(-24, -6), Vector2(-8, 8), Vector2(14, -8), Vector2(26, 6), Vector2(-30, 10)]:
		Art.flat(canvas, xf, Art.circle(2.2, speck, 8), color.darkened(0.35))


static func anvil(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var body := PackedVector2Array([Vector2(-52, -14), Vector2(-30, -22), Vector2(44, -22), Vector2(44, -9),
			Vector2(24, -4), Vector2(16, 6), Vector2(18, 14), Vector2(32, 21), Vector2(32, 30),
			Vector2(-32, 30), Vector2(-32, 21), Vector2(-18, 14), Vector2(-16, 6), Vector2(-24, -4),
			Vector2(-34, -6)])
	Art.shape(canvas, xf, body, STEEL, ink)
	Art.flat(canvas, xf, PackedVector2Array([Vector2(-28, -21), Vector2(43, -21), Vector2(43, -17), Vector2(-26, -17)]), STEEL.lightened(0.45))
	Art.flat(canvas, xf, Art.rect(48, 4, Vector2(0, 24)), STEEL.darkened(0.3))


static func bat(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var body := PackedVector2Array([Vector2(-3.5, 44), Vector2(-3.5, 14), Vector2(-9, -30)])
	for step in 9:
		body.append(Vector2(0, -36) + Vector2.from_angle(PI + PI * step / 8.0) * 9.0)
	body.append_array(PackedVector2Array([Vector2(9, -30), Vector2(3.5, 14), Vector2(3.5, 44)]))
	Art.shape(canvas, xf, body, WOOD, ink)
	Art.line(canvas, xf, PackedVector2Array([Vector2(-3, -34), Vector2(-1.5, 6)]), 1.5, WOOD.lightened(0.3))
	Art.shape(canvas, xf, Art.rect(8, 24, Vector2(0, 32)), Color("2f2b3a"), ink * 0.6, false)
	for wrap in 4:
		var y := 24.0 + wrap * 6.0
		Art.line(canvas, xf, PackedVector2Array([Vector2(-4, y), Vector2(4, y - 3)]), 1.6, Color("6a6480"))
	Art.shape(canvas, xf, Art.ellipse(8, 4.5, Vector2(0, 46)), WOOD.darkened(0.2), ink)


static func katana(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	# A long, slightly curved blade and a short wrapped grip.
	var blade := PackedVector2Array([Vector2(-3, 18), Vector2(-3.5, -10), Vector2(-2.5, -38), Vector2(-0.5, -56),
			Vector2(3, -62), Vector2(4, -52), Vector2(4, -30), Vector2(3.5, 0), Vector2(3, 18)])
	Art.shape(canvas, xf, blade, Color("e9eef5"), ink)
	Art.line(canvas, xf, PackedVector2Array([Vector2(2, 16), Vector2(2.6, -10), Vector2(2.4, -40), Vector2(2.6, -55)]), 1.4, Color.WHITE)
	Art.line(canvas, xf, PackedVector2Array([Vector2(-1, 14), Vector2(0, 4), Vector2(-1.3, -6), Vector2(0, -16),
			Vector2(-1.2, -26), Vector2(0.2, -36), Vector2(-0.6, -46)]), 1.1, Color("aab4c4"))
	Art.shape(canvas, xf, Art.ellipse(11, 3.5, Vector2(0, 20)), GOLD, ink)
	Art.shape(canvas, xf, Art.round_rect(8, 26, 3, Vector2(0, 36)), Color("2b2b38"), ink)
	for wrap in 4:
		var y := 26.0 + wrap * 5.5
		Art.line(canvas, xf, PackedVector2Array([Vector2(-3.5, y), Vector2(3.5, y + 3.5)]), 1.2, Color("d8d2e8"))
		Art.line(canvas, xf, PackedVector2Array([Vector2(3.5, y), Vector2(-3.5, y + 3.5)]), 1.2, Color("d8d2e8"))
	Art.shape(canvas, xf, Art.round_rect(9, 4.5, 2, Vector2(0, 50)), GOLD, ink)


# --- Explosives and weapons --------------------------------------------------

static func grenade(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var olive := Color("617d36")
	var body := Art.ellipse(30, 34, Vector2(0, 8))
	Art.shape(canvas, xf, body, olive, ink)
	for row in [-8.0, 6.0, 20.0]:
		for segment in Geometry2D.intersect_polygons(body, Art.rect(80, 2.4, Vector2(0, row))):
			Art.flat(canvas, xf, segment, olive.darkened(0.4))
	for column in [-12.0, 0.0, 12.0]:
		for segment in Geometry2D.intersect_polygons(body, Art.rect(2.4, 80, Vector2(column, 8))):
			Art.flat(canvas, xf, segment, olive.darkened(0.4))
	Art.shape(canvas, xf, Art.round_rect(20, 12, 3, Vector2(0, -28)), METAL, ink)
	Art.shape(canvas, xf, PackedVector2Array([Vector2(6, -34), Vector2(14, -34), Vector2(26, -14), Vector2(26, 6), Vector2(21, 6), Vector2(20, -12)]), METAL, ink)
	var ring := Art.circle(10, Vector2(-17, -32), 24)
	var hole := Art.circle(6, Vector2(-17, -32), 24)
	for loop in Geometry2D.clip_polygons(ring, hole):
		Art.shape(canvas, xf, loop, Color("d9dee6"), ink * 0.8, false)


## One stick of dynamite, lit. `spark_phase` animates the spark.
static func dynamite_stick(canvas: CanvasItem, xf: Transform2D, ink: float, spark_phase: float, burnt := 0.0) -> void:
	var red := Color("d8352e")
	Art.shape(canvas, xf, Art.round_rect(18, 62, 5), red, ink)
	Art.flat(canvas, xf, Art.rect(18, 7, Vector2(0, -14)), Color("f1e2c4"))
	Art.flat(canvas, xf, Art.rect(18, 7, Vector2(0, 14)), Color("f1e2c4"))
	var tip := Vector2(9, -31 - 18 * (1.0 - burnt))
	Art.stroke(canvas, xf, Vector2(0, -31), tip, 2.4, Color("3a3030"), ink * 0.5)
	_spark(canvas, xf, tip, spark_phase, ink)


static func dynamite_bundle(canvas: CanvasItem, xf: Transform2D, ink: float, spark_phase: float) -> void:
	var red := Color("d8352e")
	for column: float in [-17.0, 17.0, 0.0]:
		Art.shape(canvas, xf, Art.round_rect(18, 60, 5, Vector2(column, 10 + absf(column) * 0.15)), red, ink)
	Art.shape(canvas, xf, Art.round_rect(56, 11, 3, Vector2(0, 14)), Color("b89a6a"), ink)
	Art.stroke(canvas, xf, Vector2(0, -20), Vector2(6, -34), 2.4, Color("3a3030"), ink * 0.5)
	Art.stroke(canvas, xf, Vector2(6, -34), Vector2(16, -38), 2.4, Color("3a3030"), ink * 0.5)
	_spark(canvas, xf, Vector2(16, -38), spark_phase, ink)


static func _spark(canvas: CanvasItem, xf: Transform2D, at: Vector2, phase: float, ink: float) -> void:
	var size := 1.0 + 0.25 * sin(phase * 30.0)
	Art.shape(canvas, xf, Art.star(6, 11 * size, 5 * size, at, phase * 6.0), Color("ffd23f"), ink * 0.6, false)
	Art.flat(canvas, xf, Art.circle(3.5, at, 10), Color.WHITE)


static func landmine(canvas: CanvasItem, xf: Transform2D, ink: float, lit: bool) -> void:
	var green := Color("66704f")
	var dome := PackedVector2Array([Vector2(-46, 8)])
	for step in 13:
		var angle := PI + PI * step / 12.0
		dome.append(Vector2(cos(angle) * 40.0, sin(angle) * 18.0 - 2.0))
	dome.append(Vector2(46, 8))
	Art.shape(canvas, xf, dome, green, ink)
	Art.shape(canvas, xf, Art.round_rect(96, 8, 3, Vector2(0, 8)), green.darkened(0.25), ink)
	Art.shape(canvas, xf, Art.round_rect(30, 8, 3, Vector2(0, -22)), METAL, ink)
	Art.shape(canvas, xf, Art.round_rect(12, 6, 2, Vector2(0, -28)), METAL.darkened(0.15), ink)
	for rivet: float in [-30.0, -15.0, 15.0, 30.0]:
		Art.flat(canvas, xf, Art.circle(2.2, Vector2(rivet, 1), 8), green.darkened(0.4))
	Art.flat(canvas, xf, Art.circle(3.6, Vector2(24, -8), 10), Color("ff3b3b") if lit else Color("5c1a1a"))


static func pistol(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var dark := Color("3a3f4d")
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-26, -4), Vector2(-8, -4), Vector2(-2, 30), Vector2(-22, 32),
			Vector2(-30, 8)]), Color("6b4a33"), ink)
	Art.flat(canvas, xf, PackedVector2Array([Vector2(-20, 4), Vector2(-11, 4), Vector2(-7, 24), Vector2(-17, 25)]), Color("8a6346"))
	var guard := Art.circle(10, Vector2(4, 4), 20)
	var guard_hole := Art.circle(6.5, Vector2(4, 4), 20)
	for loop in Geometry2D.clip_polygons(guard, guard_hole):
		Art.shape(canvas, xf, loop, dark, ink * 0.7, false)
	Art.shape(canvas, xf, Art.round_rect(74, 20, 4, Vector2(4, -12)), dark, ink)
	Art.shape(canvas, xf, Art.rect(8, 6, Vector2(44, -12)), dark.darkened(0.2), ink)
	for slot in 4:
		Art.line(canvas, xf, PackedVector2Array([Vector2(-24 + slot * 5, -19), Vector2(-24 + slot * 5, -9)]), 1.4, dark.lightened(0.3))
	Art.flat(canvas, xf, Art.rect(6, 4, Vector2(36, -23)), dark)


## Pointing up (-y). `flicker` animates the exhaust (0 for a still icon).
static func rocket(canvas: CanvasItem, xf: Transform2D, ink: float, flicker: float) -> void:
	var flame_length := 18.0 + flicker * 10.0
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-8, 32), Vector2(0, 32 + flame_length + 8), Vector2(8, 32)]), Color("ff8a1f"), ink * 0.5, false)
	Art.flat(canvas, xf, PackedVector2Array([Vector2(-4, 32), Vector2(0, 32 + flame_length), Vector2(4, 32)]), Color("ffe066"))
	for side: float in [-1.0, 1.0]:
		Art.shape(canvas, xf, PackedVector2Array([Vector2(10 * side, 12), Vector2(24 * side, 32), Vector2(24 * side, 38), Vector2(10 * side, 32)]), RED, ink)
	Art.shape(canvas, xf, Art.round_rect(22, 62, 6, Vector2(0, 4)), Color("e8ecf2"), ink)
	Art.flat(canvas, xf, Art.rect(22, 6, Vector2(0, 18)), RED)
	Art.shape(canvas, xf, Art.circle(5, Vector2(0, -6)), Color("8fd3ff"), ink * 0.7)
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-11, -24), Vector2(-6, -40), Vector2(0, -48), Vector2(6, -40), Vector2(11, -24)]), RED, ink)


## Nose down (+y), tail fins up.
static func nuke(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var yellow := Color("f0d343")
	Art.shape(canvas, xf, Art.rect(46, 18, Vector2(0, -38)), STEEL, ink)
	for side: float in [-1.0, 1.0]:
		Art.shape(canvas, xf, PackedVector2Array([Vector2(8 * side, -26), Vector2(26 * side, -48), Vector2(26 * side, -30), Vector2(14 * side, -20)]), STEEL.lightened(0.15), ink)
	Art.shape(canvas, xf, Art.ellipse(31, 38, Vector2(0, 8)), yellow, ink)
	Art.flat(canvas, xf, Art.rect(56, 4, Vector2(0, -12)), yellow.darkened(0.3))
	Art.flat(canvas, xf, Art.circle(14, Vector2(0, 12)), INK)
	for blade in 3:
		var angle := -PI / 2 + TAU * blade / 3.0
		var wedge := PackedVector2Array([Vector2(0, 12) + Vector2.from_angle(angle - 0.5) * 3.5, Vector2(0, 12) + Vector2.from_angle(angle - 0.5) * 12.0,
				Vector2(0, 12) + Vector2.from_angle(angle + 0.5) * 12.0, Vector2(0, 12) + Vector2.from_angle(angle + 0.5) * 3.5])
		Art.flat(canvas, xf, wedge, yellow)
	Art.flat(canvas, xf, Art.circle(2.6, Vector2(0, 12), 10), yellow)


# --- Powers -----------------------------------------------------------------

static func lightning(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var bolt := PackedVector2Array([Vector2(4, -18), Vector2(-14, 12), Vector2(-2, 12), Vector2(-12, 46),
			Vector2(18, 4), Vector2(5, 4), Vector2(16, -18)])
	Art.flat(canvas, xf, Art.moved(bolt, Transform2D(0.0, Vector2(1.3, 1.15), 0.0, Vector2(-1, 2))), Color(1.0, 0.9, 0.3, 0.3))
	Art.shape(canvas, xf, bolt, Color("ffe066"), ink)
	var cloud := Color("c9d3e6")
	for puff: Array in [[Vector2(-22, -26), 15.0], [Vector2(0, -34), 19.0], [Vector2(22, -26), 14.0]]:
		Art.shape(canvas, xf, Art.circle(puff[1], puff[0]), cloud, ink)
	Art.shape(canvas, xf, Art.round_rect(64, 18, 9, Vector2(0, -18)), cloud, ink)
	Art.flat(canvas, xf, Art.round_rect(56, 12, 6, Vector2(0, -20)), cloud)
	Art.flat(canvas, xf, Art.circle(12, Vector2(0, -34)), cloud)


static func flame(canvas: CanvasItem, xf: Transform2D, ink: float, phase: float) -> void:
	var outer := PackedVector2Array([Vector2(0, -48), Vector2(10, -26), Vector2(22, -32), Vector2(20, -10),
			Vector2(32, 4), Vector2(28, 26), Vector2(12, 42), Vector2(-12, 42), Vector2(-28, 26), Vector2(-32, 2),
			Vector2(-20, -16), Vector2(-16, -36), Vector2(-6, -22)])
	var wobble := Transform2D(sin(phase * 9.0) * 0.06, Vector2.ONE, 0.0, Vector2.ZERO)
	Art.shape(canvas, xf, Art.moved(outer, wobble), Color("e8401c"), ink)
	Art.flat(canvas, xf, Art.moved(outer, Transform2D(0.0, Vector2(0.66, 0.64), 0.0, Vector2(0, 14))), Color("ff8a1f"))
	Art.flat(canvas, xf, Art.moved(outer, Transform2D(0.0, Vector2(0.34, 0.36), 0.0, Vector2(0, 26))), Color("ffe066"))


static func snowflake(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var ice := Color("a8e2ff")
	for arm in 6:
		var direction := Vector2.from_angle(-PI / 2 + TAU * arm / 6.0)
		Art.stroke(canvas, xf, Vector2.ZERO, direction * 44.0, 7.0, ice, ink)
	for arm in 6:
		var direction := Vector2.from_angle(-PI / 2 + TAU * arm / 6.0)
		for branch: float in [20.0, 32.0]:
			var root := direction * branch
			for side: float in [-1.0, 1.0]:
				Art.stroke(canvas, xf, root, root + direction.rotated(0.9 * side) * (14.0 if branch < 30.0 else 9.0), 5.0, ice, ink * 0.8)
	for arm in 6:
		var direction := Vector2.from_angle(-PI / 2 + TAU * arm / 6.0)
		Art.line(canvas, xf, PackedVector2Array([direction * 6.0, direction * 42.0]), 2.0, Color(1, 1, 1, 0.8))
	Art.shape(canvas, xf, Art.circle(11, Vector2.ZERO, 6), ice.lightened(0.2), ink)


## `spin` turns the disc; `grow` scales it in and out.
static func black_hole(canvas: CanvasItem, xf: Transform2D, ink: float, spin: float, grow: float) -> void:
	var tilt := Transform2D(-0.25, Vector2(grow, grow), 0.0, Vector2.ZERO)
	var disc := Art.moved(Art.ellipse(48, 17), tilt)
	Art.flat(canvas, xf, Art.moved(Art.ellipse(54, 22), tilt), Color(0.62, 0.35, 1.0, 0.35))
	Art.shape(canvas, xf, disc, Color("9a52e8"), ink, false)
	Art.flat(canvas, xf, Art.moved(Art.ellipse(40, 12), tilt), Color("ff9a3c"))
	Art.flat(canvas, xf, Art.moved(Art.ellipse(30, 8.5), tilt), Color("ffe08a"))
	for streak in 5:
		var angle := spin * 2.0 + TAU * streak / 5.0
		var point := Art.moved(PackedVector2Array([Vector2(cos(angle) * 44, sin(angle) * 15), Vector2(cos(angle + 0.5) * 44, sin(angle + 0.5) * 15)]), tilt)
		Art.line(canvas, xf, point, 2.0, Color(1, 1, 1, 0.5))
	Art.shape(canvas, xf, Art.circle(19 * grow), Color("06030c"), ink)
	Art.line(canvas, xf, Art.moved(_arc(23, PI * 1.05, PI * 1.95), tilt), 3.0, Color("ffcf7a"))


static func brain(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var glow := Color(0.7, 0.45, 1.0)
	# Psychic waves rising off the top.
	for ring in 3:
		var radius := 34.0 + ring * 9.0
		Art.line(canvas, xf, Art.shifted(_arc(radius, PI * 1.18, PI * 1.82), Vector2(0, 14)), 4.0 - ring * 0.9, Color(glow, 0.95 - ring * 0.25))
	var pink := Color("ff9ec7")
	var outline := PackedVector2Array()
	for step in 40:
		var angle := TAU * step / 40.0
		# A rounded, slightly lumpy brain silhouette, wider than tall.
		var bump := 1.0 + 0.06 * sin(angle * 7.0)
		outline.append(Vector2(cos(angle) * 36.0, sin(angle) * 27.0 - maxf(-sin(angle), 0.0) * 4.0) * bump + Vector2(0, 12))
	Art.shape(canvas, xf, outline, pink, ink)
	var fold := pink.darkened(0.32)
	Art.line(canvas, xf, PackedVector2Array([Vector2(0, -14), Vector2(-2, -2), Vector2(1, 10), Vector2(-1, 22), Vector2(0, 36)]), 2.4, fold)
	for squiggle: PackedVector2Array in [
			PackedVector2Array([Vector2(-28, 2), Vector2(-20, -4), Vector2(-14, 4), Vector2(-8, -2)]),
			PackedVector2Array([Vector2(-30, 18), Vector2(-22, 12), Vector2(-16, 20), Vector2(-8, 14)]),
			PackedVector2Array([Vector2(-20, 30), Vector2(-12, 26), Vector2(-6, 32)]),
			PackedVector2Array([Vector2(8, -2), Vector2(14, 4), Vector2(20, -4), Vector2(28, 2)]),
			PackedVector2Array([Vector2(8, 14), Vector2(16, 20), Vector2(22, 12), Vector2(30, 18)]),
			PackedVector2Array([Vector2(6, 32), Vector2(12, 26), Vector2(20, 30)])]:
		Art.line(canvas, xf, squiggle, 2.2, fold)


# --- Prestige weapons --------------------------------------------------------

## A huge glove fist, knuckles down.
static func giant_fist(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	_cuff(canvas, Art.place(xf, Vector2(0, -2), 0.0, 1.4), Vector2(0, -26), ink)
	Art.shape(canvas, xf, _rotated(Art.capsule(10, 34, Vector2.ZERO), 1.2, Vector2(-34, 4)), GLOVE, ink)
	Art.shape(canvas, xf, Art.round_rect(78, 56, 20, Vector2(4, 6)), GLOVE, ink)
	for knuckle in 4:
		Art.shape(canvas, xf, Art.round_rect(19, 26, 9, Vector2(-23 + knuckle * 18.5, 34)), GLOVE, ink * 0.8)
	for crease in 3:
		Art.line(canvas, xf, PackedVector2Array([Vector2(-14 + crease * 18.5, 12), Vector2(-14 + crease * 18.5, 22)]), 2.0, GLOVE.darkened(0.25))


static func mega_clap(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	Art.shape(canvas, xf, Art.star(10, 34, 16, Vector2(0, -6), 0.1), Color("ffcf3a"), ink)
	Art.shape(canvas, xf, Art.star(10, 18, 9, Vector2(0, -6), 0.4), Color("ff7a3a"), 0.0, false)
	glove_open(canvas, Art.place(xf, Vector2(-30, 8), 1.4, 0.6), ink)
	glove_open(canvas, Art.place(xf, Vector2(30, 8), -1.4, 0.6), ink)


static func slingshot(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var wood := Color("a8693a")
	Art.shape(canvas, xf, Art.round_rect(14, 44, 6, Vector2(0, 26)), wood, ink)
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-6, 8), Vector2(-30, -34), Vector2(-20, -40), Vector2(0, -6), Vector2(20, -40), Vector2(30, -34), Vector2(6, 8)]), wood, ink)
	Art.line(canvas, xf, PackedVector2Array([Vector2(-25, -36), Vector2(-4, -6), Vector2(4, -6), Vector2(25, -36)]), 4.0, Color("d8352e"))
	Art.shape(canvas, xf, Art.circle(13, Vector2(0, -6)), Color("ffa646"), ink)


static func spin_cycle(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var arrow := Color("6ec6ff")
	for turn in 2:
		var start := PI * turn
		Art.line(canvas, xf, _arc(42, start + 0.3, start + 2.4), 6.0, INK)
		Art.line(canvas, xf, _arc(42, start + 0.3, start + 2.4), 3.5, arrow)
		var tip := Vector2.from_angle(start + 2.4) * 42.0
		var along := Vector2.from_angle(start + 2.4 + PI / 2)
		Art.shape(canvas, xf, PackedVector2Array([tip + along * 12, tip + along.orthogonal() * 9, tip - along.orthogonal() * 9]), arrow, ink * 0.7)
	glove_open(canvas, Art.place(xf, Vector2(0, 2), 0.6, 0.55), ink)


static func wrecking_ball(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	Art.shape(canvas, xf, Art.circle(12, Vector2(0, -44), 16), Color("8a8f9c"), ink)
	Art.flat(canvas, xf, Art.circle(6, Vector2(0, -44), 12), INK)
	Art.shape(canvas, xf, Art.circle(42, Vector2.ZERO, 40), Color("3a3f4d"), ink)
	Art.flat(canvas, xf, Art.rect(84, 8, Vector2(0, -4)), Color("2a2e38"))
	for rivet in 5:
		Art.flat(canvas, xf, Art.circle(2.4, Vector2(-30 + rivet * 15, -4), 8), Color("8a8f9c"))


static func wrecking_icon(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	for link in 4:
		var at := Vector2(-30 + link * 9, -46 + link * 10)
		Art.shape(canvas, xf, Art.moved(Art.ellipse(4, 7, Vector2.ZERO, 12), Transform2D(-0.7, at)), Color("8a8f9c"), ink * 0.6, false)
	wrecking_ball(canvas, Art.place(xf, Vector2(10, 14), -0.6, 0.72), ink)


static func chainsaw(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var bar := Art.round_rect(18, 70, 9, Vector2(0, -26))
	Art.shape(canvas, xf, bar, Color("c9ced8"), ink)
	for tooth in 9:
		var y := -58.0 + tooth * 8.0
		Art.flat(canvas, xf, PackedVector2Array([Vector2(-9, y), Vector2(-14, y + 4), Vector2(-9, y + 7)]), INK)
		Art.flat(canvas, xf, PackedVector2Array([Vector2(9, y), Vector2(14, y + 4), Vector2(9, y + 7)]), INK)
	Art.shape(canvas, xf, Art.round_rect(40, 40, 10, Vector2(0, 22)), Color("f08a24"), ink)
	Art.shape(canvas, xf, Art.round_rect(30, 12, 5, Vector2(0, 46)), Color("2b2b33"), ink)
	Art.flat(canvas, xf, Art.rect(22, 5, Vector2(0, 18)), Color("2b2b33"))


static func sawblade(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	Art.shape(canvas, xf, Art.star(14, 44, 36, Vector2.ZERO, 0.0), Color("d6dbe4"), ink)
	Art.flat(canvas, xf, Art.circle(26, Vector2.ZERO, 32), Color("b8c0cc"))
	Art.flat(canvas, xf, Art.circle(9, Vector2.ZERO, 16), INK)
	Art.line(canvas, xf, _arc(18, -2.4, -1.2), 3.0, Color(1, 1, 1, 0.8))


static func saw_icon(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	for streak in 3:
		Art.stroke(canvas, xf, Vector2(-48, -16 + streak * 16), Vector2(-26, -16 + streak * 16), 4.0, Color.WHITE, ink * 0.6)
	sawblade(canvas, Art.place(xf, Vector2(12, 0), 0.0, 0.85), ink)


static func cluster_bomb(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var red := Color("e8473c")
	var body := Art.circle(34, Vector2(0, 8), 36)
	Art.shape(canvas, xf, body, red, ink)
	for band: float in [-6.0, 22.0]:
		for piece in Geometry2D.intersect_polygons(body, Art.rect(80, 7, Vector2(0, band))):
			Art.flat(canvas, xf, piece, Color("ffd23f"))
	Art.shape(canvas, xf, Art.round_rect(18, 12, 3, Vector2(0, -28)), METAL, ink)
	Art.stroke(canvas, xf, Vector2(0, -34), Vector2(8, -44), 2.4, Color("3a3030"), ink * 0.5)


static func bomblet(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	Art.shape(canvas, xf, Art.circle(20, Vector2.ZERO, 20), Color("2f2b3a"), ink)
	Art.flat(canvas, xf, Art.circle(8, Vector2.ZERO, 12), Color("e8473c"))


static func cluster_icon(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	for spot: Vector2 in [Vector2(-34, 30), Vector2(34, 32), Vector2(-38, -20), Vector2(36, -24)]:
		bomblet(canvas, Art.place(xf, spot, 0.0, 0.42), ink * 0.6)
	cluster_bomb(canvas, Art.place(xf, Vector2(0, -2), 0.0, 0.8), ink)


static func airstrike(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var jet := PackedVector2Array([Vector2(-46, -30), Vector2(30, -36), Vector2(46, -30), Vector2(30, -24), Vector2(-46, -28)])
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-6, -34), Vector2(-24, -52), Vector2(-14, -52), Vector2(12, -34)]), Color("7b8494"), ink * 0.8)
	Art.shape(canvas, xf, jet, Color("9aa3b5"), ink)
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-40, -30), Vector2(-48, -44), Vector2(-38, -44), Vector2(-30, -30)]), Color("7b8494"), ink * 0.8)
	for bomb in 3:
		rocket(canvas, Art.place(xf, Vector2(-24 + bomb * 22, 4 + bomb * 14), PI, 0.32), ink * 0.6, 0.0)


static func rocket_pack(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	for side: float in [-1.0, 1.0]:
		flame(canvas, Art.place(xf, Vector2(18 * side, 40), PI, 0.32), ink * 0.6, 0.0)
		rocket(canvas, Art.place(xf, Vector2(18 * side, -4), 0.0, 0.62), ink, 0.0)
	Art.shape(canvas, xf, Art.round_rect(60, 10, 4, Vector2(0, -6)), Color("6b4a33"), ink)
	Art.shape(canvas, xf, Art.round_rect(60, 10, 4, Vector2(0, 14)), Color("6b4a33"), ink)


## A whirling funnel. `phase` turns its bands.
static func tornado(canvas: CanvasItem, xf: Transform2D, ink: float, phase: float) -> void:
	var grey := Color("aeb7c7")
	for band in 7:
		var t := float(band) / 6.0
		var width := lerpf(44.0, 10.0, t)
		var center := Vector2(sin(phase * 3.0 + t * 4.0) * 8.0 * (1.0 - t), -40.0 + t * 84.0)
		Art.shape(canvas, xf, Art.ellipse(width, lerpf(9.0, 4.0, t), center, 24), grey.darkened(t * 0.25), ink * 0.8)
	for streak in 3:
		var y := -30.0 + streak * 24.0
		Art.line(canvas, xf, PackedVector2Array([Vector2(-30 + streak * 6, y), Vector2(-10, y + 4)]), 2.0, Color(1, 1, 1, 0.7))


## A flaming rock, moving toward +y with its fire trailing toward -y.
static func meteor(canvas: CanvasItem, xf: Transform2D, ink: float, phase: float) -> void:
	var flicker := 1.0 + 0.12 * sin(phase * 30.0)
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-30, 0), Vector2(0, -110 * flicker), Vector2(30, 0)]), Color("e8401c"), ink * 0.6, false)
	Art.flat(canvas, xf, PackedVector2Array([Vector2(-20, 0), Vector2(0, -76 * flicker), Vector2(20, 0)]), Color("ff8a1f"))
	Art.flat(canvas, xf, PackedVector2Array([Vector2(-10, 4), Vector2(0, -44 * flicker), Vector2(10, 4)]), Color("ffe066"))
	var rock := PackedVector2Array()
	for corner in 9:
		rock.append(Vector2.from_angle(TAU * corner / 9.0) * (34.0 + (8.0 if corner % 2 == 0 else -2.0)) + Vector2(0, 14))
	Art.shape(canvas, xf, rock, Color("7a5a48"), ink)
	Art.flat(canvas, xf, Art.circle(7, Vector2(-10, 8), 12), Color("5c4232"))
	Art.flat(canvas, xf, Art.circle(5, Vector2(12, 24), 12), Color("5c4232"))


static func orbital_laser(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	Art.flat(canvas, xf, Art.rect(30, 70, Vector2(0, 18)), Color(0.4, 0.95, 1.0, 0.35))
	Art.shape(canvas, xf, Art.rect(12, 74, Vector2(0, 16)), Color("dffcff"), ink * 0.5, false)
	for side: float in [-1.0, 1.0]:
		Art.shape(canvas, xf, Art.rect(26, 16, Vector2(32 * side, -34)), Color("3b6fd6"), ink)
		Art.line(canvas, xf, PackedVector2Array([Vector2(20 * side, -34), Vector2(44 * side, -34)]), 1.5, Color("9fd0ff"))
	Art.shape(canvas, xf, Art.round_rect(26, 30, 6, Vector2(0, -34)), Color("d6dbe4"), ink)
	Art.shape(canvas, xf, Art.circle(7, Vector2(0, -18), 14), Color("6ff0ff"), ink * 0.7)


static func land_shark(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	shark(canvas, Art.place(xf, Vector2(-4, 4), -0.5, 0.85), ink, 1.0)
	Art.shape(canvas, xf, Art.rect(100, 10, Vector2(0, 44)), Color("8a5a3b"), ink)
	for chip: Vector2 in [Vector2(-30, 30), Vector2(26, 28), Vector2(-14, 22)]:
		Art.shape(canvas, xf, Art.rect(8, 5, chip), Color("a8693a"), ink * 0.5, false)


## A cartoon shark facing +x. `bite` opens the jaw (0 closed, 1 wide).
static func shark(canvas: CanvasItem, xf: Transform2D, ink: float, bite: float) -> void:
	var body := Color("7b8fa6")
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-60, -6), Vector2(-80, -30), Vector2(-74, -2), Vector2(-80, 24), Vector2(-60, 4)]), body.darkened(0.1), ink)
	Art.shape(canvas, xf, PackedVector2Array([Vector2(-14, -20), Vector2(-4, -50), Vector2(12, -20)]), body.darkened(0.1), ink)
	var jaw := 14.0 * bite
	var upper := PackedVector2Array([Vector2(-62, -2), Vector2(-30, -24), Vector2(20, -24), Vector2(54, -10), Vector2(62, -2 - jaw), Vector2(16, 0)])
	var lower := PackedVector2Array([Vector2(-62, -2), Vector2(16, 0), Vector2(56, 6 + jaw), Vector2(40, 18), Vector2(-20, 18)])
	Art.shape(canvas, xf, lower, Color("e8eef4"), ink)
	Art.shape(canvas, xf, upper, body, ink)
	if bite > 0.1:
		Art.flat(canvas, xf, PackedVector2Array([Vector2(16, 0), Vector2(60, -2 - jaw * 0.8), Vector2(54, 4 + jaw * 0.8)]), Color("6b1f2a"))
		for tooth in 4:
			var x := 24.0 + tooth * 8.0
			Art.flat(canvas, xf, PackedVector2Array([Vector2(x, -1 - jaw * 0.3), Vector2(x + 6, -1 - jaw * 0.3), Vector2(x + 3, 6)]), Color.WHITE)
	Art.flat(canvas, xf, Art.circle(4, Vector2(30, -12), 10), INK)
	for gill in 3:
		Art.line(canvas, xf, PackedVector2Array([Vector2(-4 + gill * 6, -14), Vector2(-8 + gill * 6, -2)]), 2.0, body.darkened(0.35))


static func piano(canvas: CanvasItem, xf: Transform2D, ink: float) -> void:
	var black := Color("2b2838")
	Art.shape(canvas, xf, Art.rect(8, 20, Vector2(-40, 30)), black, ink)
	Art.shape(canvas, xf, Art.rect(8, 20, Vector2(40, 30)), black, ink)
	Art.shape(canvas, xf, Art.round_rect(96, 56, 6, Vector2(0, -8)), black, ink)
	Art.flat(canvas, xf, Art.rect(84, 6, Vector2(0, -30)), black.lightened(0.25))
	Art.shape(canvas, xf, Art.rect(92, 14, Vector2(0, 22)), Color("fbf8ef"), ink * 0.6, false)
	for key in 9:
		Art.line(canvas, xf, PackedVector2Array([Vector2(-41 + key * 10, 15), Vector2(-41 + key * 10, 29)]), 1.2, Color("9aa3b5"))
		if key % 7 != 2 and key % 7 != 6:
			Art.flat(canvas, xf, Art.rect(5, 8, Vector2(-36 + key * 10, 19)), black)
	Art.flat(canvas, xf, Art.rect(20, 14, Vector2(0, -10)), Color("e6b33e"))


## A trophy cup: gold when won, grey while still a goal.
static func trophy(canvas: CanvasItem, xf: Transform2D, ink: float, won: bool) -> void:
	var metal := GOLD if won else Color("6c6480")
	for side: float in [-1.0, 1.0]:
		var handle := Art.circle(14, Vector2(26 * side, -18), 20)
		var hole := Art.circle(8, Vector2(26 * side, -18), 20)
		for loop in Geometry2D.clip_polygons(handle, hole):
			Art.shape(canvas, xf, loop, metal, ink * 0.8, false)
	Art.shape(canvas, xf, Art.rect(12, 18, Vector2(0, 18)), metal.darkened(0.15), ink)
	Art.shape(canvas, xf, Art.round_rect(44, 12, 3, Vector2(0, 32)), metal.darkened(0.25), ink)
	var cup := PackedVector2Array([Vector2(-30, -38), Vector2(30, -38), Vector2(26, -12), Vector2(12, 8), Vector2(-12, 8), Vector2(-26, -12)])
	Art.shape(canvas, xf, cup, metal, ink)
	if won:
		Art.flat(canvas, xf, Art.star(5, 9, 4, Vector2(0, -18)), Color("fff6c8"))


static func padlock(canvas: CanvasItem, xf: Transform2D, ink: float, color: Color) -> void:
	var shackle := Art.capsule(16, 44, Vector2(0, -14))
	var hole := Art.capsule(9, 30, Vector2(0, -14))
	for loop in Geometry2D.clip_polygons(shackle, hole):
		Art.shape(canvas, xf, loop, color.lightened(0.2), ink * 0.8, false)
	Art.shape(canvas, xf, Art.round_rect(48, 36, 7, Vector2(0, 14)), color, ink)
	Art.flat(canvas, xf, Art.circle(5, Vector2(0, 10), 12), INK)
	Art.flat(canvas, xf, Art.rect(4, 10, Vector2(0, 17)), INK)


static func _rotated(points: PackedVector2Array, angle: float, offset: Vector2) -> PackedVector2Array:
	return Transform2D(angle, offset) * points


static func _arc(radius: float, from: float, to: float, count := 16) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in count + 1:
		points.append(Vector2.from_angle(lerpf(from, to, float(step) / count)) * radius)
	return points
