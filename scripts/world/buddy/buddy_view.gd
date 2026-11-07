class_name BuddyView
extends Node2D
## Draws the Buddy from its parts' transforms. Outlines for the head and torso go
## down before either fill, so the two circles read as one blob. Squash and
## stretch are applied here only; physics shapes never deform.

const OUTLINE := 6.0
const OUTLINE_COLOR := Color("1e1426")
const EYE_WHITE := Color("fffaf2")
const PUPIL := Color("1e1426")
const MOUTH := Color("4a1622")
const TONGUE := Color("e05a6a")
const CHEEK := Color(1.0, 0.45, 0.5, 0.45)
const BRUISE := Color(0.42, 0.2, 0.5, 0.45)
const BLOOD := Color("9b0f1e")
const SOOT := Color(0.12, 0.09, 0.08, 0.55)
const STAR := Color("ffe066")
const ICE := Color("bfe9ff")
const ICE_EDGE := Color("5aa9d6")
const FLAME := [Color("ffd23f"), Color("ff8a1f"), Color("e8401c")]
const SHOCK_FLASH := Color("fff6a8")
const SPEED_STRETCH := 1.0 / 26000.0
const MAX_SPEED_STRETCH := 0.18
const SCREAM_SPEED := 1100.0
const LOW_HEALTH := Buddy.LOW_HEALTH
const BLINK_EVERY := Vector2(2.0, 5.0)
const BLINK_TIME := 0.12

var buddy: Buddy
var expression := &"happy"
var _blink_wait := 3.0
var _blink_left := 0.0
var _time := 0.0
var _circle := _circle_points(1.0, 48)


static func mark_color(mark: int) -> Color:
	match mark:
		BuddyPart.Mark.BLOOD:
			return BLOOD
		BuddyPart.Mark.SOOT:
			return SOOT
	return BRUISE


func _process(delta: float) -> void:
	_time += delta
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink_left = BLINK_TIME
		_blink_wait = randf_range(BLINK_EVERY.x, BLINK_EVERY.y)
	_blink_left = maxf(_blink_left - delta, 0.0)
	expression = pick_expression()
	if is_inside_tree() and get_viewport() != null:
		buddy.look_target = get_global_mouse_position()
	queue_redraw()


## Which face to show right now, most important first.
func pick_expression() -> StringName:
	if buddy.is_knocked_out:
		return &"ko"
	if buddy.frozen_time > 0.0:
		return &"frozen"
	if buddy.shock_time > 0.0:
		return &"shocked"
	if buddy.burn_time > 0.0:
		return &"scream"
	if buddy.hurt_time > 0.0:
		return &"ouch"
	if buddy.face_override != &"":
		return buddy.face_override
	if buddy.state == Buddy.State.GRABBED:
		return &"grabbed"
	if buddy.state == Buddy.State.RAGDOLL and buddy.torso.linear_velocity.length() > SCREAM_SPEED:
		return &"scream"
	if buddy.state == Buddy.State.GETTING_UP or buddy.health < LOW_HEALTH:
		return &"groggy"
	return &"happy"


func _draw() -> void:
	var skin := buddy.color
	var outline := OUTLINE_COLOR
	if buddy.frozen_time > 0.0:
		skin = skin.lerp(ICE, 0.6)
		outline = ICE_EDGE.darkened(0.4)
	if buddy.shock_time > 0.0 and fmod(_time, 0.12) < 0.06:
		skin = SHOCK_FLASH
	var shade := skin.darkened(0.18)
	var belly := skin.lightened(0.35)
	var torso := buddy.torso
	var head := buddy.head

	for id: StringName in [&"leg_l", &"leg_r"]:
		var leg: BuddyPart = buddy.parts.get(id)
		if leg == null:
			continue
		var xf := _part_transform(leg)
		_capsule(xf, leg, outline, OUTLINE)
		_capsule(xf, leg, shade, 0.0)
		var foot := Vector2(0, leg.length / 2 - leg.radius * 0.35)
		_ellipse(xf, foot, Vector2(leg.radius * 1.45, leg.radius * 0.95) + Vector2.ONE * OUTLINE, outline)
		_ellipse(xf, foot, Vector2(leg.radius * 1.45, leg.radius * 0.95), shade.darkened(0.15))
		_draw_marks(xf, leg)

	var torso_xf := _part_transform(torso)
	var head_xf := _part_transform(head)
	_ellipse(torso_xf, Vector2.ZERO, Vector2.ONE * (torso.radius + OUTLINE), outline)
	_ellipse(head_xf, Vector2.ZERO, Vector2.ONE * (head.radius + OUTLINE), outline)
	_ellipse(torso_xf, Vector2.ZERO, Vector2.ONE * torso.radius, skin)
	_ellipse(torso_xf, Vector2(0, 16), Vector2(38, 34), belly)
	_draw_marks(torso_xf, torso)
	for stump in buddy.stumps:
		_ellipse(torso_xf, stump * 0.92, Vector2(15, 13), BLOOD)
		_ellipse(torso_xf, stump * 0.92, Vector2(6, 5), Color("f3d9c4"))
	_ellipse(head_xf, Vector2.ZERO, Vector2.ONE * head.radius, skin)
	_ellipse(head_xf, Vector2(-22, -30), Vector2(16, 11), Color(1, 1, 1, 0.28))
	_draw_marks(head_xf, head)
	_draw_face(head_xf)

	for id: StringName in [&"arm_l", &"arm_r"]:
		var arm: BuddyPart = buddy.parts.get(id)
		if arm == null:
			continue
		var xf := _part_transform(arm)
		_capsule(xf, arm, outline, OUTLINE)
		_capsule(xf, arm, skin, 0.0)
		_draw_marks(xf, arm)

	draw_set_transform_matrix(Transform2D.IDENTITY)
	if buddy.frozen_time > 0.0:
		_draw_ice()
	if buddy.burn_time > 0.0:
		_draw_flames()
	if expression == &"ko" or expression == &"dizzy":
		_draw_stars(head.global_position - Vector2(0, head.radius + 18), expression == &"ko")


func _draw_marks(xf: Transform2D, part: BuddyPart) -> void:
	for mark: Array in part.marks:
		var at: Vector2 = mark[0]
		var size: float = mark[1]
		var color := mark_color(mark[2])
		if mark[2] == BuddyPart.Mark.BLOOD:
			_ellipse(xf, at, Vector2(size, size * 0.8), color)
			_ellipse(xf, at + Vector2(size * 0.7, size * 0.4), Vector2.ONE * size * 0.35, color)
			_ellipse(xf, at + Vector2(0, size * 0.9), Vector2(size * 0.25, size * 0.5), color.darkened(0.1))
		else:
			_ellipse(xf, at, Vector2(size, size * 0.85), color)


func _draw_ice() -> void:
	for part in buddy.part_list:
		var at := part.global_position
		var glint := Vector2(-part.radius * 0.4, -part.radius * 0.5)
		draw_line(at + glint, at + glint + Vector2(10, -10), Color(1, 1, 1, 0.8), 4.0, true)
		draw_line(at + glint + Vector2(14, 2), at + glint + Vector2(19, -3), Color(1, 1, 1, 0.6), 3.0, true)


func _draw_flames() -> void:
	var up := -buddy.gravity().normalized() if buddy.gravity().length() > 1.0 else Vector2.UP
	for part in buddy.part_list:
		for index in 3:
			var flicker := sin(_time * 18.0 + part.radius + index * 2.1)
			var base := part.global_position + up.orthogonal() * (index - 1) * part.radius * 0.55
			var height := part.radius * (1.1 + 0.35 * flicker)
			var width := part.radius * 0.45
			var color: Color = FLAME[(index + int(_time * 10.0)) % FLAME.size()]
			# See-through enough that the face still reads under the fire.
			color.a = 0.6 if part == buddy.head else 0.8
			var tip := base + up * height
			var points := PackedVector2Array([base + up.orthogonal() * width, tip, base - up.orthogonal() * width, base - up * width * 0.6])
			draw_colored_polygon(points, color)


func _draw_stars(center: Vector2, knocked_out: bool) -> void:
	var count := 4 if knocked_out else 3
	for index in count:
		var angle := _time * 3.0 + TAU * index / count
		var at := center + Vector2(cos(angle) * 58.0, sin(angle) * 14.0)
		_star(at, 11.0, STAR)


func _star(at: Vector2, radius: float, fill: Color) -> void:
	var points := PackedVector2Array()
	for index in 10:
		var r := radius if index % 2 == 0 else radius * 0.45
		points.append(at + Vector2.from_angle(-PI / 2 + TAU * index / 10) * r)
	draw_colored_polygon(points, OUTLINE_COLOR)
	var inner := PackedVector2Array()
	for point in points:
		inner.append(at + (point - at) * 0.72)
	draw_colored_polygon(inner, fill)


func _draw_face(xf: Transform2D) -> void:
	draw_set_transform_matrix(xf)
	var look := xf.affine_inverse() * buddy.look_target
	var gaze := look.normalized() * minf(look.length() / 40.0, 6.0)
	if expression == &"frozen" or expression == &"shocked":
		gaze = Vector2.ZERO
	var closed_eyes := [&"ouch", &"ko", &"dizzy", &"yawn", &"laugh"].has(expression)
	var blinking := _blink_left > 0.0 and not closed_eyes and not [&"scream", &"frozen", &"shocked"].has(expression)
	for side: float in [-1.0, 1.0]:
		draw_set_transform_matrix(xf)
		var eye := Vector2(21.0 * side, -6.0)
		draw_circle(eye + Vector2(0, 22), 9.0, CHEEK)
		match expression:
			&"ouch":
				draw_polyline(PackedVector2Array([eye + Vector2(-8 * side, -8), eye + Vector2(8 * side, 0), eye + Vector2(-8 * side, 8)]), PUPIL, 5.0, true)
			&"ko":
				draw_line(eye + Vector2(-9, -9), eye + Vector2(9, 9), PUPIL, 5.0, true)
				draw_line(eye + Vector2(-9, 9), eye + Vector2(9, -9), PUPIL, 5.0, true)
			&"dizzy":
				var spiral := PackedVector2Array()
				for step in 24:
					var a := float(step) / 23.0 * TAU * 2.0 + _time * 6.0 * side
					spiral.append(eye + Vector2.from_angle(a) * (2.0 + 11.0 * step / 23.0))
				draw_polyline(spiral, PUPIL, 3.0, true)
			&"yawn":
				draw_arc(eye + Vector2(0, -2), 9.0, 0.15 * PI, 0.85 * PI, 10, PUPIL, 4.0, true)
			&"laugh":
				draw_arc(eye + Vector2(0, 4), 10.0, 1.15 * PI, 1.85 * PI, 10, PUPIL, 4.5, true)
			_:
				_draw_open_eye(xf, eye, side, gaze, blinking)
	draw_set_transform_matrix(xf)
	_draw_mouth(xf, Vector2(0, 24))


func _draw_open_eye(xf: Transform2D, eye: Vector2, side: float, gaze: Vector2, blinking: bool) -> void:
	var radii := Vector2(15, 19)
	var pupil := 8.0
	match expression:
		&"scream":
			radii = Vector2(17, 22)
			pupil = 4.0
		&"shocked":
			radii = Vector2(18, 22)
			pupil = 3.0
		&"frozen":
			pupil = 5.0
		&"grabbed":
			pupil = 5.5
		&"angry":
			pupil = 6.5
	if blinking:
		draw_line(eye + Vector2(-radii.x, 0), eye + Vector2(radii.x, 0), PUPIL, 4.0, true)
		return
	_ellipse(xf, eye, radii + Vector2.ONE * 3.0, OUTLINE_COLOR)
	_ellipse(xf, eye, radii, EYE_WHITE)
	draw_set_transform_matrix(xf)
	draw_circle(eye + gaze, pupil, PUPIL)
	draw_circle(eye + gaze + Vector2(-2.5, -3), pupil * 0.3, EYE_WHITE)
	var lid := 0.0
	match expression:
		&"groggy":
			lid = 0.55
		&"bored":
			lid = 0.5
		&"smug":
			lid = 0.4
	if lid > 0.0:
		var cover := Rect2(eye + Vector2(-radii.x - 4, -radii.y - 5), Vector2(radii.x * 2 + 8, radii.y * 2 * lid + 4))
		draw_rect(cover, buddy.color)
		draw_line(Vector2(cover.position.x + 3, cover.end.y), Vector2(cover.end.x - 3, cover.end.y), PUPIL, 3.0, true)
	if expression == &"grabbed":
		draw_line(eye + Vector2(-12, -30), eye + Vector2(10, -34 + 4 * side), PUPIL, 4.0, true)
	elif expression == &"angry":
		# Brows slant down toward the middle.
		draw_line(eye + Vector2(-13 * side, -30), eye + Vector2(11 * side, -20), PUPIL, 5.0, true)


func _draw_mouth(xf: Transform2D, mouth: Vector2) -> void:
	match expression:
		&"happy":
			draw_arc(mouth + Vector2(0, -6), 13.0, 0.25 * PI, 0.75 * PI, 12, MOUTH, 5.0, true)
		&"smug":
			draw_arc(mouth + Vector2(4, -6), 12.0, 0.15 * PI, 0.55 * PI, 10, MOUTH, 5.0, true)
		&"laugh":
			var grin := PackedVector2Array()
			for step in 13:
				grin.append(mouth + Vector2.from_angle(PI * step / 12.0) * Vector2(16, 14))
			draw_colored_polygon(grin, MOUTH)
			_ellipse(xf, mouth + Vector2(0, 9), Vector2(8, 4), TONGUE)
		&"grabbed", &"frozen":
			_ellipse(xf, mouth, Vector2(7, 9), MOUTH)
		&"scream":
			_ellipse(xf, mouth + Vector2(0, 4), Vector2(15, 19), MOUTH)
			_ellipse(xf, mouth + Vector2(0, 14), Vector2(9, 6), TONGUE)
		&"shocked":
			draw_rect(Rect2(mouth + Vector2(-16, -6), Vector2(32, 14)), MOUTH)
			for tooth in 5:
				draw_line(mouth + Vector2(-16 + tooth * 8, -6), mouth + Vector2(-16 + tooth * 8, 8), EYE_WHITE, 2.0)
			draw_line(mouth + Vector2(-16, 1), mouth + Vector2(16, 1), EYE_WHITE, 2.0)
		&"yawn":
			_ellipse(xf, mouth + Vector2(0, 2), Vector2(12, 16), MOUTH)
		&"ouch", &"dizzy":
			var points := PackedVector2Array()
			for index in 7:
				points.append(mouth + Vector2(-15 + index * 5, (index % 2) * 5))
			draw_polyline(points, MOUTH, 4.0, true)
		&"ko":
			draw_line(mouth + Vector2(-12, 0), mouth + Vector2(12, 0), MOUTH, 4.0, true)
			_ellipse(xf, mouth + Vector2(5, 7), Vector2(6, 8), TONGUE)
		&"angry":
			draw_arc(mouth + Vector2(0, 8), 12.0, 1.2 * PI, 1.8 * PI, 10, MOUTH, 5.0, true)
		_:
			draw_line(mouth + Vector2(-10, 2), mouth + Vector2(10, -1), MOUTH, 4.0, true)


## The part's transform, plus squash along the last impact or stretch along its motion.
func _part_transform(part: BuddyPart) -> Transform2D:
	var base := part.global_transform
	if part != buddy.torso:
		base = base.translated(buddy.joint_gap(part))
	if buddy.frozen_time > 0.0:
		return base
	var amount := part.squash
	var axis := part.squash_axis
	if absf(amount) < 0.03:
		var speed := part.linear_velocity.length()
		amount = -minf(speed * SPEED_STRETCH, MAX_SPEED_STRETCH)
		axis = part.linear_velocity.angle()
	if absf(amount) < 0.005:
		return base
	var pivot := Transform2D(axis, base.origin)
	var squeeze := Transform2D.IDENTITY.scaled(Vector2(1.0 - amount, 1.0 + amount * 0.6))
	return pivot * squeeze * pivot.affine_inverse() * base


func _ellipse(xf: Transform2D, center: Vector2, radii: Vector2, fill: Color) -> void:
	if radii == Vector2.ZERO:
		return
	draw_set_transform_matrix(xf * Transform2D(0.0, radii, 0.0, center))
	draw_colored_polygon(_circle, fill)


func _capsule(xf: Transform2D, part: BuddyPart, fill: Color, grow: float) -> void:
	draw_set_transform_matrix(xf)
	draw_colored_polygon(capsule_points(part.radius + grow, part.length + grow * 2.0), fill)


static func _circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		points.append(Vector2.from_angle(TAU * index / count) * radius)
	return points


static func capsule_points(radius: float, height: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var half := maxf(height / 2.0 - radius, 0.0)
	var steps := 14
	for index in steps + 1:
		points.append(Vector2(0, -half) + Vector2.from_angle(PI + PI * index / steps) * radius)
	for index in steps + 1:
		points.append(Vector2(0, half) + Vector2.from_angle(PI * index / steps) * radius)
	return points
