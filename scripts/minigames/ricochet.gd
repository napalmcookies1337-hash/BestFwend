extends Minigame
## Ricochet: one throw with the Hand. Score is how far the Buddy travels, in
## metres (100 px), until it comes to rest. Walls and ceilings are your friends.

const METRE := 100.0
const MIN_THROW := 600.0
const REST_SPEED := 80.0
const REST_TIME := 1.0
const MAX_FLIGHT := 15.0
const THROW_WINDOW := 20.0
const PAY_PER_METRE := 6.0

var thrown := false
var _last := Vector2.ZERO
var _rest := 0.0
var _flight := 0.0


func begin() -> void:
	Game.select_tool("hand")
	sandbox.tools.locked = true
	time_left = THROW_WINDOW
	hint = "Grab your fwend and throw it. One throw!"
	Events.buddy_released.connect(_on_released)


func cleanup() -> void:
	sandbox.tools.locked = false
	sandbox.grabber.locked = false
	if Events.buddy_released.is_connected(_on_released):
		Events.buddy_released.disconnect(_on_released)


func score_text() -> String:
	return "%.1f m" % score


func reward_for(final_score: float) -> int:
	return roundi(final_score * PAY_PER_METRE)


func tick(delta: float) -> void:
	if not thrown or sandbox.buddy == null:
		return
	var torso := sandbox.buddy.torso
	score += torso.global_position.distance_to(_last) / METRE
	_last = torso.global_position
	_flight += delta
	_rest = _rest + delta if torso.linear_velocity.length() < REST_SPEED else 0.0
	if _rest >= REST_TIME or _flight >= MAX_FLIGHT:
		finish()


func _on_released(_part: StringName, velocity: Vector2) -> void:
	if thrown or velocity.length() < MIN_THROW:
		return
	thrown = true
	time_left = -1.0
	hint = "Go go go!"
	sandbox.grabber.locked = true
	_last = sandbox.buddy.torso.global_position
