extends TestSuite
## Milestone 4: every tool, the shared object/explosion/severing systems, and the
## Buddy's status effects. Run with --fixed-fps 120.

const MAIN_SCENE := preload("res://scenes/main.tscn")
const HZ := 120

var main: Sandbox
var buddy: Buddy
var tools: ToolUser
var hits: Array[Dictionary] = []
var kinds: Array = []


func before_each() -> void:
	reset_game("tools")
	Game.unlock_all_tools()
	hits.clear()
	kinds.clear()
	main = MAIN_SCENE.instantiate()
	add_child(main)
	buddy = main.buddy
	tools = main.tools
	tools.manual_cursor = true
	main.grabber.manual_target = true
	Events.buddy_hit.connect(_on_hit)
	Events.buddy_interacted.connect(_on_interacted)
	await _seconds(4.0)


func after_each() -> void:
	Events.buddy_hit.disconnect(_on_hit)
	Events.buddy_interacted.disconnect(_on_interacted)
	Game.select_tool("hand")
	main.queue_free()
	await frames(1)
	Engine.time_scale = 1.0


func test_catalog_is_complete() -> bool:
	var ids: Array[String] = []
	for tool in ToolCatalog.all():
		check(not ids.has(tool.id), "%s is unique" % tool.id)
		ids.append(tool.id)
		check(not tool.display_name.is_empty() and not tool.description.is_empty(), "%s has text" % tool.id)
		if tool.id == "hand":
			continue
		check(tool.price > 0, "%s has a price" % tool.id)
		check(tool.behavior != null, "%s has a behavior" % tool.id)
		check(tools.behavior_for(tool.id) != null, "%s behavior builds" % tool.id)
	check_eq(ids.size(), 36, "36 tools")
	for tool in ToolCatalog.all():
		if tool.prestige:
			check(tool.price >= 30000, "%s costs a lot (%d)" % [tool.id, tool.price])
			check(tool.order >= 5, "%s sits in a slot that used to be empty" % tool.id)
	return true


# --- Prestige weapons ----------------------------------------------------------

func test_giant_fist() -> bool:
	_use("giant_fist", buddy.head.global_position)
	await _seconds(1.5)
	check(_hurt_by(&"fist"), "fist landed (%s)" % [_sources()])
	return true


func test_mega_clap() -> bool:
	_use("mega_clap", buddy.torso.global_position)
	await _seconds(0.6)
	check(_sources().has(&"mega_clap"), "clapped")
	check(buddy.health <= Buddy.MAX_HEALTH - 40.0, "it hurts (%.1f)" % buddy.health)
	return true


func test_slingshot() -> bool:
	Game.select_tool("slingshot")
	var start := buddy.torso.global_position
	tools.press(start)
	for step in 30:
		tools.cursor = start + Vector2(step * 8.0, step * 2.0)
		await physics_frames(1)
	tools.release(tools.cursor)
	await physics_frames(2)
	check(buddy.torso.linear_velocity.x < -2500.0, "flung back the other way (%.0f)" % buddy.torso.linear_velocity.x)
	return true


func test_spin_cycle() -> bool:
	Game.select_tool("spin_cycle")
	var center := buddy.torso.global_position + Vector2(0, -250)
	tools.press(buddy.torso.global_position)
	for _step in int(1.5 * HZ):
		tools.cursor = center
		await physics_frames(1)
	var speed := buddy.torso.linear_velocity.length()
	tools.release(center)
	check(speed > 2500.0, "whirling fast (%.0f)" % speed)
	check(not buddy.levitated, "let go")
	return true


func test_wrecking_ball() -> bool:
	_use("wrecking_ball", buddy.torso.global_position)
	check_eq(get_tree().get_nodes_in_group(&"pins").size(), 0, "its chain isn't a pin")
	await _seconds(3.0)
	check(_hurt_by(&"wrecking_ball"), "smashed it (%s)" % [_sources()])
	# Near a wall it swings out into the room, never into the wall.
	for x: float in [320.0, Room.SIZE.x - 320.0]:
		main.clean_up(true)
		_use("wrecking_ball", Vector2(x, 700))
		var ball: WorldObject = null
		for object in main.objects:
			if object is WorldObject and (object as WorldObject).kind == &"wrecking_ball":
				ball = object
		check(ball != null and main.room.interior().has_point(ball.global_position), "starts inside the room at x=%d" % x)
	return true


func test_chainsaw() -> bool:
	Game.select_tool("chainsaw")
	tools.press(buddy.parts[&"arm_r"].global_position)
	for _step in int(1.5 * HZ):
		if buddy.parts.has(&"arm_r"):
			tools.cursor = buddy.parts[&"arm_r"].global_position
		await physics_frames(1)
	tools.release(tools.cursor)
	check(_sources().has(&"chainsaw"), "it cuts")
	check(buddy.severed.size() >= 1, "a limb came off")
	return true


func test_piano() -> bool:
	_use("piano", buddy.head.global_position)
	await _seconds(2.0)
	check(_hurt_by(&"piano"), "piano landed (%s)" % [_sources()])
	return true


func test_saw_launcher() -> bool:
	_use("saw_launcher", buddy.torso.global_position)
	await _seconds(1.5)
	check(buddy.severed.size() >= 1 or _hurt_by(&"sawblade"), "sawblade sliced (%s)" % [_sources()])
	return true


func test_cluster_bomb() -> bool:
	var booms := [0]
	Events.listen(main, Events.exploded, func(_at: Vector2, _radius: float) -> void: booms[0] += 1)
	var bomb := main.spawn_object(&"cluster", buddy.torso.global_position + Vector2(140, -200))
	bomb.fuse = 0.2
	await _seconds(3.0)
	check(booms[0] >= 6, "bomb plus bomblets went off (%d)" % booms[0])
	check(_sources().has(&"explosion"), "and hurt it")
	return true


func test_airstrike() -> bool:
	_use("airstrike", buddy.torso.global_position)
	await _seconds(3.5)
	check(_sources().count(&"explosion") >= 2, "missiles hit (%d)" % _sources().count(&"explosion"))
	return true


func test_rocket_pack() -> bool:
	_use("rocket_pack", buddy.torso.global_position)
	var floor_y := buddy.torso.global_position.y
	var highest := floor_y
	for _step in int(4.5 * HZ):
		highest = minf(highest, buddy.torso.global_position.y)
		await physics_frames(1)
	check(highest < floor_y - 150.0, "it took off (%.0f)" % (floor_y - highest))
	check(_sources().has(&"explosion"), "and blew up")
	check(get_tree().get_nodes_in_group(&"debris").filter(func(n: Node) -> bool: return n is RocketPack).is_empty(), "pack gone")
	return true


func test_tornado() -> bool:
	_use("tornado", buddy.torso.global_position)
	var floor_y := buddy.torso.global_position.y
	var highest := floor_y
	for _step in int(3.0 * HZ):
		highest = minf(highest, buddy.torso.global_position.y)
		await physics_frames(1)
	check(highest < floor_y - 150.0, "sucked up (%.0f)" % (floor_y - highest))
	check(_sources().has(&"tornado"), "it hurts")
	await _seconds(3.5)
	check(get_tree().get_nodes_in_group(&"tornadoes").is_empty(), "blew itself out")
	return true


func test_meteor_shower() -> bool:
	_use("meteor_shower", buddy.torso.global_position)
	await _seconds(5.5)
	check(_sources().count(&"explosion") >= 3, "meteors hit (%d)" % _sources().count(&"explosion"))
	return true


func test_orbital_laser() -> bool:
	Game.select_tool("orbital_laser")
	tools.press(buddy.torso.global_position)
	for _step in int(1.0 * HZ):
		tools.cursor = buddy.torso.global_position
		await physics_frames(1)
	tools.release(tools.cursor)
	check(_sources().has(&"orbital_laser"), "beam hit")
	check(buddy.burn_time > 0.0, "set it on fire")
	check(main.room.decals.stained_samples() > 0, "scorched the floor")
	return true


func test_land_shark() -> bool:
	_use("land_shark", Vector2(200, 800))
	await _seconds(4.0)
	check(buddy.severed.size() >= 1, "bit a limb off (%s)" % [_sources()])
	check(get_tree().get_nodes_in_group(&"debris").filter(func(n: Node) -> bool: return n is LandShark).is_empty(), "dove back under")
	return true


func test_prestige_weapons_survive_abuse() -> bool:
	var ids := ["giant_fist", "mega_clap", "wrecking_ball", "piano", "saw_launcher", "airstrike", "rocket_pack",
			"tornado", "meteor_shower", "land_shark"]
	for round_index in ids.size():
		var target := buddy.torso.global_position + Vector2(randf_range(-150, 150), randf_range(-150, 0))
		_use(ids[round_index], target)
		main.grabber.release()
		await physics_frames(60)
	await _seconds(6.0)
	check(main.buddy != null, "still has a buddy")
	for part in main.buddy.part_list:
		check(part.global_position.is_finite(), "%s finite" % part.part_name)
		check(main.room.interior().grow(5.0).has_point(part.global_position), "%s inside" % part.part_name)
	return true


func _hurt_by(source: StringName) -> bool:
	for hit in hits:
		if hit.get("source", &"") == source or hit.get("tool", &"") == source:
			return true
	return false


func test_poke() -> bool:
	var before := buddy.torso.linear_velocity
	var health := buddy.health
	_use("poke", buddy.torso.global_position + Vector2(-20, 0))
	check(kinds.has(&"poke"), "counts as a poke")
	check(buddy.torso.linear_velocity.distance_to(before) > 100.0, "nudged it")
	check(buddy.health >= health, "harmless")
	return true


func test_slap() -> bool:
	_use("slap", buddy.head.global_position + Vector2(-40, 0))
	check(kinds.has(&"slap"), "counts as a slap")
	check(_sources().has(&"slap"), "slap hit reported")
	check(buddy.health < Buddy.MAX_HEALTH, "stings (%.1f)" % buddy.health)
	check(buddy.head.linear_velocity.x > 300.0, "knocked away from the hand")
	return true


func test_tickle() -> bool:
	Game.select_tool("tickle")
	var center := buddy.torso.global_position
	check(tools.press(center), "pressed")
	for step in int(1.6 * HZ):
		tools.cursor = center + Vector2(sin(step * 0.6) * 30.0, 0)
		await physics_frames(1)
	tools.release(center)
	check(kinds.count(&"tickle") >= 2, "giggled more than once (%d)" % kinds.count(&"tickle"))
	check_eq(buddy.health, Buddy.MAX_HEALTH, "harmless")
	return true


func test_pin_and_unpin() -> bool:
	var arm: BuddyPart = buddy.parts[&"arm_r"]
	var spot := arm.global_position
	_use("pin", spot)
	check_eq(get_tree().get_nodes_in_group(&"pins").size(), 1, "one nail")
	await _seconds(1.0)
	check(arm.global_position.distance_to(spot) < 40.0, "arm stays near the nail")
	_use("pin", spot)
	await frames(1)
	check_eq(get_tree().get_nodes_in_group(&"pins").size(), 0, "clicking the nail removes it")
	return true


func test_spawn_in_hand_and_throw() -> bool:
	for kind: String in ["ball", "brick"]:
		_use(kind, Vector2(400, 400))
		var held := main.grabber.held as WorldObject
		check(held != null and String(held.kind) == kind, "%s is in the hand" % kind)
		main.grabber.release()
		check(main.grabber.held == null, "%s let go" % kind)
	return true


func test_thrown_brick_hits() -> bool:
	_use("brick", buddy.torso.global_position + Vector2(-400, -40))
	for index in 12:
		main.grabber.target = buddy.torso.global_position + Vector2(-400 + index * 50, -40)
		await physics_frames(1)
	main.grabber.release()
	await _seconds(0.6)
	check(_sources().has(&"brick"), "brick hit reported (%s)" % [_sources()])
	return true


func test_anvil_drops_on_it() -> bool:
	_use("anvil", buddy.head.global_position)
	await _seconds(2.0)
	check(_sources().has(&"anvil"), "anvil landed on it (%s)" % [_sources()])
	check(buddy.health < Buddy.MAX_HEALTH - 25.0, "that hurt (%.1f)" % buddy.health)
	return true


func test_anvil_is_heavy_in_the_hand() -> bool:
	var ball := main.spawn_object(&"ball", Vector2(400, 600))
	var anvil := main.spawn_object(&"anvil", Vector2(900, 600))
	await _seconds(1.0)
	var lag := {}
	for object: WorldObject in [ball, anvil]:
		var start := object.global_position
		main.grabber.hold(object, start, MOUSE_BUTTON_RIGHT)
		main.grabber.target = start + Vector2(0, -300)
		await _seconds(0.35)
		lag[object.kind] = (start + Vector2(0, -300)).distance_to(object.global_position)
		main.grabber.release()
		await _seconds(1.0)
	check(lag[&"anvil"] > lag[&"ball"] + 60.0, "the anvil lags far behind the cursor (%.0f vs ball %.0f)" % [lag[&"anvil"], lag[&"ball"]])
	return true


func test_anvil_falls_fast() -> bool:
	_use("anvil", Vector2(300, 700))
	var anvil: WorldObject = main.objects.back()
	await _seconds(0.2)
	check(anvil.linear_velocity.y > 1400.0, "already falling fast (%.0f)" % anvil.linear_velocity.y)
	return true


func test_bat_swing() -> bool:
	await _swipe("bat", buddy.torso.global_position + Vector2(-300, 0), buddy.torso.global_position + Vector2(300, 0), 0.25)
	var bat_hits := hits.filter(func(hit: Dictionary) -> bool: return hit["source"] == &"bat")
	check(not bat_hits.is_empty(), "bat connected")
	check(buddy.torso.linear_velocity.x > 300.0 or buddy.state != Buddy.State.STANDING, "sent flying")
	return true


func test_katana_cuts_off_a_limb() -> bool:
	var arm: BuddyPart = buddy.parts[&"arm_r"]
	var at := arm.global_position
	await _swipe("katana", at + Vector2(0, -250), at + Vector2(0, 250), 0.12)
	check(not buddy.parts.has(&"arm_r"), "the arm came off")
	var cut := buddy.severed.size()
	check(cut >= 1, "at least one limb loose (%d)" % cut)
	check_eq(buddy.stumps.size(), cut, "a stump per cut")
	var limb := buddy.severed[0]
	check(limb.detached and limb.is_in_group(&"debris"), "limb is debris")
	check_eq(buddy.joints.size(), 5 - cut, "their joints are gone")
	check_eq(buddy.part_list.size(), 6 - cut, "and they're off the body")
	await _seconds(1.0)
	check(buddy.joint_stretch() < 5.0, "the rest holds together (%.1f)" % buddy.joint_stretch())
	main.clean_up()
	await frames(1)
	check(not is_instance_valid(limb), "Clean Up removes the limb")
	return true


func test_severed_limb_is_just_an_object_in_the_hand() -> bool:
	var limb := buddy.sever(&"leg_l", Vector2(300, -300))
	await _seconds(1.0)
	check(main.grabber.grab_at(limb.global_position), "grabbed the leg")
	check(main.grabber.held == limb and main.grabber.held_buddy == null, "held as an object")
	check(buddy.state != Buddy.State.GRABBED, "the Buddy isn't grabbed")
	main.grabber.release()
	return true


func test_no_legs_no_standing() -> bool:
	buddy.sever(&"leg_l")
	buddy.sever(&"leg_r")
	await _seconds(4.0)
	check(not buddy.can_stand(), "can't stand")
	check_eq(buddy.state, Buddy.State.RAGDOLL, "lies there")
	main.respawn()
	await frames(1)
	check_eq(main.buddy.part_list.size(), 6, "respawn brings every part back")
	return true


func test_grenade_explodes() -> bool:
	var grenade := main.spawn_object(&"grenade", buddy.torso.global_position + Vector2(110, -60))
	check(is_equal_approx(grenade.fuse, 3.0), "3 second fuse")
	grenade.fuse = 0.3
	await _seconds(0.6)
	check(not is_instance_valid(grenade), "grenade went off")
	check(_sources().has(&"explosion"), "explosion hit reported")
	check(buddy.health < Buddy.MAX_HEALTH - 15.0, "hurt (%.1f)" % buddy.health)
	check(main.room.decals.stained_samples() > 0, "scorched the room")
	return true


func test_chain_reaction() -> bool:
	var first := main.spawn_object(&"grenade", Vector2(300, 700))
	var second := main.spawn_object(&"grenade", Vector2(420, 700))
	second.fuse = 30.0
	first.fuse = 0.2
	await _seconds(1.0)
	check(not is_instance_valid(first) and not is_instance_valid(second), "one set off the other")
	return true


func test_dynamite_takes_the_leg() -> bool:
	var leg: BuddyPart = buddy.parts[&"leg_l"]
	_use("dynamite", leg.global_position)
	check_eq(get_tree().get_nodes_in_group(&"explosive").size(), 1, "stuck on")
	await _seconds(3.0)
	check(not buddy.parts.has(&"leg_l"), "leg blown off")
	check(not buddy.can_stand(), "can't stand on one leg")
	return true


func test_landmine() -> bool:
	_use("landmine", Vector2(buddy.torso.global_position.x, 500))
	await _seconds(2.0)
	check(get_tree().get_nodes_in_group(&"explosive").is_empty(), "stepped on and went off")
	check(_sources().has(&"explosion"), "it hurt")
	return true


func test_pistol() -> bool:
	Game.select_tool("pistol")
	tools.press(buddy.torso.global_position)
	for _step in int(0.7 * HZ):
		tools.cursor = buddy.torso.global_position
		await physics_frames(1)
	tools.release(tools.cursor)
	var shots := hits.filter(func(hit: Dictionary) -> bool: return hit["source"] == &"pistol")
	check(shots.size() >= 3, "kept firing while held (%d hits)" % shots.size())
	main.clean_up()
	_use("pistol", Vector2(300, 200))
	check(main.room.decals.is_stained(Vector2(300, 200)), "a miss leaves a bullet hole")
	return true


func test_rocket() -> bool:
	_use("rocket", buddy.torso.global_position)
	await _seconds(2.0)
	check(_sources().has(&"explosion"), "rocket hit (%s)" % [_sources()])
	return true


func test_mini_nuke() -> bool:
	_use("mini_nuke", buddy.head.global_position)
	await _seconds(3.0)
	check(_sources().has(&"explosion"), "nuke went off")
	check(buddy.health < 80.0 or buddy.is_knocked_out, "devastating (%.1f)" % buddy.health)
	return true


func test_lightning() -> bool:
	_use("lightning", buddy.torso.global_position + Vector2(60, -60))
	check(buddy.shock_time > 0.0, "electrocuted")
	check(_sources().has(&"lightning"), "hit reported")
	check(buddy.health < Buddy.MAX_HEALTH - 20.0, "hurt (%.1f)" % buddy.health)
	check(not buddy.can_stand(), "twitching on the ground")
	main.clean_up()
	_use("lightning", Vector2(200, 200))
	check(main.room.decals.stained_samples() > 0, "a miss scorches the floor")
	return true


func test_ignite() -> bool:
	_use("ignite", buddy.torso.global_position)
	check(buddy.burn_time > 0.0, "on fire")
	await _seconds(2.0)
	check(buddy.health < Buddy.MAX_HEALTH - 10.0, "burning hurts (%.1f)" % buddy.health)
	var soot := false
	for part in buddy.part_list:
		for mark: Array in part.marks:
			soot = soot or mark[2] == BuddyPart.Mark.SOOT
	check(soot, "leaves soot")
	check_eq(main.room.decals.stained_samples(), 0, "fire doesn't bleed")
	await _seconds(5.0)
	check_eq(buddy.burn_time, 0.0, "burns out")
	return true


func test_freeze() -> bool:
	_use("freeze", buddy.torso.global_position)
	check(buddy.frozen_time > 0.0, "frozen")
	await _seconds(1.0)
	check(not buddy.can_stand() and buddy.state == Buddy.State.RAGDOLL, "a stiff statue")
	var info := buddy.take_hit({"part": &"torso", "force": 3000.0, "position": buddy.torso.global_position})
	check(info.get("shattering", false), "hits on ice are worse")
	check(is_equal_approx(info["damage"], Buddy.damage_for(&"torso", 3000.0) * Buddy.FROZEN_DAMAGE), "x1.5 damage")
	buddy.ignite(1.0)
	check_eq(buddy.frozen_time, 0.0, "fire thaws it")
	return true


func test_frozen_knockout_shatters() -> bool:
	var shattered := [false]
	var on_shatter := func() -> void: shattered[0] = true
	Events.buddy_shattered.connect(on_shatter)
	var old := buddy
	buddy.freeze(6.0)
	buddy.take_hit({"part": &"torso", "force": 3000.0, "damage": 500.0, "position": buddy.torso.global_position})
	Events.buddy_shattered.disconnect(on_shatter)
	check(shattered[0], "shatter event")
	await frames(2)
	check(not is_instance_valid(old), "the frozen Buddy is gone")
	var chunks := get_tree().get_nodes_in_group(&"debris").filter(func(node: Node) -> bool: return node is IceChunk)
	check(chunks.size() >= 10, "broke into ice chunks (%d)" % chunks.size())
	check(main.buddy == null, "nobody home for a moment")
	await _seconds(Sandbox.SHATTER_RESPAWN + 0.2)
	check(main.buddy != null and main.buddy.part_list.size() == 6, "a new Buddy arrives")
	check(main.buddy.has_meta(&"reformed"), "and knows it was reformed")
	await _seconds(IceChunk.MELT_AFTER + IceChunk.MELT_TIME)
	check(get_tree().get_nodes_in_group(&"debris").filter(func(node: Node) -> bool: return node is IceChunk).is_empty(), "the ice melts away")
	return true


func test_knockout_without_ice_does_not_shatter() -> bool:
	buddy.take_hit({"part": &"torso", "force": 3000.0, "damage": 500.0, "position": buddy.torso.global_position})
	await frames(2)
	check(is_instance_valid(buddy) and buddy.is_knocked_out and not buddy.is_shattered, "just knocked out")
	return true


func test_black_hole() -> bool:
	var spot := buddy.torso.global_position + Vector2(450, -200)
	var ball := main.spawn_object(&"ball", spot + Vector2(-150, 0))
	var start := buddy.torso.global_position.distance_to(spot)
	_use("black_hole", spot)
	await _seconds(1.5)
	check(buddy.torso.global_position.distance_to(spot) < start - 100.0, "pulled the Buddy in")
	check(not is_instance_valid(ball), "swallowed the ball")
	await _seconds(4.0)
	check(get_tree().get_nodes_in_group(&"black_holes").is_empty(), "collapsed after a while")
	check(buddy.part_list.size() == 6, "never swallows the Buddy")
	return true


func test_telekinesis() -> bool:
	Game.select_tool("telekinesis")
	var start := buddy.torso.global_position
	tools.press(start)
	check(buddy.levitated, "lifted")
	for step in HZ:
		tools.cursor = start + Vector2(0, -2.5 * step)
		await physics_frames(1)
	check(buddy.torso.global_position.y < start.y - 150.0, "carried up (%.0f)" % (start.y - buddy.torso.global_position.y))
	tools.release(tools.cursor)
	check(not buddy.levitated, "let go")
	check_eq(buddy.state, Buddy.State.RAGDOLL, "falls")
	return true


func test_switching_tools_lets_go() -> bool:
	Game.select_tool("telekinesis")
	tools.press(buddy.torso.global_position)
	check(buddy.levitated, "lifted")
	Game.select_tool("hand")
	check(not buddy.levitated, "switching tools drops it")
	check(tools.active == null, "nothing active")
	return true


func test_object_cap() -> bool:
	for index in Sandbox.MAX_OBJECTS + 10:
		main.spawn_object(&"ball", Vector2(200 + (index % 20) * 70, 200 + (index / 20) * 90))
	await frames(2)
	var alive := 0
	for node in main.objects:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			alive += 1
	check(alive <= Sandbox.MAX_OBJECTS, "capped at %d (%d)" % [Sandbox.MAX_OBJECTS, alive])
	return true


func test_tools_survive_abuse() -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var ids := ["slap", "brick", "anvil", "grenade", "pistol", "rocket", "lightning", "ignite", "freeze", "black_hole"]
	for round_index in 16:
		var target := buddy.torso.global_position + Vector2(rng.randf_range(-200, 200), rng.randf_range(-200, 50))
		_use(ids[round_index % ids.size()], target)
		main.grabber.release()
		await physics_frames(rng.randi_range(30, 90))
	await _seconds(4.0)
	for part in buddy.part_list:
		check(part.global_position.is_finite(), "%s finite" % part.part_name)
		check(main.room.interior().grow(5.0).has_point(part.global_position), "%s inside" % part.part_name)
	return true


func _use(tool_id: String, at: Vector2) -> void:
	check(Game.select_tool(tool_id), "selected %s" % tool_id)
	tools.cursor = at
	check(tools.press(at), "%s took the click" % tool_id)
	if tools.active != null:
		tools.release(at)


func _swipe(tool_id: String, from: Vector2, to: Vector2, seconds: float) -> void:
	Game.select_tool(tool_id)
	tools.press(from)
	var steps := int(seconds * HZ)
	for step in steps + 1:
		tools.cursor = from.lerp(to, float(step) / steps)
		await physics_frames(1)
	tools.release(to)


func _sources() -> Array:
	return hits.map(func(hit: Dictionary) -> StringName: return hit.get("source", &""))


func _on_hit(info: Dictionary) -> void:
	hits.append(info)


func _on_interacted(kind: StringName, _part: StringName) -> void:
	kinds.append(kind)


func _seconds(seconds: float) -> void:
	await physics_frames(int(seconds * HZ))
