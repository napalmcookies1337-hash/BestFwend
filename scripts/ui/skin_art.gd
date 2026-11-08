class_name SkinArt
extends RefCounted
## Draws Buddy skins: patterns on the skin, things behind the head (ears, horns,
## antennae), hats on top and things over the face. Everything is in the part's
## own space (head radius 60, torso radius 58), so it moves and squashes with it.

const INK := Art.INK
const INK_WIDTH := 4.0


## Zombie Mode's look. Not sold in the shop.
const ZOMBIE := {"name": "Zombie", "price": 0, "pattern": "rot", "face": "stitches"}
const ZOMBIE_COLOR := Color("8fb36a")


static func skin_of(skin_id: String) -> Dictionary:
	if skin_id == "zombie":
		return ZOMBIE
	return Cosmetics.SKINS.get(skin_id, Cosmetics.SKINS["classic"])


## Pattern on a round part: `radius` is the part's radius.
static func pattern(canvas: CanvasItem, xf: Transform2D, skin_id: String, radius: float, skin: Color, seed_value: int) -> void:
	var kind: String = skin_of(skin_id).get("pattern", "")
	if kind.is_empty():
		return
	var body := Art.circle(radius - 1.0, Vector2.ZERO, 40)
	var mark := skin.darkened(0.28) if skin.get_luminance() > 0.35 else skin.lightened(0.3)
	match kind:
		"spots":
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			for _index in 6:
				var spot := Art.circle(radius * rng.randf_range(0.12, 0.22), Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.2, 0.85), 16)
				for piece in Geometry2D.intersect_polygons(body, spot):
					Art.flat(canvas, xf, piece, mark)
		"rot":
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			for _index in 4:
				var center := Vector2.from_angle(rng.randf() * TAU) * radius * rng.randf_range(0.2, 0.7)
				var blotch := Art.ellipse(radius * rng.randf_range(0.18, 0.3), radius * rng.randf_range(0.12, 0.2), center, 14)
				for piece in Geometry2D.intersect_polygons(body, blotch):
					Art.flat(canvas, xf, piece, Color("5f7d44"))
			# A stitched-up gash.
			var start := Vector2(-radius * 0.55, radius * 0.25)
			var finish := Vector2(radius * 0.35, -radius * 0.05)
			Art.line(canvas, xf, PackedVector2Array([start, finish]), 3.0, Color("3b2a2a"))
			for stitch in 5:
				var at := start.lerp(finish, (stitch + 0.5) / 5.0)
				var across := (finish - start).orthogonal().normalized() * 7.0
				Art.line(canvas, xf, PackedVector2Array([at - across, at + across]), 2.5, Color("3b2a2a"))
		"stripes":
			for index in 4:
				var y := -radius * 0.75 + index * radius * 0.5
				var band := PackedVector2Array([Vector2(-radius, y - 5), Vector2(-radius * 0.2, y - 9),
						Vector2(radius * 0.25, y - 2), Vector2(radius, y - 7), Vector2(radius, y + 3),
						Vector2(radius * 0.25, y + 8), Vector2(-radius * 0.2, y + 2), Vector2(-radius, y + 6)])
				for piece in Geometry2D.intersect_polygons(body, band):
					Art.flat(canvas, xf, piece, mark)


## Behind the head: drawn before the head's fill so the head covers the base.
static func back(canvas: CanvasItem, xf: Transform2D, skin_id: String, skin: Color) -> void:
	match skin_of(skin_id).get("back", ""):
		"cat":
			for side: float in [-1.0, 1.0]:
				var ear := PackedVector2Array([Vector2(24 * side, -46), Vector2(52 * side, -86), Vector2(56 * side, -30)])
				Art.shape(canvas, xf, ear, skin, INK_WIDTH)
				var inner := PackedVector2Array([Vector2(32 * side, -46), Vector2(49 * side, -74), Vector2(50 * side, -40)])
				Art.flat(canvas, xf, inner, Color("ff9ec7"))
		"horns":
			for side: float in [-1.0, 1.0]:
				var horn := PackedVector2Array([Vector2(22 * side, -48), Vector2(30 * side, -70), Vector2(46 * side, -92),
						Vector2(44 * side, -72), Vector2(46 * side, -50)])
				Art.shape(canvas, xf, horn, Color("d8352e"), INK_WIDTH)
		"antennae":
			for side: float in [-1.0, 1.0]:
				Art.stroke(canvas, xf, Vector2(16 * side, -52), Vector2(34 * side, -102), 4.0, skin.darkened(0.2), INK_WIDTH * 0.7)
				Art.flat(canvas, xf, Art.circle(15, Vector2(34 * side, -104), 20), Color(0.6, 1.0, 0.5, 0.35))
				Art.shape(canvas, xf, Art.circle(9, Vector2(34 * side, -104), 20), Color("9cff6a"), INK_WIDTH * 0.8)


## On top of the head: hats.
static func hat(canvas: CanvasItem, xf: Transform2D, skin_id: String) -> void:
	match skin_of(skin_id).get("hat", ""):
		"party":
			var cone := PackedVector2Array([Vector2(-30, -46), Vector2(34, -50), Vector2(10, -132)])
			Art.shape(canvas, xf, cone, Color("6ec6ff"), INK_WIDTH)
			for stripe in 3:
				var y := -60.0 - stripe * 24.0
				var band := Art.rect(80, 9, Vector2(0, y))
				for piece in Geometry2D.intersect_polygons(cone, Art.moved(band, Transform2D(0.08, Vector2.ZERO))):
					Art.flat(canvas, xf, piece, Color("ffd23f"))
			Art.shape(canvas, xf, Art.circle(11, Vector2(10, -134), 16), Color("ff6464"), INK_WIDTH)
		"tophat":
			Art.shape(canvas, xf, Art.round_rect(58, 62, 6, Vector2(4, -88)), Color("2b2838"), INK_WIDTH)
			Art.flat(canvas, xf, Art.rect(58, 11, Vector2(4, -66)), Color("c0392b"))
			Art.shape(canvas, xf, Art.moved(Art.ellipse(48, 9, Vector2.ZERO, 28), Transform2D(-0.06, Vector2(4, -58))), Color("2b2838"), INK_WIDTH)
		"crown":
			var crown := PackedVector2Array([Vector2(-36, -50), Vector2(36, -50), Vector2(40, -96), Vector2(22, -72),
					Vector2(8, -104), Vector2(-6, -74), Vector2(-22, -102), Vector2(-32, -72), Vector2(-42, -94)])
			Art.shape(canvas, xf, crown, Color("f2c14e"), INK_WIDTH)
			for jewel: Array in [[Vector2(-16, -60), Color("ff4d6d")], [Vector2(4, -62), Color("58c4ff")], [Vector2(22, -60), Color("7be08f")]]:
				Art.shape(canvas, xf, Art.circle(5, jewel[0], 12), jewel[1], 2.0)


## Over the face, after the eyes and mouth.
static func face(canvas: CanvasItem, xf: Transform2D, skin_id: String) -> void:
	match skin_of(skin_id).get("face", ""):
		"stitches":
			# Stitches across the forehead.
			Art.line(canvas, xf, PackedVector2Array([Vector2(-30, -40), Vector2(-4, -46), Vector2(20, -38)]), 3.0, Color("3b2a2a"))
			for stitch: Vector2 in [Vector2(-24, -42), Vector2(-12, -45), Vector2(0, -45), Vector2(12, -41)]:
				Art.line(canvas, xf, PackedVector2Array([stitch + Vector2(-2, -6), stitch + Vector2(2, 6)]), 2.5, Color("3b2a2a"))
		"shades":
			for side: float in [-1.0, 1.0]:
				Art.shape(canvas, xf, Art.round_rect(32, 22, 8, Vector2(21 * side, -6)), Color("1f1b2b"), INK_WIDTH * 0.7, false)
				Art.flat(canvas, xf, PackedVector2Array([Vector2(21 * side - 10, -12), Vector2(21 * side - 2, -12), Vector2(21 * side - 8, -4)]), Color(1, 1, 1, 0.55))
			Art.stroke(canvas, xf, Vector2(-6, -8), Vector2(6, -8), 3.0, Color("1f1b2b"), 0.0)
			Art.stroke(canvas, xf, Vector2(-37, -10), Vector2(-56, -14), 3.0, Color("1f1b2b"), 0.0)
			Art.stroke(canvas, xf, Vector2(37, -10), Vector2(56, -14), 3.0, Color("1f1b2b"), 0.0)
		"monocle":
			var ring := Art.circle(19, Vector2(21, -6), 28)
			var glass := Art.circle(15, Vector2(21, -6), 28)
			Art.flat(canvas, xf, glass, Color(0.85, 0.95, 1.0, 0.25))
			for loop in Geometry2D.clip_polygons(ring, glass):
				Art.shape(canvas, xf, loop, Color("e6b33e"), 2.0, false)
			Art.line(canvas, xf, PackedVector2Array([Vector2(36, 2), Vector2(44, 24), Vector2(40, 44)]), 2.0, Color("e6b33e"))


## A standing Buddy in a fixed pose, for shop previews. `xf` places a Buddy
## whose torso centre is the origin (about 250 units tall).
static func preview(canvas: CanvasItem, xf: Transform2D, skin: Color, skin_id: String) -> void:
	var ink := INK_WIDTH * xf.get_scale().x * 1.2
	var shade := skin.darkened(0.18)
	for side: float in [-1.0, 1.0]:
		Art.shape(canvas, xf, Art.capsule(18, 58, Vector2(26 * side, 62)), shade, ink, false)
		Art.shape(canvas, xf, Art.ellipse(26, 17, Vector2(26 * side, 86)), shade.darkened(0.15), ink, false)
	var head_xf := Art.place(xf, Vector2(0, -92))
	back(canvas, head_xf, skin_id, skin)
	for outline: PackedVector2Array in [Art.circle(64, Vector2.ZERO, 40), Art.circle(66, Vector2(0, -92), 40)]:
		Art.flat(canvas, xf, outline, INK)
	Art.flat(canvas, xf, Art.circle(58, Vector2.ZERO, 40), skin)
	Art.flat(canvas, xf, Art.ellipse(38, 34, Vector2(0, 16), 32), skin.lightened(0.35))
	pattern(canvas, xf, skin_id, 58.0, skin, 11)
	Art.flat(canvas, head_xf, Art.circle(60, Vector2.ZERO, 40), skin)
	pattern(canvas, head_xf, skin_id, 60.0, skin, 7)
	Art.flat(canvas, head_xf, Art.ellipse(16, 11, Vector2(-22, -30), 20), Color(1, 1, 1, 0.28))
	for side: float in [-1.0, 1.0]:
		Art.flat(canvas, head_xf, Art.circle(9, Vector2(21 * side, 16), 16), Color(1.0, 0.45, 0.5, 0.45))
		Art.flat(canvas, head_xf, Art.ellipse(18, 22, Vector2(21 * side, -6), 24), INK)
		Art.flat(canvas, head_xf, Art.ellipse(15, 19, Vector2(21 * side, -6), 24), Color("fffaf2"))
		Art.flat(canvas, head_xf, Art.circle(8, Vector2(21 * side + 2, -4), 16), INK)
		Art.flat(canvas, head_xf, Art.circle(2.4, Vector2(21 * side - 0.5, -7), 8), Color("fffaf2"))
	var smile := PackedVector2Array()
	for step in 9:
		smile.append(Vector2(0, 18) + Vector2.from_angle(0.25 * PI + 0.5 * PI * step / 8.0) * 13.0)
	Art.line(canvas, head_xf, smile, 5.0, Color("4a1622"))
	face(canvas, head_xf, skin_id)
	hat(canvas, head_xf, skin_id)
	for side: float in [-1.0, 1.0]:
		Art.shape(canvas, xf, Art.capsule(15, 62, Vector2(58 * side, 10)), skin, ink, false)
