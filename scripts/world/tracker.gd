class_name Tracker
extends Node
## Turns what happens in the room into stats for achievements and daily
## challenges (Game.record). Keeps the counting out of the physics and tools.

const THROW_SPEED := 1500.0

var _seconds := 0.0


func _ready() -> void:
	name = "Tracker"
	Events.listen(self, Events.buddy_released, func(_part: StringName, velocity: Vector2) -> void:
		if velocity.length() >= THROW_SPEED:
			Game.record("throws"))
	Events.buddy_hit.connect(_on_hit)
	Events.listen(self, Events.buddy_knocked_out, func() -> void: Game.record("knockouts"))
	Events.listen(self, Events.buddy_shattered, func() -> void: Game.record("shatters"))
	Events.listen(self, Events.buddy_limb_lost, func(_limb: StringName) -> void: Game.record("limbs"))
	Events.listen(self, Events.exploded, func(_at: Vector2, _radius: float) -> void: Game.record("explosions"))
	Events.listen(self, Events.buddy_interacted, func(kind: StringName, _part: StringName) -> void:
		if kind == &"tickle":
			Game.record("tickles"))
	Events.listen(self, Events.combo_changed, func(multiplier: float) -> void: Game.record("max_combo", multiplier))
	Events.listen(self, Events.buddy_flight, func(seconds: float) -> void: Game.record("longest_flight", seconds))
	Events.listen(self, Events.tool_used, func(tool_id: StringName, _at: Vector2) -> void: Game.note_tool_used(String(tool_id)))
	Events.listen(self, Events.tool_purchased, func(_id: StringName) -> void: Game.check_achievements())
	Events.listen(self, Events.looks_changed, func(_kind: StringName) -> void: Game.check_achievements())


func _process(delta: float) -> void:
	_seconds += delta
	if _seconds >= 1.0:
		_seconds -= 1.0
		Game.record("seconds_played", 1.0)


func _on_hit(info: Dictionary) -> void:
	var damage: float = info.get("damage", 0.0)
	if damage > 0.0:
		Game.record("hits")
		Game.record("damage", damage)
	Game.record("biggest_hit", info.get("force", 0.0))
