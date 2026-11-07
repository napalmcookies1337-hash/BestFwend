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
const CHEEK := Color(1.0, 0.45, 0.5, 0.45)
const SPEED_STRETCH := 1.0 / 26000.0
const MAX_SPEED_STRETCH := 0.18
const SCREAM_SPEED := 1100.0
const BLINK_EVERY := Vector2(2.0, 5.0)
const BLINK_TIME := 0.12

var buddy: Buddy
var expression := &"happy"
var _blink_wait := 3.0
var _blink_left := 0.0
var _circle := _circle_points(1.0, 48)


func _process(delta: float) -> void:
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink_left = BLINK_TIME
		_blink_wait = randf_range(BLINK_EVERY.x, BLINK_EVERY.y)
	_blink_left = maxf(_blink_left - delta, 0.0)
	expression = _pick_expression()
	if is_inside_tree() and get_viewport() != null:
		buddy.look_target = get_global_mouse_position()
	queue_redraw()


func _pick_expression() -> StringName:
	if buddy.hurt_time > 0.0:
		return &"ouch"
	if buddy.state == Buddy.State.GRABBED:
		return &"grabbed"
	if buddy.state == Buddy.State.RAGDOLL and buddy.torso.linear_velocity.length() > SCREAM_SPEED:
		return &"scream"
	if buddy.state == Buddy.State.GETTING_UP:
		return &"groggy"
	return &"happy"


func _draw() -> void:
	var skin := buddy.color
	var shade := skin.darkened(0.18)
	var belly := skin.lightened(0.35)
	var torso := buddy.torso
	var head := buddy.head

	for id: StringName in [&"leg_l", &"leg_r"]:
		var leg: BuddyPart = buddy.parts[id]
		var xf := _part_transform(leg)
		_capsule(xf, leg, OUTLINE_COLOR, OUTLINE)
		_capsule(xf, leg, shade, 0.0)
		var foot := Vector2(0, leg.length / 2 - leg.radius * 0.35)
		_ellipse(xf, foot, Vector2(leg.radius * 1.45, leg.radius * 0.95) + Vector2.ONE * OUTLINE, OUTLINE_COLOR)
		_ellipse(xf, foot, Vector2(leg.radius * 1.45, leg.radius * 0.95), shade.darkened(0.15))

	var torso_xf := _part_transform(torso)
	var head_xf := _part_transform(head)
	_ellipse(torso_xf, Vector2.ZERO, Vector2.ONE * (torso.radius + OUTLINE), OUTLINE_COLOR)
	_ellipse(head_xf, Vector2.ZERO, Vector2.ONE * (head.radius + OUTLINE), OUTLINE_COLOR)
	_ellipse(torso_xf, Vector2.ZERO, Vector2.ONE * torso.radius, skin)
	_ellipse(torso_xf, Vector2(0, 16), Vector2(38, 34), belly)
	_ellipse(head_xf, Vector2.ZERO, Vector2.ONE * head.radius, skin)
	_ellipse(head_xf, Vector2(-22, -30), Vector2(16, 11), Color(1, 1, 1, 0.28))
	_draw_face(head_xf, head)

	for id: StringName in [&"arm_l", &"arm_r"]:
		var arm: BuddyPart = buddy.parts[id]
		var xf := _part_transform(arm)
		_capsule(xf, arm, OUTLINE_COLOR, OUTLINE)
		_capsule(xf, arm, skin, 0.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_face(xf: Transform2D, head: BuddyPart) -> void:
	draw_set_transform_matrix(xf)
	var look := xf.affine_inverse() * buddy.look_target
	var gaze := look.normalized() * minf(look.length() / 40.0, 6.0)
	var blinking := _blink_left > 0.0 and expression != &"scream" and expression != &"ouch"
	for side: float in [-1.0, 1.0]:
		draw_set_transform_matrix(xf)
		var eye := Vector2(21.0 * side, -6.0)
		draw_circle(eye + Vector2(0, 22), 9.0, CHEEK)
		match expression:
			&"ouch":
				var a := eye + Vector2(-8 * side, -8)
				var b := eye + Vector2(8 * side, 0)
				var c := eye + Vector2(-8 * side, 8)
				draw_polyline(PackedVector2Array([a, b, c]), PUPIL, 5.0, true)
			_:
				var radii := Vector2(15, 19)
				var pupil := 8.0
				if expression == &"scream":
					radii = Vector2(17, 22)
					pupil = 4.0
				elif expression == &"grabbed":
					pupil = 5.5
				if blinking:
					draw_line(eye + Vector2(-radii.x, 0), eye + Vector2(radii.x, 0), PUPIL, 4.0, true)
					continue
				_ellipse(xf, eye, radii + Vector2.ONE * 3.0, OUTLINE_COLOR)
				_ellipse(xf, eye, radii, EYE_WHITE)
				draw_set_transform_matrix(xf)
				draw_circle(eye + gaze, pupil, PUPIL)
				draw_circle(eye + gaze + Vector2(-2.5, -3), pupil * 0.3, EYE_WHITE)
				if expression == &"groggy":
					draw_rect(Rect2(eye + Vector2(-radii.x - 3, -radii.y - 4), Vector2(radii.x * 2 + 6, radii.y + 3)), head_skin())
					draw_line(eye + Vector2(-radii.x, -1), eye + Vector2(radii.x, -1), PUPIL, 3.0, true)
				elif expression == &"grabbed":
					draw_line(eye + Vector2(-12, -30), eye + Vector2(10, -34 + 4 * side), PUPIL, 4.0, true)
	draw_set_transform_matrix(xf)
	var mouth := Vector2(0, 24)
	match expression:
		&"happy":
			draw_arc(mouth + Vector2(0, -6), 13.0, 0.25 * PI, 0.75 * PI, 12, MOUTH, 5.0, true)
		&"grabbed":
			_ellipse(xf, mouth, Vector2(7, 9), MOUTH)
		&"scream":
			_ellipse(xf, mouth + Vector2(0, 4), Vector2(15, 19), MOUTH)
			_ellipse(xf, mouth + Vector2(0, 14), Vector2(9, 6), Color("e05a6a"))
		&"ouch":
			var points := PackedVector2Array()
			for index in 7:
				points.append(mouth + Vector2(-15 + index * 5, (index % 2) * 5))
			draw_polyline(points, MOUTH, 4.0, true)
		&"groggy":
			draw_line(mouth + Vector2(-10, 2), mouth + Vector2(10, -1), MOUTH, 4.0, true)


func head_skin() -> Color:
	return buddy.color


## The part's transform, plus squash along the last impact or stretch along its motion.
func _part_transform(part: BuddyPart) -> Transform2D:
	var base := part.global_transform
	if part != buddy.torso:
		base = base.translated(buddy.joint_gap(part))
	var amount := part.squash
	var axis := part.squash_axis
	if absf(amount) < 0.03:
		var speed := part.linear_velocity.length()
		amount = -minf(speed * SPEED_STRETCH, MAX_SPEED_STRETCH)
		axis = part.linear_velocity.angle()
	if absf(amount) < 0.005:
		return base
	var pivot := Transform2D(axis, part.global_position)
	var squeeze := Transform2D.IDENTITY.scaled(Vector2(1.0 - amount, 1.0 + amount * 0.6))
	return pivot * squeeze * pivot.affine_inverse() * base


func _ellipse(xf: Transform2D, center: Vector2, radii: Vector2, fill: Color) -> void:
	draw_set_transform_matrix(xf * Transform2D(0.0, radii, 0.0, center))
	draw_colored_polygon(_circle, fill)


func _capsule(xf: Transform2D, part: BuddyPart, fill: Color, grow: float) -> void:
	draw_set_transform_matrix(xf)
	draw_colored_polygon(_capsule_points(part.radius + grow, part.length + grow * 2.0), fill)


static func _circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count:
		points.append(Vector2.from_angle(TAU * index / count) * radius)
	return points


static func _capsule_points(radius: float, height: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var half := maxf(height / 2.0 - radius, 0.0)
	var steps := 14
	for index in steps + 1:
		points.append(Vector2(0, -half) + Vector2.from_angle(PI + PI * index / steps) * radius)
	for index in steps + 1:
		points.append(Vector2(0, half) + Vector2.from_angle(PI * index / steps) * radius)
	return points
