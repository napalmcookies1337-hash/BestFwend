extends Minigame
## Zombie Mode: two minutes against a horde. Five zombie fwends drop in and
## shamble after your cursor; when all five are down, five more come. Kill as
## many as you can with any tools you own.

const DURATION := 120.0
const WAVE_SIZE := 5
const ZOMBIE_HEALTH := 70.0
const PAY_PER_KILL := 60
const NEXT_WAVE_DELAY := 1.2
## A downed zombie lies there this long before crumbling away.
const CORPSE_TIME := 1.4

var zombies: Array[Buddy] = []
var kills := 0
var wave := 0
var _rng := RandomNumberGenerator.new()
var _wave_timer := -1.0


func _init() -> void:
	replaces_buddy = true


func begin() -> void:
	_rng.randomize()
	time_left = DURATION
	hint = "Kill the zombies! Any tool goes."
	sandbox.remove_buddy()
	_spawn_wave()


func cleanup() -> void:
	for zombie in zombies:
		if is_instance_valid(zombie):
			zombie.queue_free()
	zombies.clear()
	for corpse in sandbox.get_tree().get_nodes_in_group(&"zombies"):
		corpse.queue_free()


func score_text() -> String:
	return "%d %s" % [kills, "kill" if kills == 1 else "kills"]


func reward_for(final_score: float) -> int:
	return roundi(final_score) * PAY_PER_KILL


func tick(delta: float) -> void:
	zombies = zombies.filter(func(zombie: Buddy) -> bool: return is_instance_valid(zombie) and not zombie.is_knocked_out and not zombie.is_shattered)
	if not zombies.is_empty():
		return
	if _wave_timer < 0.0:
		_wave_timer = NEXT_WAVE_DELAY
		hint = "Wave %d down! More are coming..." % wave
	_wave_timer -= delta
	if _wave_timer <= 0.0:
		_wave_timer = -1.0
		_spawn_wave()


func _spawn_wave() -> void:
	wave += 1
	hint = "Wave %d! Kill the zombies!" % wave
	var lane := (Room.SIZE.x - 400.0) / WAVE_SIZE
	for index in WAVE_SIZE:
		var at := Vector2(200.0 + lane * (index + 0.5) + _rng.randf_range(-60, 60), Room.FLOOR_Y - 340.0 - _rng.randf_range(0, 160))
		var zombie := Buddy.new()
		zombie.bounds = sandbox.room.interior()
		zombie.is_zombie = true
		zombie.chase = true
		zombie.announces_health = false
		zombie.max_health = ZOMBIE_HEALTH
		zombie.health = ZOMBIE_HEALTH
		zombie.voice_pitch = 0.55
		zombie.skin_id = "zombie"
		zombie.build(at, SkinArt.ZOMBIE_COLOR)
		zombie.set_meta(&"zombie", true)
		zombie.add_to_group(&"zombies")
		zombie.knocked_out.connect(_on_down.bind(zombie))
		zombie.shattered.connect(_on_shattered.bind(zombie))
		zombie.lost.connect(_on_lost.bind(zombie))
		sandbox.world.add_child(zombie)
		zombies.append(zombie)
		sandbox.fx.add(0.6, Fx.smoke(at + Vector2(0, 60), 90.0, _rng.randi()))
	Sfx.play(&"grunt", -2.0, 0.5)


func _count_kill(at: Vector2) -> void:
	kills += 1
	score = kills
	sandbox.fx.add(0.5, Fx.sparks(at, 14, 200.0, Color("9cff6a"), _rng.randi()))
	Sfx.play(&"splat", -2.0, 0.7)


func _on_down(zombie: Buddy) -> void:
	_count_kill(zombie.head.global_position)
	sandbox.get_tree().create_timer(CORPSE_TIME, false).timeout.connect(func() -> void:
		if is_instance_valid(zombie):
			sandbox.fx.add(0.8, Fx.smoke(zombie.torso.global_position, 110.0, _rng.randi()))
			zombie.queue_free())


func _on_shattered(zombie: Buddy) -> void:
	_count_kill(zombie.torso.global_position)
	sandbox.shatter(zombie)


func _on_lost(zombie: Buddy) -> void:
	zombie.queue_free()
