extends TestSuite
## Milestone 8: release QA. A fresh save, a fully progressed save, the developer
## tools, every minigame to the end, every tool from a maxed save, and a
## performance budget under heavy load. Run with --fixed-fps 120.

const MAIN_SCENE := preload("res://scenes/main.tscn")
const HZ := 120

var main: Sandbox
var folder := ""


func before_each() -> void:
	folder = reset_game("release")


func after_each() -> void:
	if main != null and is_instance_valid(main):
		main.queue_free()
		main = null
	await frames(1)
	Engine.time_scale = 1.0


func _start() -> void:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	main.tools.manual_cursor = true
	main.grabber.manual_target = true
	await physics_frames(3 * HZ)


func test_fresh_save_starts_clean() -> bool:
	check_eq(Game.profile.money, 0, "no $$$")
	check_eq(Game.profile.owned_tools, ["hand"] as Array[String], "only the Hand")
	check_eq(Game.profile.prestige_count, 0, "no prestige")
	check(Game.profile.achievements.is_empty(), "no achievements")
	await _start()
	check(main.buddy != null and main.buddy.part_list.size() == 6, "a whole fwend")
	for tool in ToolCatalog.all():
		var status := Game.tool_status(tool.id)
		if tool.id == "hand":
			check_eq(status, &"owned", "hand owned")
		elif tool.prestige:
			check_eq(status, &"prestige_locked", "%s waits for a prestige" % tool.id)
		else:
			check(status == &"too_expensive" or status == &"locked", "%s not free (%s)" % [tool.id, status])
	return true


func test_full_save_round_trip() -> bool:
	Game.max_everything()
	var before := Game.profile.to_dict()
	Game.use_folder(folder)
	var after := Game.profile.to_dict()
	for key: String in ["money", "lifetime_money", "owned_tools", "tool_upgrades", "owned_skins", "owned_colors",
			"owned_backgrounds", "achievements", "prestige_count", "prestige_unlocks", "best_scores", "stats"]:
		check_eq(_normal(after.get(key)), _normal(before.get(key)), "%s survives a reload" % key)
	check_eq(Game.profile.owned_tools.size(), ToolCatalog.all().size(), "every tool owned")
	check_eq(Game.profile.achievements.size(), GoalData.ACHIEVEMENTS.size(), "every achievement")
	check_eq(Game.reward_multiplier(), 1.0 + Game.PRESTIGE_BONUS * 5, "prestige 5 pays more")
	await _start()
	# Every window and tab opens on a maxed save.
	var shop := main.hud.shop_panel
	shop.show()
	for index in shop.tabs.size():
		shop.show_category(index)
		await frames(2)
		check(shop.grid.get_child_count() > 0, "shop tab %d has cards" % index)
	shop.hide()
	main.hud.goals_panel.show()
	for page in 3:
		main.hud.goals_panel.show_page(page)
		await frames(2)
	main.hud.goals_panel.hide()
	main.hud.minigames_panel.show()
	await frames(2)
	main.hud.minigames_panel.hide()
	for slot in main.hud.slots:
		check(slot.usable, "%s slot usable" % slot.tool_id)
	# Prestige from a maxed save keeps the prestige weapons.
	Game.ready_prestige()
	check(Game.prestige(), "can prestige again")
	var kept := 0
	for tool in ToolCatalog.all():
		if tool.prestige and Game.owns_tool(tool.id):
			kept += 1
	check_eq(kept, 15, "all 15 prestige weapons kept")
	check_eq(Game.tool_level("tornado"), Game.MAX_UPGRADE, "with their upgrades")
	check(not Game.owns_tool("katana"), "base tools reset")
	return true


## JSON text with sorted keys and every number as a float, so a value compares
## equal to itself after a save and load.
static func _normal(value: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(value)), "", true)


func test_corrupt_full_save_falls_back() -> bool:
	Game.max_everything()
	Game.save_now()
	var path := folder.path_join("save.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{ this is not json")
	file.close()
	Game.use_folder(folder)
	check(Game.profile.owned_tools.size() > 1, "recovered from the previous save (%d tools)" % Game.profile.owned_tools.size())
	return true


func test_dev_tools() -> bool:
	await _start()
	var panel := main.hud.dev_panel
	check(panel != null and not panel.visible, "dev panel exists, hidden")
	var press := func(label: String) -> void: (panel.buttons[label] as Button).pressed.emit()
	press.call("+$$$ 10,000")
	check(Game.profile.money >= 10000, "+10k (plus any achievement it set off)")
	press.call("Unlock every tool (incl. prestige)")
	check_eq(Game.profile.owned_tools.size(), ToolCatalog.all().size(), "all tools")
	press.call("Max every owned tool's upgrades")
	check_eq(Game.tool_level("rocket"), Game.MAX_UPGRADE, "upgrades maxed")
	press.call("Unlock every look")
	check_eq(Game.owned_looks(&"skin").size(), Cosmetics.SKINS.size(), "all skins")
	press.call("Unlock every achievement")
	check_eq(Game.profile.achievements.size(), GoalData.ACHIEVEMENTS.size(), "all achievements")
	press.call("Earn enough to prestige")
	check(Game.can_prestige(), "prestige ready")
	return true


func test_every_minigame_finishes() -> bool:
	Game.unlock_all_tools()
	await _start()
	for minigame_id: StringName in Minigames.LIST:
		var results: Array = []
		var on_finish := func(result: Dictionary) -> void: results.append(result)
		Events.minigame_finished.connect(on_finish)
		var game := main.minigames.start(minigame_id)
		await physics_frames(2 * HZ)
		game.score = 3.0
		game.time_left = 0.05
		await physics_frames(HZ)
		Events.minigame_finished.disconnect(on_finish)
		check_eq(results.size(), 1, "%s finished once" % minigame_id)
		check(not main.minigames.is_running(), "%s stopped" % minigame_id)
		check(main.buddy != null and is_instance_valid(main.buddy) and not main.buddy.is_zombie, "%s gave your fwend back" % minigame_id)
		check(float(Game.profile.best_scores.get(String(minigame_id), 0.0)) >= 3.0, "%s best saved" % minigame_id)
	check(main.get_tree().get_nodes_in_group(&"zombies").is_empty(), "no zombies left over")
	return true


func test_every_tool_from_a_maxed_save() -> bool:
	Game.max_everything()
	await _start()
	var errors_before := main.get_tree().get_nodes_in_group(&"buddies").size()
	check_eq(errors_before, 1, "one buddy")
	for tool in ToolCatalog.all():
		if tool.id == "hand":
			continue
		if main.buddy == null or not is_instance_valid(main.buddy) or main.buddy.part_list.size() < 6:
			main.respawn()
			await physics_frames(HZ)
		check(Game.select_tool(tool.id), "select %s" % tool.id)
		var at := main.buddy.torso.global_position
		main.tools.cursor = at
		check(main.tools.press(at), "%s used" % tool.id)
		if main.tools.active != null:
			for _step in int(0.5 * HZ):
				if main.buddy != null and is_instance_valid(main.buddy):
					main.tools.cursor = main.buddy.torso.global_position
				await physics_frames(1)
			main.tools.release(main.tools.cursor)
		main.grabber.release()
		await physics_frames(int(0.5 * HZ))
	await physics_frames(6 * HZ)
	check(main.buddy != null and is_instance_valid(main.buddy), "a fwend survives the whole arsenal")
	for part in main.buddy.part_list:
		check(part.global_position.is_finite() and main.room.interior().grow(5.0).has_point(part.global_position), "%s in the room" % part.part_name)
	main.clean_up(true)
	await physics_frames(2)
	check(main.objects.is_empty(), "clean up empties the room")
	return true


func test_performance_under_load() -> bool:
	Game.unlock_all_tools()
	await _start()
	var game := main.minigames.start(&"zombies")
	await physics_frames(HZ)
	for index in Sandbox.MAX_OBJECTS:
		main.spawn_object(&"brick" if index % 2 == 0 else &"ball", Vector2(200 + (index % 20) * 80, 150 + (index / 20) * 120))
	Game.select_tool("tornado")
	main.tools.press(Vector2(960, 700))
	Game.select_tool("black_hole")
	main.tools.press(Vector2(700, 500))
	await physics_frames(HZ)
	var worst := 0.0
	var total := 0.0
	var samples := 2 * HZ
	for _step in samples:
		var started := Time.get_ticks_usec()
		await physics_frames(1)
		var took := (Time.get_ticks_usec() - started) / 1000.0
		total += took
		worst = maxf(worst, took)
	var average := total / samples
	print("    load: 5 zombies, %d objects, tornado, black hole: avg %.2f ms, worst %.2f ms per frame" % [Sandbox.MAX_OBJECTS, average, worst])
	check(average < 8.3, "average frame under the 120 Hz budget (%.2f ms)" % average)
	main.minigames.stop()
	game = null
	return true
