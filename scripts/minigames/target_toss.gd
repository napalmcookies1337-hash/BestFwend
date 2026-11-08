extends Minigame
## Target Toss: 45 seconds to throw the Buddy into bullseyes. A hit only counts
## while the Buddy is flying free (not held), and the target then jumps elsewhere.

const DURATION := 45.0
const PAY_PER_TARGET := 50
const AREA := Rect2(260, 150, 1400, 560)
const MIN_GAP := 380.0

var target: TargetBoard
var _rng := RandomNumberGenerator.new()


func begin() -> void:
	_rng.randomize()
	Game.select_tool("hand")
	sandbox.tools.locked = true
	time_left = DURATION
	hint = "Throw your fwend into the target!"
	target = TargetBoard.new()
	sandbox.world.add_child(target)
	move_target()


func cleanup() -> void:
	sandbox.tools.locked = false
	if is_instance_valid(target):
		target.queue_free()


func reward_for(final_score: float) -> int:
	return roundi(final_score) * PAY_PER_TARGET


func move_target() -> void:
	var avoid := sandbox.buddy.torso.global_position if sandbox.buddy != null else Room.SIZE / 2
	var spot := Vector2(_rng.randf_range(AREA.position.x, AREA.end.x), _rng.randf_range(AREA.position.y, AREA.end.y))
	for _attempt in 12:
		if spot.distance_to(avoid) >= MIN_GAP and spot.distance_to(target.position) >= MIN_GAP:
			break
		spot = Vector2(_rng.randf_range(AREA.position.x, AREA.end.x), _rng.randf_range(AREA.position.y, AREA.end.y))
	target.place(spot)


func tick(_delta: float) -> void:
	var buddy := sandbox.buddy
	if buddy == null or not is_instance_valid(target) or buddy.state == Buddy.State.GRABBED:
		return
	for part in buddy.part_list:
		if part.global_position.distance_to(target.position) <= TargetBoard.RADIUS + part.radius * 0.6:
			score += 1.0
			sandbox.fx.add(0.5, Fx.ring(target.position, 160.0, Color(1, 0.85, 0.3, 0.9), 12.0))
			sandbox.fx.add(0.5, Fx.sparks(target.position, 16, 220.0, Color("ffd23f"), _rng.randi()))
			Sfx.play(&"cha_ching", -6.0, 1.2)
			move_target()
			return
