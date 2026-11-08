class_name Minigames
extends Node
## Starts, runs and scores minigames. Each one starts from a clean room, normal
## gravity and a fresh Buddy, and pays $$$ for its score. Best scores are saved.

## id: [script, title, how to play]
const LIST := {
	&"zombies": [preload("res://scripts/minigames/zombie_mode.gd"), "Zombie Mode",
		"2 minutes. Your fwend's gone zombie, and it brought friends. Five shamble after your cursor at a time; kill them all and five more come. Any tools go."],
	&"toss": [preload("res://scripts/minigames/target_toss.gd"), "Target Toss",
		"45 seconds. Throw your fwend into the bullseyes. Every hit moves the target."],
	&"frenzy": [preload("res://scripts/minigames/frenzy.gd"), "Impact Frenzy",
		"30 seconds. Deal as much damage as you can with any tools you own. It can't be knocked out."],
}

var sandbox: Sandbox
var current: Minigame


func is_running() -> bool:
	return current != null


## True while a minigame has taken your Buddy out of the room.
func replaces_buddy() -> bool:
	return current != null and current.replaces_buddy


func start(minigame_id: StringName) -> Minigame:
	stop()
	sandbox.hud.close_menus()
	sandbox.set_slowmo(false)
	sandbox.set_gravity(Vector2(0, Sandbox.BASE_GRAVITY))
	sandbox.clean_up(true)
	sandbox.respawn()
	var spec: Array = LIST[minigame_id]
	current = spec[0].new()
	current.sandbox = sandbox
	current.minigame_id = minigame_id
	current.title = spec[1]
	current.name = String(minigame_id).capitalize()
	add_child(current)
	current.begin()
	Events.minigame_started.emit(minigame_id)
	Sfx.play(&"whistle_start", -2.0)
	return current


## Ends the game in progress without scoring it.
func stop() -> void:
	if current == null:
		return
	var brings_back := current.replaces_buddy
	current.cleanup()
	current.queue_free()
	current = null
	if brings_back:
		sandbox.clean_up(true)
		sandbox.respawn()


## Called by a minigame when it's over.
func finish(game: Minigame) -> void:
	var minigame_id := game.minigame_id
	var final_score := game.score
	var best := float(Game.profile.best_scores.get(String(minigame_id), 0.0))
	var new_best := final_score > best
	if new_best:
		Game.profile.best_scores[String(minigame_id)] = final_score
		Game.mark_dirty()
	Game.record("best_" + String(minigame_id), final_score)
	var reward := game.reward_for(final_score)
	Game.earn(reward, &"minigame")
	var result := {
		"id": minigame_id, "title": game.title, "score": final_score, "score_text": game.score_text(),
		"best": maxf(best, final_score), "new_best": new_best and final_score > 0.0, "reward": reward,
	}
	stop()
	Game.save_now()
	Sfx.play(&"cha_ching" if new_best else &"pop", -2.0)
	Events.minigame_finished.emit(result)


static func best_text(minigame_id: StringName, value: float) -> String:
	match minigame_id:
		&"zombies":
			return "%d kills" % roundi(value)
		&"toss":
			return "%d targets" % roundi(value)
		_:
			return "%s damage" % Fmt.grouped(roundi(value))
