class_name BuddyMind
extends Node
## Decides how the Buddy reacts: which line it says, which sound it makes and which
## face it pulls. Reactions come from context (what hit it, how hard, where, being
## held, flying, lying knocked out, being left alone), never from a mood meter.
##
## A line plays only if nothing more important is being said. Each situation has a
## cooldown, and recent lines aren't repeated.

## Higher interrupts lower. Below CHATTY, lines also wait for a short gap.
const PRIORITY := {
	&"spawn": 3, &"respawn": 3, &"grabbed": 3, &"grabbed_head": 3, &"grabbed_limb": 3,
	&"dangling": 2, &"upside_down": 3, &"thrown": 4, &"hit_light": 1, &"hit_medium": 3,
	&"hit_hard": 5, &"hit_head": 5, &"hit_object": 4, &"hit_ceiling": 4, &"survived": 2,
	&"getting_up": 1, &"low_health": 2, &"revived": 5, &"healed": 2, &"idle": 0, &"bored": 0,
	&"dizzy": 3, &"gravity_weird": 2, &"zero_g": 2, &"gravity_normal": 2, &"slowmo": 1,
	&"cleaned": 1, &"poked": 2, &"slapped": 4, &"tickled": 3, &"pinned": 3, &"lost_arm": 6,
	&"lost_leg": 6, &"legless": 1, &"on_fire": 5, &"burned_out": 2, &"frozen": 4, &"thawed": 3,
	&"shocked": 5, &"bomb_near": 3, &"shot": 5, &"batted": 5, &"stabbed": 5, &"hit_anvil": 5,
	&"blown_up": 5, &"sucked_in": 4, &"levitated": 3,
}
## Hits from these sources get their own lines instead of the generic ones.
const SOURCE_CONTEXT := {
	&"pistol": &"shot", &"bat": &"batted", &"katana": &"stabbed", &"anvil": &"hit_anvil",
	&"explosion": &"blown_up",
}
## Things that happen to it (Buddy.affected) and the line, sound and face they get.
const AFFECTED := {
	&"poke": [&"poked", 0.6, &"squeak", &"angry"],
	&"slap": [&"slapped", 1.0, &"yelp", &"angry"],
	&"tickle": [&"tickled", 0.4, &"giggle", &"laugh"],
	&"pinned": [&"pinned", 1.0, &"yelp", &"grabbed"],
	&"ignited": [&"on_fire", 1.0, &"scream", &""],
	&"burned_out": [&"burned_out", 1.0, &"", &"groggy"],
	&"frozen": [&"frozen", 1.0, &"", &""],
	&"thawed": [&"thawed", 1.0, &"", &"groggy"],
	&"shocked": [&"shocked", 1.0, &"scream", &""],
	&"bomb_near": [&"bomb_near", 0.9, &"squeak", &"grabbed"],
	&"black_hole": [&"sucked_in", 1.0, &"scream", &""],
	&"levitated": [&"levitated", 0.8, &"squeak", &"grabbed"],
}
const CHATTY := 3
## Seconds before the same situation can speak again.
const COOLDOWN := {
	&"grabbed": 2.5, &"grabbed_head": 2.5, &"grabbed_limb": 2.5, &"hit_light": 2.0,
	&"thrown": 1.0, &"hit_medium": 1.2, &"hit_hard": 0.8, &"hit_head": 1.0, &"hit_object": 1.0,
	&"dangling": 8.0, &"upside_down": 6.0, &"survived": 5.0, &"low_health": 10.0, &"idle": 0.0,
	&"bored": 0.0, &"dizzy": 6.0, &"poked": 2.0, &"slapped": 1.0, &"tickled": 2.5, &"on_fire": 2.2,
	&"shot": 1.0, &"batted": 1.0, &"stabbed": 1.0, &"lost_arm": 0.0, &"lost_leg": 0.0, &"legless": 12.0,
	&"bomb_near": 3.0, &"blown_up": 1.0,
}
const DEFAULT_COOLDOWN := 4.0
const GAP := 1.2
const RECENT_KEPT := 3

const THROWN_SPEED := 1500.0
const DANGLE_TIME := 4.0
const UPSIDE_DOWN_TILT := 2.4
const UPSIDE_DOWN_TIME := 1.0
const FLIGHT_TIME := 0.8
const DIZZY_SPIN := 12.0
const DIZZY_TIME := 1.2
const LOW_HEALTH := Buddy.LOW_HEALTH
const IDLE_FIRST := 15.0
const BORED_AFTER := 45.0

var buddy: Buddy
var untouched := 0.0
var _rng := RandomNumberGenerator.new()
var _recent: Dictionary = {}
var _cooldowns: Dictionary = {}
var _gap := 0.0
var _next_idle := IDLE_FIRST
var _airborne := 0.0
var _held := 0.0
var _upside := 0.0
var _spin := 0.0
var _dizzy_pending := false
var _was_low := false
var _last_state := Buddy.State.RAGDOLL
var _gravity_kind := &"normal"


func _ready() -> void:
	_rng.randomize()
	buddy.hit_taken.connect(_on_hit)
	buddy.grabbed.connect(_on_grabbed)
	buddy.released.connect(_on_released)
	buddy.knocked_out.connect(_on_knocked_out)
	buddy.revived.connect(_on_revived)
	buddy.affected.connect(_on_affected)
	buddy.limb_lost.connect(_on_limb_lost)
	Events.gravity_changed.connect(_on_gravity_changed)
	Events.slowmo_changed.connect(_on_slowmo_changed)
	Events.room_cleaned.connect(_on_room_cleaned)
	var greeting := &"respawn" if buddy.has_meta(&"respawned") else &"spawn"
	get_tree().create_timer(0.8, false).timeout.connect(func() -> void: say(greeting))


## Says a line for `context` if allowed now. Returns true if it spoke.
func say(context: StringName, chance := 1.0) -> bool:
	if buddy.is_knocked_out or not BuddyLines.LINES.has(context):
		return false
	var priority: int = PRIORITY.get(context, 1)
	if buddy.bubble.is_talking() and priority < buddy.bubble.priority:
		return false
	if priority < CHATTY and _gap > 0.0:
		return false
	if _cooldowns.get(context, 0.0) > 0.0:
		return false
	if _rng.randf() > chance:
		return false
	var line := _pick_line(context)
	buddy.bubble.say(line, priority)
	_gap = GAP
	_cooldowns[context] = COOLDOWN.get(context, DEFAULT_COOLDOWN)
	Events.buddy_spoke.emit(line, context)
	return true


func _pick_line(context: StringName) -> String:
	var lines: Array = BuddyLines.LINES[context]
	var recent: Array = _recent.get(context, [])
	var choices: Array[int] = []
	for index in lines.size():
		if not recent.has(index):
			choices.append(index)
	if choices.is_empty():
		choices.append(_rng.randi() % lines.size())
	var picked: int = choices[_rng.randi() % choices.size()]
	recent.append(picked)
	while recent.size() > mini(RECENT_KEPT, lines.size() - 1):
		recent.pop_front()
	_recent[context] = recent
	return lines[picked]


func _physics_process(delta: float) -> void:
	_gap = maxf(_gap - delta, 0.0)
	for key: StringName in _cooldowns.keys():
		_cooldowns[key] = maxf(_cooldowns[key] - delta, 0.0)
	var state := buddy.state
	if buddy.is_knocked_out:
		_last_state = state
		return
	untouched += delta
	if buddy.burn_time > 0.0:
		untouched = 0.0
		say(&"on_fire")
	if not buddy.parts.has(&"leg_l") or not buddy.parts.has(&"leg_r"):
		if state == Buddy.State.RAGDOLL and untouched > 6.0:
			say(&"legless")
	_track_flight(delta, state)
	_track_spin(delta)
	_track_held(delta, state)
	_track_health()
	if state != _last_state:
		_on_state_changed(_last_state, state)
		_last_state = state
	_track_idle()


func _track_flight(delta: float, state: Buddy.State) -> void:
	if state == Buddy.State.RAGDOLL and buddy.is_airborne():
		_airborne += delta
		return
	if _airborne >= FLIGHT_TIME and state != Buddy.State.GRABBED:
		say(&"survived", 0.6)
	_airborne = 0.0


func _track_spin(delta: float) -> void:
	if absf(buddy.torso.angular_velocity) > DIZZY_SPIN:
		_spin += delta
		if _spin >= DIZZY_TIME:
			_dizzy_pending = true
	else:
		_spin = maxf(_spin - delta * 0.5, 0.0)


func _track_held(delta: float, state: Buddy.State) -> void:
	if state != Buddy.State.GRABBED:
		_held = 0.0
		_upside = 0.0
		return
	untouched = 0.0
	_held += delta
	if _held >= DANGLE_TIME:
		say(&"dangling")
	_upside = _upside + delta if buddy.tilt() > UPSIDE_DOWN_TILT else 0.0
	if _upside >= UPSIDE_DOWN_TIME:
		say(&"upside_down")


func _track_health() -> void:
	if buddy.health < LOW_HEALTH + 20.0:
		_was_low = true
	elif _was_low and buddy.health >= Buddy.MAX_HEALTH:
		_was_low = false
		say(&"healed")


func _track_idle() -> void:
	if not buddy.is_standing_still() or untouched < _next_idle:
		return
	_next_idle = untouched + _rng.randf_range(8.0, 16.0)
	if untouched >= BORED_AFTER:
		if _rng.randf() < 0.5 and buddy.play_idle(&"yawn", 1.3):
			buddy.show_face(&"yawn", 1.3)
			Sfx.play(&"yawn", -4.0, buddy.voice_pitch)
		else:
			buddy.show_face(&"bored", 3.0)
			say(&"bored")
		return
	match _rng.randi() % 3:
		0:
			say(&"idle")
		1:
			buddy.play_idle(&"tap_foot", 2.0)
		2:
			buddy.play_idle(&"look_around", 2.5)


func _on_state_changed(from: Buddy.State, to: Buddy.State) -> void:
	if to == Buddy.State.GETTING_UP and from == Buddy.State.RAGDOLL:
		if buddy.health < LOW_HEALTH:
			buddy.show_face(&"groggy", 2.0)
			say(&"low_health")
		else:
			say(&"getting_up", 0.3)
	elif to == Buddy.State.STANDING and _dizzy_pending:
		_dizzy_pending = false
		_spin = 0.0
		buddy.show_face(&"dizzy", 2.5)
		say(&"dizzy")


func _on_hit(info: Dictionary) -> void:
	untouched = 0.0
	var force: float = info.get("force", 0.0)
	var damage: float = info.get("damage", 0.0)
	var part: StringName = info["part"]
	var source: StringName = info.get("source", &"wall")
	if info.get("quiet", false):
		return
	var loudness := clampf(remap(force, 300.0, 4000.0, -14.0, 0.0), -14.0, 2.0)
	if force < 300.0:
		pass
	elif force >= 2500.0:
		Sfx.play(&"crunch", loudness)
	elif force >= 1200.0:
		Sfx.play(&"smack", loudness)
	else:
		Sfx.play(&"thud", loudness)
	if damage >= Buddy.BLEED_DAMAGE:
		Sfx.play(&"splat", -6.0)
	if info.get("knocked_out", false) or buddy.is_knocked_out:
		return
	var position: Vector2 = info.get("position", buddy.torso.global_position)
	var context := &""
	if info.has("severed"):
		return
	if SOURCE_CONTEXT.has(source) and (damage > 0.0 or force > 700.0):
		context = SOURCE_CONTEXT[source]
	elif source in [&"slap", &"lightning", &"fire", &"black_hole"]:
		return
	elif source != &"wall" and force > 700.0:
		context = &"hit_object"
	elif part == &"head" and damage > 3.0:
		context = &"hit_head"
	elif source == &"wall" and position.y < 40.0 and damage > 2.0:
		context = &"hit_ceiling"
	elif damage >= 15.0:
		context = &"hit_hard"
	elif damage > 2.0:
		context = &"hit_medium"
	elif force > 600.0:
		context = &"hit_light"
	if context == &"":
		return
	if damage >= 15.0:
		Sfx.play(&"grunt", -2.0, buddy.voice_pitch)
	elif damage > 2.0:
		Sfx.play(&"yelp", -3.0, buddy.voice_pitch)
	elif _rng.randf() < 0.5:
		Sfx.play(&"squeak", -6.0, buddy.voice_pitch)
	if say(context, 0.4 if context == &"hit_light" else 1.0) and damage > 2.0:
		buddy.show_face(&"angry", 1.8)


func _on_affected(kind: StringName) -> void:
	untouched = 0.0
	if buddy.is_knocked_out or not AFFECTED.has(kind):
		return
	var reaction: Array = AFFECTED[kind]
	var context: StringName = reaction[0]
	if kind == &"frozen":
		# Say it first, then the ice stops the jaw.
		buddy.bubble.silence()
	var spoke := say(context, reaction[1])
	if reaction[2] != &"" and (spoke or kind == &"tickle"):
		Sfx.play(reaction[2], -4.0, buddy.voice_pitch)
	if reaction[3] != &"":
		buddy.show_face(reaction[3], 1.2)


func _on_limb_lost(limb: StringName, _part: BuddyPart) -> void:
	untouched = 0.0
	if buddy.is_knocked_out:
		return
	Sfx.play(&"scream", -3.0, buddy.voice_pitch * 1.1)
	_cooldowns.erase(&"lost_arm")
	_cooldowns.erase(&"lost_leg")
	say(&"lost_arm" if String(limb).begins_with("arm") else &"lost_leg")


func _on_grabbed(part: StringName) -> void:
	untouched = 0.0
	if buddy.is_knocked_out:
		return
	Sfx.play(&"squeak", -6.0, buddy.voice_pitch)
	var context := &"grabbed"
	if part == &"head":
		context = &"grabbed_head"
	elif part != &"torso":
		context = &"grabbed_limb"
	say(context, 0.8)


func _on_released(velocity: Vector2) -> void:
	if buddy.is_knocked_out:
		return
	if velocity.length() >= THROWN_SPEED:
		Sfx.play(&"scream", -5.0, buddy.voice_pitch)
		say(&"thrown")


func _on_knocked_out() -> void:
	buddy.bubble.silence()
	Sfx.play(&"ko", -2.0, buddy.voice_pitch)
	_airborne = 0.0
	_dizzy_pending = false


func _on_revived() -> void:
	Sfx.play(&"revive", -4.0)
	buddy.show_face(&"dizzy", 2.5)
	say(&"revived")


func _on_gravity_changed(gravity: Vector2) -> void:
	var kind := &"normal"
	if gravity.length() < 1.0:
		kind = &"zero_g"
	elif gravity.normalized().dot(Vector2.DOWN) < 0.99:
		kind = &"weird"
	if kind == _gravity_kind:
		return
	_gravity_kind = kind
	match kind:
		&"zero_g":
			say(&"zero_g")
		&"weird":
			say(&"gravity_weird")
		_:
			say(&"gravity_normal")


func _on_slowmo_changed(enabled: bool) -> void:
	if enabled:
		say(&"slowmo", 0.7)


func _on_room_cleaned() -> void:
	say(&"cleaned", 0.5)
