extends TestSuite
## Milestone 3: health, knockouts, reviving, speech, faces, blood and sounds.
## Run with --fixed-fps 120.

const MAIN_SCENE := preload("res://scenes/main.tscn")
const HZ := 120

var main: Node2D
var buddy: Buddy
var grab: Grabber
var spoken: Array = []
var events: Array = []


func before_each() -> void:
	reset_game("reactions")
	spoken.clear()
	events.clear()
	main = MAIN_SCENE.instantiate()
	add_child(main)
	buddy = main.buddy
	grab = main.grabber
	grab.manual_target = true
	Events.buddy_spoke.connect(_on_spoke)
	Events.buddy_knocked_out.connect(_on_knocked_out)
	Events.buddy_revived.connect(_on_revived)
	await frames(1)


func after_each() -> void:
	Events.buddy_spoke.disconnect(_on_spoke)
	Events.buddy_knocked_out.disconnect(_on_knocked_out)
	Events.buddy_revived.disconnect(_on_revived)
	main.queue_free()
	await frames(1)


func test_damage_scales_with_force_and_part() -> bool:
	check_eq(Buddy.damage_for(&"torso", 1300.0), 0.0, "falls from standing height don't hurt")
	var torso := Buddy.damage_for(&"torso", 3000.0)
	check(torso > 15.0 and torso < 30.0, "a hard wall slam does real damage (%.1f)" % torso)
	check(Buddy.damage_for(&"head", 3000.0) > torso, "head hits hurt more")
	check(Buddy.damage_for(&"arm_l", 3000.0) < torso, "limb hits hurt less")
	return true


func test_hit_lowers_health_and_reports_damage() -> bool:
	var reported: Array = []
	var on_hit := func(info: Dictionary) -> void: reported.append(info)
	var health_seen: Array = []
	var on_health := func(health: float, _max: float, _ko: bool) -> void: health_seen.append(health)
	Events.buddy_hit.connect(on_hit)
	Events.buddy_health_changed.connect(on_health)
	var info := buddy.take_hit({"part": &"torso", "force": 3000.0, "position": buddy.torso.global_position})
	Events.buddy_hit.disconnect(on_hit)
	Events.buddy_health_changed.disconnect(on_health)
	check(info["damage"] > 0.0, "damage filled in")
	check(is_equal_approx(buddy.health, Buddy.MAX_HEALTH - info["damage"]), "health dropped (%.1f)" % buddy.health)
	check_eq(reported.size(), 1, "one hit event")
	check(not health_seen.is_empty() and health_seen[-1] == buddy.health, "health event sent")
	check(not buddy.torso.marks.is_empty(), "left a mark on the skin")
	return true


func test_knockout_stays_down_then_revives() -> bool:
	await _seconds(3.0)
	buddy.take_hit({"part": &"head", "force": 1000.0, "damage": 300.0, "position": buddy.head.global_position})
	check(buddy.is_knocked_out, "knocked out")
	check_eq(buddy.health, 0.0, "no health")
	check_eq(events, ["ko"], "KO event")
	check_eq(main.buddy.view.pick_expression(), &"ko", "X eyes")
	await _seconds(Buddy.REVIVE_TIME - 1.0)
	check(buddy.is_knocked_out, "still out before the revive time")
	check(buddy.state == Buddy.State.RAGDOLL, "lying limp, not getting up")
	await _seconds(1.5)
	check(not buddy.is_knocked_out, "woke up by itself")
	check(is_equal_approx(buddy.health, Buddy.REVIVE_HEALTH), "revived with some health (%.1f)" % buddy.health)
	check_eq(events, ["ko", "revived"], "revive event")
	return true


func test_click_wakes_it_up() -> bool:
	await _seconds(3.0)
	buddy.take_hit({"part": &"torso", "force": 1000.0, "damage": 300.0, "position": buddy.torso.global_position})
	await _seconds(1.0)
	check(grab.grab_at(buddy.torso.global_position), "grabbed the limp body")
	await physics_frames(3)
	grab.release()
	check(not buddy.is_knocked_out, "a quick click revives")
	return true


func test_dragging_a_knocked_out_buddy_does_not_wake_it() -> bool:
	await _seconds(3.0)
	buddy.take_hit({"part": &"torso", "force": 1000.0, "damage": 300.0, "position": buddy.torso.global_position})
	grab.grab_at(buddy.torso.global_position)
	for index in 60:
		grab.target = buddy.torso.global_position + Vector2(0, -4.0 * index)
		await physics_frames(1)
	grab.release()
	check(buddy.is_knocked_out, "a drag is not a click")
	return true


func test_heals_when_left_alone() -> bool:
	await _seconds(4.0)
	buddy.take_hit({"part": &"torso", "force": 1000.0, "damage": 40.0, "position": buddy.torso.global_position})
	var hurt := buddy.health
	await _seconds(Buddy.HEAL_DELAY - 0.5)
	check(is_equal_approx(buddy.health, hurt), "no healing right after a hit")
	await _seconds(3.0)
	check(buddy.health > hurt + 5.0, "heals after a while (%.1f -> %.1f)" % [hurt, buddy.health])
	return true


func test_says_hello_when_it_arrives() -> bool:
	await _seconds(1.5)
	check(_contexts().has(&"spawn"), "greeted (%s)" % [_contexts()])
	check(buddy.bubble.visible, "bubble showing")
	main.respawn()
	await _seconds(1.5)
	check(_contexts().has(&"respawn"), "respawn line (%s)" % [_contexts()])
	return true


func test_hard_hit_gets_a_hard_reaction() -> bool:
	await _seconds(2.0)
	_quiet()
	buddy.take_hit({"part": &"torso", "force": 3500.0, "source": &"wall", "position": Vector2(1000, 600)})
	check_eq(_contexts().back(), &"hit_hard", "hit_hard line")
	check(buddy.bubble.is_talking(), "bubble up")
	check(BuddyLines.LINES[&"hit_hard"].has(buddy.bubble.text), "said a hit_hard line")
	_quiet()
	buddy.take_hit({"part": &"head", "force": 3500.0, "source": &"wall", "position": Vector2(1000, 600)})
	check_eq(_contexts().back(), &"hit_head", "head hits get head lines")
	return true


func test_unimportant_lines_cannot_interrupt() -> bool:
	await _seconds(2.0)
	_quiet()
	buddy.take_hit({"part": &"torso", "force": 3500.0, "source": &"wall", "position": Vector2(1000, 600)})
	var said := buddy.bubble.text
	buddy.mind._gap = 0.0
	check(not buddy.mind.say(&"idle"), "idle chatter waits")
	check_eq(buddy.bubble.text, said, "the hit line stays")
	check(buddy.mind.say(&"revived"), "something more important can interrupt")
	return true


func test_lines_do_not_repeat_back_to_back() -> bool:
	await _seconds(1.0)
	var seen: Array[String] = []
	for _index in 4:
		_quiet()
		buddy.mind._cooldowns.clear()
		buddy.mind.say(&"hit_hard")
		seen.append(buddy.bubble.text)
	for index in range(1, seen.size()):
		check(seen[index] != seen[index - 1], "no immediate repeat (%s)" % [seen])
	return true


func test_every_situation_has_lines() -> bool:
	for context: StringName in BuddyMind.PRIORITY:
		var lines: Array = BuddyLines.LINES.get(context, [])
		check(not lines.is_empty(), "%s has lines" % context)
	for context: StringName in BuddyLines.LINES:
		check(BuddyMind.PRIORITY.has(context), "%s has a priority" % context)
	return true


func test_knocked_out_buddy_is_silent() -> bool:
	await _seconds(2.0)
	buddy.take_hit({"part": &"torso", "force": 1000.0, "damage": 300.0, "position": buddy.torso.global_position})
	check(not buddy.bubble.visible, "bubble gone")
	_quiet()
	check(not buddy.mind.say(&"revived"), "can't talk while out")
	return true


func test_grab_and_throw_reactions() -> bool:
	await _seconds(3.0)
	# Grabs speak 80% of the time, so give it a few tries.
	var said := &""
	for _attempt in 8:
		_quiet()
		grab.grab_at(buddy.head.global_position)
		if not spoken.is_empty():
			said = _contexts().back()
			break
		grab.release()
		await physics_frames(2)
	check_eq(said, &"grabbed_head", "head grab line")
	grab.target = Vector2(400, 400)
	await _seconds(0.6)
	_quiet()
	for index in 12:
		grab.target = Vector2(400 + index * 90, 400)
		await physics_frames(1)
	grab.release()
	check(_contexts().has(&"thrown"), "screams when thrown (%s)" % [_contexts()])
	return true


func test_left_alone_it_does_something() -> bool:
	await _seconds(5.0)
	check_eq(buddy.state, Buddy.State.STANDING, "standing")
	var acted := false
	buddy.walk_direction = 0.0
	buddy._idle_time = 100.0 # Don't wander off mid-test.
	for _attempt in 6:
		_quiet()
		buddy.walk_direction = 0.0
		buddy.mind.untouched = BuddyMind.IDLE_FIRST + 1.0
		buddy.mind._next_idle = 0.0
		await physics_frames(2)
		if not spoken.is_empty() or buddy.idle_action != &"":
			acted = true
			break
	check(acted, "chats or fidgets when idle")
	_quiet()
	buddy.walk_direction = 0.0
	buddy.mind.untouched = BuddyMind.BORED_AFTER + 1.0
	buddy.mind._next_idle = 0.0
	await physics_frames(2)
	check(buddy.face_override == &"bored" or buddy.face_override == &"yawn", "bored face after a long time (%s)" % buddy.face_override)
	return true


func test_gravity_comments() -> bool:
	await _seconds(2.0)
	_quiet()
	main.set_gravity(Vector2.ZERO)
	check_eq(_contexts().back() if not spoken.is_empty() else &"", &"zero_g", "notices zero-G")
	_quiet()
	main.set_gravity(Vector2(0, main.BASE_GRAVITY))
	check_eq(_contexts().back() if not spoken.is_empty() else &"", &"gravity_normal", "notices gravity is back")
	return true


func test_faces_follow_what_is_happening() -> bool:
	await _seconds(4.0)
	check_eq(buddy.view.pick_expression(), &"happy", "happy when fine")
	buddy.take_hit({"part": &"torso", "force": 2000.0, "position": buddy.torso.global_position})
	check_eq(buddy.view.pick_expression(), &"ouch", "ouch right after a hit")
	await _seconds(Buddy.HURT_TIME + 0.1)
	buddy.show_face(&"smug", 1.0)
	check_eq(buddy.view.pick_expression(), &"smug", "the mind can set a face")
	return true


func test_blood_sprays_stains_and_cleans_up() -> bool:
	var decals: DecalLayer = main.room.decals
	check_eq(decals.stained_samples(), 0, "clean room")
	var at := Vector2(1919, 500)
	buddy.take_hit({"part": &"torso", "force": 4000.0, "source": &"wall", "position": at})
	check(decals.is_stained(at - Vector2(30, 0)), "splat at the impact, fully inside the room")
	check(not main.blood.drops.is_empty(), "drops flying")
	var before := decals.stained_samples()
	await _seconds(3.0)
	check(main.blood.drops.is_empty(), "drops all landed")
	check(decals.stained_samples() > before, "drops left stains (%d -> %d)" % [before, decals.stained_samples()])
	main.clean_up()
	check_eq(decals.stained_samples(), 0, "clean up wipes the stains")
	return true


func test_wall_slam_draws_blood() -> bool:
	await _seconds(3.0)
	var start := buddy.health
	buddy.launch(Vector2(4500, -300))
	await _seconds(1.0)
	check(buddy.health < start, "slam hurt (%.1f)" % buddy.health)
	check(main.room.decals.stained_samples() > 0, "blood on the walls")
	return true


func test_respawn_is_clean_and_healthy() -> bool:
	buddy.take_hit({"part": &"torso", "force": 4000.0, "position": buddy.torso.global_position})
	check(not buddy.torso.marks.is_empty(), "marked")
	main.respawn()
	await frames(1)
	var fresh: Buddy = main.buddy
	check_eq(fresh.health, Buddy.MAX_HEALTH, "full health")
	for part in fresh.part_list:
		check(part.marks.is_empty(), "%s unmarked" % part.part_name)
	return true


func test_health_bar_shows_health_and_ko() -> bool:
	var hud: Hud = main.hud
	buddy.take_hit({"part": &"torso", "force": 1000.0, "damage": 40.0, "position": buddy.torso.global_position})
	check(is_equal_approx(hud.health_bar.value, 160.0), "bar at 160 (%.1f)" % hud.health_bar.value)
	check_eq(hud.health_label.text, "HP", "label")
	buddy.take_hit({"part": &"torso", "force": 1000.0, "damage": 200.0, "position": buddy.torso.global_position})
	check_eq(hud.health_label.text, "KO!", "KO shown")
	return true


func test_all_sounds_exist() -> bool:
	for sound: StringName in [&"squeak", &"yelp", &"grunt", &"scream", &"ko", &"revive", &"yawn",
			&"giggle", &"thud", &"smack", &"crunch", &"splat", &"pop", &"syllable_a", &"syllable_u"]:
		var stream: AudioStreamWAV = Sfx.sounds.get(sound)
		check(stream != null and stream.data.size() > 1000, "%s synthesized" % sound)
	Sfx.play(&"thud")
	Sfx.babble(1.2)
	return true


func test_music_loop_builds() -> bool:
	var started := Time.get_ticks_msec()
	var track: AudioStreamWAV = Music.build()
	var took := Time.get_ticks_msec() - started
	check_eq(track.loop_mode, AudioStreamWAV.LOOP_FORWARD, "loops")
	var seconds := track.data.size() / 2.0 / Music.RATE
	check(absf(seconds - 16.0) < 0.05, "8 bars at 120 BPM (%.2f s)" % seconds)
	check_eq(track.loop_end, track.data.size() / 2, "loops at the very end")
	check(took < 8000, "builds in reasonable time (%d ms)" % took)
	print("    music built in %d ms" % took)
	var loud := 0
	for index in range(0, track.data.size(), 400):
		if absi(track.data.decode_s16(index)) > 3000:
			loud += 1
	check(loud > 100, "isn't silent")
	check_eq(Music.player.bus, &"Music", "plays on the Music bus")
	return true


func _on_spoke(text: String, context: StringName) -> void:
	spoken.append([text, context])


func _on_knocked_out() -> void:
	events.append("ko")


func _on_revived() -> void:
	events.append("revived")


func _contexts() -> Array:
	return spoken.map(func(entry: Array) -> StringName: return entry[1])


## Clears whatever the Buddy is saying and its timers, so the next line can play.
func _quiet() -> void:
	spoken.clear()
	buddy.bubble.silence()
	buddy.mind._gap = 0.0
	buddy.mind._cooldowns.clear()


func _seconds(seconds: float) -> void:
	await physics_frames(int(seconds * HZ))
