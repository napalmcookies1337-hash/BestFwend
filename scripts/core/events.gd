extends Node
## Global signal bus. Holds no state. Signals are facts in the past tense, so
## achievements, rewards and UI can listen without the emitter knowing about them.
## Many are declared ahead of the milestone that first emits them.

@warning_ignore_start("unused_signal")

# Buddy (emitted from Milestone 2 on).
signal buddy_grabbed(part: StringName)
signal buddy_released(part: StringName, velocity: Vector2)
## info keys: "part", "force", "source" (tool id or &"wall"), "damage", "position".
signal buddy_hit(info: Dictionary)
signal buddy_limb_lost(limb: StringName)
signal buddy_knocked_out
## Knocked out while frozen: it broke into ice chunks.
signal buddy_shattered
signal buddy_revived
signal buddy_respawned
signal buddy_health_changed(health: float, max_health: float, knocked_out: bool)
## A gentle action: &"poke", &"slap", &"tickle". (Kind actions pay a little in Milestone 5.)
signal buddy_interacted(kind: StringName, part: StringName)
## The Buddy said something. context is the reaction that picked the line.
signal buddy_spoke(text: String, context: StringName)

# Tools.
signal tool_selected(tool_id: StringName)
signal tool_used(tool_id: StringName, at: Vector2)

# Economy.
signal money_earned(amount: int, reason: StringName)
signal money_spent(amount: int, reason: StringName)
signal money_changed(total: int)
## The variety combo multiplier changed (1.0 means no combo).
signal combo_changed(multiplier: float)
signal tool_purchased(tool_id: StringName)
## A colour, skin or room was put on: kind is &"color", &"skin" or &"room".
signal looks_changed(kind: StringName)
signal item_unlocked(kind: StringName, item_id: StringName)

# Goals.
signal achievement_unlocked(achievement_id: StringName)
## Today's challenges were made (a new day, or a reset).
signal daily_refreshed
signal daily_completed(index: int)
signal prestiged(count: int)
## The Buddy landed after `seconds` in the air.
signal buddy_flight(seconds: float)
## Something blew up.
signal exploded(at: Vector2, radius: float)
# Minigames.
signal minigame_started(minigame_id: StringName)
## info keys: "title", "time_left", "score_text", "hint".
signal minigame_updated(info: Dictionary)
## result keys: "id", "title", "score", "score_text", "best", "new_best", "reward".
signal minigame_finished(result: Dictionary)

# Room.
signal room_cleaned
signal slowmo_changed(enabled: bool)
signal gravity_changed(gravity: Vector2)

# Session.
signal settings_changed
signal progress_reset
signal game_saved
signal notification_posted(text: String)

@warning_ignore_restore("unused_signal")


## Connects `callable` to `event` for as long as `owner` is in the tree. Use this
## for inline functions: unlike methods, Godot doesn't drop a lambda's connection
## when the node that made it is freed, so it would keep running forever.
func listen(owner: Node, event: Signal, callable: Callable) -> void:
	event.connect(callable)
	owner.tree_exiting.connect(func() -> void:
		if event.is_connected(callable):
			event.disconnect(callable), CONNECT_ONE_SHOT)
