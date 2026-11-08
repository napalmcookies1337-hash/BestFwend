class_name Minigame
extends Node
## Base for a minigame played in the sandbox. The Minigames controller starts it
## with a fresh Buddy and room, and it calls finish() with its score when done.
## Override begin(), tick(), score_text() and reward_for().

const UPDATE_EVERY := 0.1

var sandbox: Sandbox
var minigame_id: StringName
var title := ""
## Seconds left on the clock, or -1 when the game ends some other way.
var time_left := -1.0
var score := 0.0
var hint := ""
## Removes your Buddy for the duration and brings it back after (Zombie Mode).
var replaces_buddy := false
var _update := 0.0
var _done := false


func begin() -> void:
	pass


func tick(_delta: float) -> void:
	pass


func score_text() -> String:
	return Fmt.grouped(roundi(score))


func reward_for(final_score: float) -> int:
	return roundi(final_score)


## Undo anything the game changed (locks, invulnerability). Always called.
func cleanup() -> void:
	pass


func finish() -> void:
	if _done:
		return
	_done = true
	(get_parent() as Minigames).finish(self)


func _physics_process(delta: float) -> void:
	if _done:
		return
	if time_left >= 0.0:
		time_left = maxf(time_left - delta, 0.0)
	tick(delta)
	if time_left == 0.0:
		finish()
		return
	_update += delta
	if _update >= UPDATE_EVERY:
		_update = 0.0
		Events.minigame_updated.emit({"title": title, "time_left": time_left, "score_text": score_text(), "hint": hint})
