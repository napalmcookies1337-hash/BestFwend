extends Minigame
## Impact Frenzy: 30 seconds, every owned tool allowed, score is total damage.
## The Buddy can't be knocked out, so the fun never stops.

const DURATION := 30.0
const PAY_PER_DAMAGE := 0.6


func begin() -> void:
	time_left = DURATION
	hint = "Hurt it! Any tool goes."
	Events.buddy_hit.connect(_on_hit)
	Events.buddy_respawned.connect(_protect)
	_protect()


func cleanup() -> void:
	if Events.buddy_hit.is_connected(_on_hit):
		Events.buddy_hit.disconnect(_on_hit)
	if Events.buddy_respawned.is_connected(_protect):
		Events.buddy_respawned.disconnect(_protect)
	if sandbox.buddy != null:
		sandbox.buddy.invulnerable = false


func score_text() -> String:
	return "%s damage" % Fmt.grouped(roundi(score))


func reward_for(final_score: float) -> int:
	return roundi(final_score * PAY_PER_DAMAGE)


func _protect() -> void:
	if sandbox.buddy != null:
		sandbox.buddy.invulnerable = true


func _on_hit(info: Dictionary) -> void:
	score += float(info.get("damage", 0.0))
