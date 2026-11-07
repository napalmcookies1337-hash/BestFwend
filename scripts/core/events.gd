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
signal buddy_revived
signal buddy_respawned
signal buddy_health_changed(health: float, max_health: float, knocked_out: bool)
## The Buddy said something. context is the reaction that picked the line.
signal buddy_spoke(text: String, context: StringName)

# Tools.
signal tool_selected(tool_id: StringName)
signal tool_used(tool_id: StringName, at: Vector2)

# Economy.
signal money_earned(amount: int, reason: StringName)
signal money_spent(amount: int, reason: StringName)
signal money_changed(total: int)
signal tool_purchased(tool_id: StringName)
signal item_unlocked(kind: StringName, item_id: StringName)

# Goals (Milestone 7).
signal achievement_progressed(achievement_id: StringName, value: float)
signal achievement_unlocked(achievement_id: StringName)

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
