extends TestSuite
## Milestone 7: stats, achievements, daily challenges, prestige and minigames.
## Run with --fixed-fps 120.

const MAIN_SCENE := preload("res://scenes/main.tscn")
const ZombieModeScript := preload("res://scripts/minigames/zombie_mode.gd")
const HZ := 120

var main: Sandbox
var unlocked: Array = []


func before_each() -> void:
	reset_game("goals")
	Game.date_override = "2026-11-07"
	unlocked.clear()
	Events.achievement_unlocked.connect(_on_unlocked)


func after_each() -> void:
	Events.achievement_unlocked.disconnect(_on_unlocked)
	Game.date_override = ""
	if main != null and is_instance_valid(main):
		main.minigames.stop()
		main.queue_free()
		main = null
	await frames(1)
	Engine.time_scale = 1.0


func test_achievement_data_is_sound() -> bool:
	check_eq(GoalData.ACHIEVEMENTS.size(), 24, "24 achievements")
	for achievement_id: String in GoalData.ACHIEVEMENTS:
		var spec: Array = GoalData.ACHIEVEMENTS[achievement_id]
		check_eq(spec.size(), 5, "%s complete" % achievement_id)
		check(float(spec[3]) > 0.0 and int(spec[4]) > 0, "%s has a goal and reward" % achievement_id)
	return true


func test_stats_add_up_or_keep_the_best() -> bool:
	Game.record("throws")
	Game.record("throws")
	check_eq(Game.profile.stats["throws"], 2.0, "throws add up")
	Game.record("biggest_hit", 3000.0)
	Game.record("biggest_hit", 1000.0)
	check_eq(Game.profile.stats["biggest_hit"], 3000.0, "the biggest hit keeps the best")
	return true


func test_achievement_unlocks_once_and_pays() -> bool:
	var before := Game.profile.money
	Game.record("throws")
	check(unlocked.has(&"first_throw"), "Yeet unlocked")
	check(Game.profile.achievements.has("first_throw"), "remembered")
	check_eq(Game.profile.money, before + 50, "paid its reward")
	Game.record("throws")
	check_eq(unlocked.count(&"first_throw"), 1, "only once")
	Game.load_profile()
	Game.date_override = "2026-11-07"
	check(Game.profile.achievements.has("first_throw"), "saved")
	return true


func test_owned_counts_unlock_achievements() -> bool:
	Game.unlock_all_tools()
	Game.check_achievements()
	check(unlocked.has(&"tools_5") and unlocked.has(&"tools_all"), "tool collection achievements")
	return true


func test_rewards_do_not_count_as_earnings() -> bool:
	Game.earn(9990, &"test")
	Game.earn(20, &"test")
	check(unlocked.has(&"earned_10k"), "Ten Grand")
	check(Game.profile.stats["earned"] < 10100.0, "the 500 reward wasn't counted (%.0f)" % Game.profile.stats["earned"])
	return true


func test_daily_is_the_same_all_day_and_new_tomorrow() -> bool:
	var first: Array = Game.daily()["challenges"].duplicate(true)
	check_eq(first.size(), GoalData.DAILY_COUNT, "three challenges")
	Game.profile.daily = {}
	check_eq(Game.daily()["challenges"], first, "same date, same challenges")
	var tiers: Array = first.map(func(challenge: Dictionary) -> int: return GoalData.DAILIES[challenge["id"]][2].find(challenge["goal"]))
	check_eq(tiers, [0, 1, 2], "easy, medium, hard")
	Game.date_override = "2026-11-08"
	var second: Array = Game.daily()["challenges"]
	check(second != first, "a new day brings new challenges")
	return true


func test_daily_needs_owned_tools() -> bool:
	for date_index in 20:
		var daily := Goals.make_daily("2026-12-%02d" % (date_index + 1), ["hand"] as Array[String])
		for challenge: Dictionary in daily["challenges"]:
			check(String(GoalData.DAILIES[challenge["id"]][4]).is_empty(), "%s doesn't need a tool you lack" % challenge["id"])
	return true


func test_completing_a_daily_pays_once() -> bool:
	Game.profile.daily = {"date": Game.today(), "tools_today": [], "challenges": [
		{"id": "throws", "goal": 3, "reward": 200, "progress": 0.0, "done": false}]}
	var before := Game.profile.money
	for _index in 3:
		Game.record("throws")
	var challenge: Dictionary = Game.daily()["challenges"][0]
	check(challenge["done"], "done after 3 throws")
	check(Game.profile.money >= before + 200, "paid")
	var after := Game.profile.money
	Game.record("throws")
	check_eq(Game.profile.money, after, "no second payout")
	return true


func test_different_tools_today() -> bool:
	Game.profile.daily = {"date": Game.today(), "tools_today": [], "challenges": [
		{"id": "tools", "goal": 3, "reward": 300, "progress": 0.0, "done": false}]}
	for tool_id in ["slap", "slap", "bat", "grenade"]:
		Game.note_tool_used(tool_id)
	check(Game.daily()["challenges"][0]["done"], "three different tools")
	check_eq(Game.profile.stats.get("used_slap"), 2.0, "per-tool use counts")
	return true


func test_prestige() -> bool:
	check(not Game.can_prestige(), "not at first")
	check(not Game.prestige(), "refused")
	Game.earn(Game.PRESTIGE_BASE, &"test")
	Game.buy_tool("ball")
	Game.upgrade_tool("ball")
	Game.buy_look(&"color", "gold")
	check(Game.can_prestige(), "allowed after earning enough")
	var achievements := Game.profile.achievements.size()
	check(Game.prestige(), "prestiged")
	check_eq(Game.profile.prestige_count, 1, "level 1")
	check_eq(Game.profile.money, 0, "money gone")
	check_eq(Game.profile.owned_tools, ["hand"] as Array[String], "tools gone")
	check_eq(Game.tool_level("ball"), 0, "upgrades gone")
	check_eq(Game.equipped_look(&"color"), "gold", "looks kept")
	check_eq(Game.profile.achievements.size(), achievements, "achievements kept")
	check_eq(Game.reward_multiplier(), 1.25, "pays x1.25")
	check_eq(Game.prestige_goal(), Game.PRESTIGE_BASE * 2, "the next one needs more")
	check(not Game.can_prestige(), "and starts from zero")
	return true


func test_prestige_bonus_applies_to_hits() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await physics_frames(4 * HZ)
	Game.profile.prestige_count = 2
	var economy_before := Game.profile.money
	main.buddy.notice(&"poke", &"torso")
	check(Game.profile.money - economy_before >= 4, "x1.5 on a 3 $$$ poke (%d)" % (Game.profile.money - economy_before))
	return true


func test_zombie_mode() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)
	Game.unlock_all_tools()
	var game: Minigame = main.minigames.start(&"zombies")
	await physics_frames(2)
	check(main.buddy == null, "your fwend sits this one out")
	var horde: Array = game.zombies
	check_eq(horde.size(), 5, "five zombies")
	for zombie: Buddy in horde:
		check(zombie.is_zombie and zombie.chase and zombie.skin_id == "zombie", "a proper zombie")
	await physics_frames(3 * HZ)
	main.respawn()
	check(main.buddy == null, "respawn can't bring your fwend back mid-game")
	for zombie: Buddy in horde.duplicate():
		zombie.take_hit({"part": &"head", "force": 1000.0, "damage": 500.0, "position": zombie.head.global_position})
	check_eq(game.kills, 5, "five kills")
	await physics_frames(int((ZombieModeScript.NEXT_WAVE_DELAY + 0.3) * HZ))
	check_eq(game.wave, 2, "the next wave arrives")
	check_eq(game.zombies.size(), 5, "five more")
	await physics_frames(int(ZombieModeScript.CORPSE_TIME * HZ))
	check_eq(get_tree().get_nodes_in_group(&"zombies").size(), 5, "the dead crumble away")
	var frozen: Buddy = game.zombies[0]
	frozen.freeze(5.0)
	frozen.take_hit({"part": &"torso", "force": 1000.0, "damage": 500.0, "position": frozen.torso.global_position})
	await frames(2)
	check_eq(game.kills, 6, "a shattered zombie counts too")
	check(main.buddy == null, "shattering a zombie doesn't bring yours back")
	var results: Array = []
	var on_finish := func(result: Dictionary) -> void: results.append(result)
	Events.minigame_finished.connect(on_finish)
	game.time_left = 0.01
	await physics_frames(3)
	Events.minigame_finished.disconnect(on_finish)
	check_eq(results.size(), 1, "finished")
	if not results.is_empty():
		check_eq(results[0]["score"], 6.0, "scored by kills")
		check_eq(results[0]["reward"], 6 * ZombieModeScript.PAY_PER_KILL, "paid per kill")
	await frames(2)
	check(get_tree().get_nodes_in_group(&"zombies").is_empty(), "the horde is gone")
	check(main.buddy != null and not main.buddy.is_zombie, "your fwend is back")
	return true


func test_target_toss_counts_hits() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)
	var game: Minigame = main.minigames.start(&"toss")
	await physics_frames(3 * HZ)
	var board: TargetBoard = game.target
	var before := board.position
	main.buddy.launch(Vector2.ZERO)
	main.buddy.torso.global_position = board.position
	await physics_frames(2)
	check_eq(game.score, 1.0, "a hit")
	check(board.position != before, "the target moved")
	game.time_left = 0.01
	await physics_frames(3)
	check(Game.profile.best_scores.has("toss"), "scored")
	check(not main.tools.locked, "tools unlocked")
	return true


func test_frenzy_counts_damage_and_cant_ko() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)
	var game: Minigame = main.minigames.start(&"frenzy")
	await physics_frames(HZ)
	main.buddy.take_hit({"part": &"torso", "force": 1000.0, "damage": 500.0, "position": main.buddy.torso.global_position})
	check_eq(game.score, 500.0, "damage counted")
	check(not main.buddy.is_knocked_out, "can't be knocked out")
	check_eq(main.buddy.health, Buddy.MAX_HEALTH, "health untouched")
	main.minigames.stop()
	check(not main.buddy.invulnerable, "normal again after")
	return true


func test_goals_window() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)
	var panel: GoalsPanel = main.hud.goals_panel
	main.hud.goals_button.pressed.emit()
	check(panel.visible, "opens")
	var screen := Rect2(Vector2.ZERO, main.hud.root.size)
	for page in GoalsPanel.PAGES.size():
		panel.show_page(page)
		await frames(2)
		check(screen.encloses(panel.get_rect()), "page %d fits (%s)" % [page, panel.get_rect()])
	main.hud.minigames_button.pressed.emit()
	var games: MinigamesPanel = main.hud.minigames_panel
	check(games.visible and not panel.visible, "Minigames has its own button and window")
	await frames(2)
	check(screen.encloses(games.get_rect()), "the minigames window fits (%s)" % games.get_rect())
	var started: Array = []
	var on_start := func(minigame_id: StringName) -> void: started.append(minigame_id)
	Events.minigame_started.connect(on_start)
	games.minigame_chosen.emit(&"frenzy")
	Events.minigame_started.disconnect(on_start)
	check_eq(started, [&"frenzy"], "Play starts a minigame")
	main.hud.minigame_quit.emit()
	check(not main.minigames.is_running(), "Quit stops it")
	return true


func test_tracker_counts_real_events() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await physics_frames(4 * HZ)
	main.buddy.take_hit({"part": &"torso", "force": 3200.0, "position": main.buddy.torso.global_position})
	main.explode(Vector2(300, 300), 200.0, 1000.0, 0.0, 0.0)
	check(Game.profile.stats.get("hits", 0.0) >= 1.0, "hits")
	check(Game.profile.stats.get("biggest_hit", 0.0) >= 3200.0, "biggest hit")
	check_eq(Game.profile.stats.get("explosions", 0.0), 1.0, "explosions")
	return true


func test_respawning_leaks_no_listeners() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)
	var before := Events.looks_changed.get_connections().size()
	for _index in 5:
		main.respawn()
		await frames(1)
	check_eq(Events.looks_changed.get_connections().size(), before, "old Buddies stop listening when freed")
	main.queue_free()
	main = null
	await frames(2)
	check(Events.exploded.get_connections().is_empty(), "a freed sandbox leaves no listeners behind")
	return true


func _on_unlocked(achievement_id: StringName) -> void:
	unlocked.append(achievement_id)