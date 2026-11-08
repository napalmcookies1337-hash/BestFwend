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
