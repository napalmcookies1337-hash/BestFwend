extends ToolBehavior
## Tickle Feather: hold the button and wiggle over the Buddy. It squirms and giggles.

const MIN_SPEED := 120.0
const WIGGLE_EVERY := 0.1
const GIGGLE_EVERY := 0.6

var _last := Vector2.ZERO
var _wiggle := 0.0
var _giggle := 0.0
var _phase := 0.0


func press(at: Vector2) -> void:
	_last = at
	_wiggle = 0.0
	_giggle = 0.0


func hold(at: Vector2, delta: float) -> void:
	_phase += delta
	var speed := at.distance_to(_last) / maxf(delta, 0.0001)
	_last = at
	var part := part_at(at)
	if part == null or speed < MIN_SPEED or owner_of(part).is_knocked_out:
		return
	_wiggle += delta
	_giggle += delta
	if _wiggle >= WIGGLE_EVERY:
		_wiggle = 0.0
		for limb in owner_of(part).part_list:
			if limb != owner_of(part).torso:
				limb.angular_velocity += randf_range(-7.0, 7.0) * power()
		owner_of(part).torso.linear_velocity += Vector2(randf_range(-120, 120), randf_range(-160, 0))
	if _giggle >= GIGGLE_EVERY:
		_giggle = 0.0
		owner_of(part).notice(&"tickle", part.part_name)


func draw_cursor(canvas: CanvasItem, at: Vector2) -> void:
	var sway := sin(_phase * 18.0) * 0.4 if sandbox.tools.active == self else 0.0
	canvas.draw_set_transform(at, -0.6 + sway, Vector2.ONE)
	ToolArt.draw_icon(canvas, "tickle", Vector2(0, -30), 64.0, Color.WHITE)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
