extends TestSuite
## The Buddy's physics: standing, grabbing, throwing, recovering and staying in one
## piece. Run with --fixed-fps 120 so simulated time doesn't wait on the clock.

const MAIN_SCENE := preload("res://scenes/main.tscn")
## Physics steps per simulated second.
const HZ := 120

var main: Node2D
var buddy: Buddy
var grab: Grabber
var hits: Array[Dictionary] = []


func before_each() -> void:
	reset_game("buddy")
	hits.clear()
	main = MAIN_SCENE.instantiate()
	add_child(main)
	buddy = main.buddy
	grab = main.grabber
	grab.manual_target = true
	Events.buddy_hit.connect(_on_hit)
	await frames(1)


func after_each() -> void:
	Events.buddy_hit.disconnect(_on_hit)
	main.queue_free()
	await frames(1)


func test_body_is_assembled() -> bool:
	check_eq(buddy.part_list.size(), 6, "six parts")
	check_eq(buddy.joints.size(), 5, "five joints")
	check(is_equal_approx(buddy.total_mass, 7.2), "total mass %.2f" % buddy.total_mass)
	check(buddy.joint_stretch() < 0.5, "joints start closed")
	return true


func test_drops_and_stands_up() -> bool:
	await _seconds(5.0)
	check_eq(buddy.state, Buddy.State.STANDING, "standing")
	check(_tilt() < 0.15, "upright (tilt %.2f)" % _tilt())
	var height := Room.FLOOR_Y - buddy.torso.global_position.y
	check(absf(height - Buddy.HOVER_HEIGHT) < 20.0, "torso at hip height (%.0f)" % height)
	check(buddy.joint_stretch() < 3.0, "joints closed (%.1f)" % buddy.joint_stretch())
	_check_inside("after standing")
	return true


func test_wanders_and_stays_upright() -> bool:
	await _seconds(4.0)
	var last_x := buddy.torso.global_position.x
	var distance := 0.0
	var walked := false
	var worst_tilt := 0.0
	for _step in 12 * HZ:
		await physics_frames(1)
		walked = walked or buddy.is_walking()
		worst_tilt = maxf(worst_tilt, _tilt())
		distance += absf(buddy.torso.global_position.x - last_x)
		last_x = buddy.torso.global_position.x
	check(walked, "went for a walk")
	check(distance > 200.0, "actually moved (%.0f px walked)" % distance)
	check_eq(buddy.state, Buddy.State.STANDING, "still standing")
	check(worst_tilt < 0.4, "waddles without falling (worst tilt %.2f)" % worst_tilt)
	_check_inside("after wandering")
	return true


func test_grab_head_and_lift() -> bool:
	await _seconds(4.0)
	var start := buddy.head.global_position
	hits.clear()
	check(grab.grab_at(start), "grabbed")
	check_eq(buddy.state, Buddy.State.GRABBED, "grabbed state")
	check_eq(buddy.held_part, &"head", "head is held")
	for index in HZ:
		grab.target = start + Vector2(0, -300.0 * index / HZ)
		await physics_frames(1)
	await _seconds(0.5)
	var error := (buddy.head.to_global(grab.held_offset) - grab.target).length()
	check(error < 15.0, "held point follows the cursor (%.1f off)" % error)
	var lowest := _lowest_part()
	check(lowest < Room.FLOOR_Y - 60.0, "whole body off the floor (lowest %.0f)" % lowest)
	check(buddy.torso.global_position.y > buddy.head.global_position.y + 40.0,
			"body hangs below the head (torso y %.0f, head y %.0f)" % [buddy.torso.global_position.y, buddy.head.global_position.y])
	check(buddy.joint_stretch() < 6.0, "dangles in one piece (%.1f)" % buddy.joint_stretch())
	check(hits.is_empty(), "lifting it gently isn't a hit (%d reported)" % hits.size())
	check_eq(buddy.hurt_time, 0.0, "not hurt")
	return true


func test_grab_every_part() -> bool:
	await _seconds(4.0)
	for part in buddy.part_list:
		var at := part.global_position
		check(grab.grab_at(at), "can grab %s" % part.part_name)
		check(grab.held == part or (grab.held as BuddyPart).pick_priority >= part.pick_priority,
				"%s or something drawn over it is picked" % part.part_name)
		grab.target = at + Vector2(0, -150)
		await _seconds(0.4)
		grab.release()
		await _seconds(0.6)
	_check_inside("after grabbing each part")
	return true


func test_fast_shaking_stays_together() -> bool:
	await _seconds(3.0)
	check(grab.grab_at(buddy.parts[&"arm_r"].global_position), "grabbed arm")
	var worst := 0.0
	for index in 3 * HZ:
		grab.target = Vector2(250 if (index / 10) % 2 == 0 else 1650, 300 + (index % 7) * 60)
		await physics_frames(1)
		worst = maxf(worst, buddy.joint_stretch())
		if not _all_finite():
			break
	check(_all_finite(), "no NaN")
	check(worst < 40.0, "joints hold while shaken (worst %.1f)" % worst)
	_check_inside("while shaken")
	grab.release()
	await _seconds(3.0)
	check(buddy.joint_stretch() < 3.0, "settles back together (%.1f)" % buddy.joint_stretch())
	return true


func test_throw_into_wall_hits_and_is_capped() -> bool:
	await _seconds(3.0)
	check(grab.grab_at(buddy.torso.global_position), "grabbed torso")
	grab.target = Vector2(400, 500)
	await _seconds(0.6)
	for index in 14:
		grab.target = Vector2(400 + index * 90, 500)
		await physics_frames(1)
	grab.release()
	var speed := buddy.torso.linear_velocity.length()
	check(speed > 2000.0, "thrown hard (%.0f px/s)" % speed)
	check(speed <= Grabber.MAX_THROW_SPEED + 1.0, "throw is capped (%.0f)" % speed)
	check(buddy.torso.linear_velocity.x > 0.0, "thrown right")
	check_eq(buddy.state, Buddy.State.RAGDOLL, "ragdoll after release")
	await _seconds(1.0)
	var wall_hits := hits.filter(func(hit: Dictionary) -> bool: return hit["source"] == &"wall")
	check(not wall_hits.is_empty(), "hit the wall")
	var strongest := 0.0
	for hit in wall_hits:
		strongest = maxf(strongest, hit["force"])
	check(strongest > 1500.0, "hard hit reported (%.0f)" % strongest)
	_check_inside("after the throw")
	return true


func test_throw_into_floor_bounces() -> bool:
	await _seconds(3.0)
	check(grab.grab_at(buddy.torso.global_position), "grabbed")
	grab.target = Vector2(960, 200)
	await _seconds(0.8)
	for index in 10:
		grab.target = Vector2(960, 200 + index * 60)
		await physics_frames(1)
	grab.release()
	var went_up := false
	for _step in HZ:
		await physics_frames(1)
		if buddy.torso.linear_velocity.y < -150.0:
			went_up = true
			break
	check(went_up, "bounced back up off the floor")
	check(hits.any(func(hit: Dictionary) -> bool: return hit["force"] > 1000.0), "floor slam reported")
	return true


func test_recovers_after_a_throw() -> bool:
	await _seconds(3.0)
	buddy.launch(Vector2(-3500, -1800))
	var stood := false
	for _step in 10 * HZ:
		await physics_frames(1)
		if buddy.state == Buddy.State.STANDING:
			stood = true
			break
	check(stood, "back on its feet within 10 s")
	return true


func test_hard_hit_knocks_it_down() -> bool:
	await _seconds(5.0)
	check_eq(buddy.state, Buddy.State.STANDING, "standing first")
	var ball: TestBall = main.spawn_test_ball(buddy.head.global_position + Vector2(-300, 0))
	ball.linear_velocity = Vector2(3000, 0)
	await _seconds(0.5)
	check(buddy.state != Buddy.State.STANDING, "knocked over")
	check(hits.any(func(hit: Dictionary) -> bool: return hit["source"] == &"object"), "hit by an object reported")
	return true


func test_stands_on_whatever_gravity_points_at() -> bool:
	main.set_gravity(Vector2(-Buddy.MIN_GRAVITY_TO_STAND * 19.6, 0))
	await _seconds(6.0)
	check_eq(buddy.state, Buddy.State.STANDING, "standing on the left wall")
	check(buddy.torso.global_position.x < 150.0, "near the left wall (x=%.0f)" % buddy.torso.global_position.x)
	check(_tilt() < 0.2, "upright relative to gravity (%.2f)" % _tilt())
	main.set_gravity(Vector2.ZERO)
	await _seconds(1.0)
	check_eq(buddy.state, Buddy.State.RAGDOLL, "floats limp in zero-G")
	return true


func test_long_abuse_stays_stable() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for round_index in 20:
		var part: BuddyPart = buddy.part_list[rng.randi() % buddy.part_list.size()]
		if grab.grab_at(part.global_position):
			for _step in 20:
				grab.target = Vector2(rng.randf_range(100, 1820), rng.randf_range(100, 850))
				await physics_frames(3)
			grab.release()
		await physics_frames(rng.randi_range(10, 90))
		if not _all_finite():
			break
	check(_all_finite(), "no NaN after 20 rounds")
	_check_inside("after abuse")
	await _seconds(8.0)
	check(buddy.joint_stretch() < 3.0, "in one piece (%.1f)" % buddy.joint_stretch())
	check_eq(buddy.state, Buddy.State.STANDING, "stood back up")
	return true


func test_respawn_and_lost_buddy() -> bool:
	var old := buddy
	var respawned := [false]
	var on_respawn := func() -> void: respawned[0] = true
	Events.buddy_respawned.connect(on_respawn)
	main.respawn()
	await frames(1)
	check(not is_instance_valid(old), "old buddy freed")
	check(main.buddy != old and main.buddy != null, "new buddy")
	check(respawned[0], "event")
	respawned[0] = false
	buddy = main.buddy
	buddy.torso.global_position = Vector2(5000, 5000)
	await physics_frames(3)
	check(respawned[0], "a lost buddy is respawned automatically")
	Events.buddy_respawned.disconnect(on_respawn)
	return true


func test_left_click_needs_the_hand() -> bool:
	await _seconds(3.0)
	var at := buddy.torso.global_position
	Game.profile.owned_tools.append("brick")
	Game.select_tool("brick")
	check(not grab.press(MOUSE_BUTTON_LEFT, at), "left click with another tool doesn't grab")
	check(grab.press(MOUSE_BUTTON_RIGHT, at), "right click always grabs")
	grab.release()
	Game.select_tool("hand")
	check(grab.press(MOUSE_BUTTON_LEFT, at), "left click with the hand grabs")
	grab.release()
	check(not grab.press(MOUSE_BUTTON_LEFT, Vector2(100, 100)), "clicking empty air grabs nothing")
	return true


func test_grabbing_emits_events() -> bool:
	await _seconds(3.0)
	var log: Array = []
	var on_grab := func(part: StringName) -> void: log.append(["grab", part])
	var on_release := func(part: StringName, _velocity: Vector2) -> void: log.append(["release", part])
	Events.buddy_grabbed.connect(on_grab)
	Events.buddy_released.connect(on_release)
	grab.grab_at(buddy.head.global_position)
	grab.release()
	Events.buddy_grabbed.disconnect(on_grab)
	Events.buddy_released.disconnect(on_release)
	check_eq(log, [["grab", &"head"], ["release", &"head"]], "events")
	return true


func _on_hit(info: Dictionary) -> void:
	hits.append(info)


func _seconds(seconds: float) -> void:
	await physics_frames(int(seconds * HZ))


func _tilt() -> float:
	return buddy._tilt(buddy.gravity())


func _lowest_part() -> float:
	var lowest := -INF
	for part in buddy.part_list:
		lowest = maxf(lowest, part.global_position.y)
	return lowest


func _all_finite() -> bool:
	for part in buddy.part_list:
		if not part.global_position.is_finite() or not part.linear_velocity.is_finite():
			return false
	return true


func _check_inside(label: String) -> void:
	var room: Rect2 = main.room.interior().grow(2.0)
	for part in buddy.part_list:
		check(room.has_point(part.global_position), "%s: %s inside the room (%s)" % [label, part.part_name, part.global_position])
