extends TestSuite
## Game: earning, spending, saving and loading through the real autoload.

var _events: Array = []


func before_each() -> void:
	_events.clear()


func test_fresh_folder_starts_clean() -> bool:
	reset_game("game_fresh")
	check_eq(Game.profile.money, 0, "no money")
	check(Game.saving_enabled, "saving allowed")
	check_eq(Game.load_notice, "", "no notice")
	return true


func test_earn_and_spend_emit_events() -> bool:
	reset_game("game_money")
	var on_earned := func(amount: int, reason: StringName) -> void: _events.append(["earned", amount, reason])
	var on_changed := func(total: int) -> void: _events.append(["changed", total])
	Events.money_earned.connect(on_earned)
	Events.money_changed.connect(on_changed)
	Game.earn(250, &"test")
	Game.earn(-5, &"test")
	check_eq(Game.spend(100, &"shop"), true, "can afford")
	check_eq(Game.spend(1000, &"shop"), false, "can't afford")
	Events.money_earned.disconnect(on_earned)
	Events.money_changed.disconnect(on_changed)
	check_eq(Game.profile.money, 150, "balance")
	check_eq(Game.profile.lifetime_money, 250, "lifetime ignores spending")
	check_eq(_events, [["earned", 250, &"test"], ["changed", 250], ["changed", 150]], "events")
	check(Game.is_dirty(), "changes need saving")
	return true


func test_save_and_load_round_trip() -> bool:
	reset_game("game_round_trip")
	Game.earn(777, &"test")
	Game.profile.owned_tools.append("brick")
	Game.select_tool("brick")
	Game.set_setting("sfx_volume", 0.3)
	check(Game.save_now(), "saved")
	check(not Game.is_dirty(), "clean after save")
	Game.profile = Profile.new()
	Game.load_profile()
	check_eq(Game.profile.money, 777, "money")
	check_eq(Game.profile.selected_tool, "brick", "selected tool")
	check_eq(Game.profile.settings["sfx_volume"], 0.3, "setting")
	return true


func test_selecting_unowned_tool_is_refused() -> bool:
	reset_game("game_select")
	check_eq(Game.select_tool("mini_nuke"), false, "not owned")
	check_eq(Game.profile.selected_tool, "hand", "still the hand")
	return true


func test_newer_save_is_never_overwritten() -> bool:
	var folder := reset_game("game_newer")
	var store := SaveStore.new(folder)
	store.write({"money": 50}, SaveMigrations.CURRENT_VERSION + 1, 1000)
	var before := FileAccess.get_file_as_string(store.path(SaveStore.MAIN))
	Game.load_profile()
	check(not Game.saving_enabled, "saving disabled")
	check(not Game.load_notice.is_empty(), "player is told")
	Game.earn(5, &"test")
	check_eq(Game.save_now(), false, "save refused")
	check_eq(FileAccess.get_file_as_string(store.path(SaveStore.MAIN)), before, "file untouched")
	return true


func test_unreadable_save_is_never_overwritten() -> bool:
	var folder := reset_game("game_corrupt")
	write_text(folder.path_join(SaveStore.MAIN), "scrambled")
	Game.load_profile()
	check(not Game.saving_enabled, "saving disabled")
	check_eq(Game.save_now(), false, "save refused")
	check_eq(FileAccess.get_file_as_string(folder.path_join(SaveStore.MAIN)), "scrambled", "file untouched")
	return true


func test_recovered_save_tells_the_player() -> bool:
	var folder := reset_game("game_recover")
	var store := SaveStore.new(folder)
	store.write({"money": 11}, 1, 1000)
	store.write({"money": 22}, 1, 1001)
	write_text(store.path(SaveStore.MAIN), "scrambled")
	Game.load_profile()
	check_eq(Game.profile.money, 11, "previous copy used")
	check(Game.saving_enabled, "saving still allowed")
	check(Game.load_notice.contains("backup"), "notice")
	return true


func test_reset_keeps_settings() -> bool:
	reset_game("game_reset")
	Game.earn(500, &"test")
	Game.set_setting("master_volume", 0.4)
	Game.reset_progress()
	check_eq(Game.profile.money, 0, "money wiped")
	check_eq(Game.profile.settings["master_volume"], 0.4, "settings kept")
	Game.load_profile()
	check_eq(Game.profile.money, 0, "wipe was saved")
	return true


func test_audio_buses_follow_settings() -> bool:
	reset_game("game_audio")
	check(AudioServer.get_bus_index("Music") != -1, "music bus")
	check(AudioServer.get_bus_index("SFX") != -1, "sfx bus")
	Game.set_setting("music_volume", 0.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "zero mutes")
	Game.set_setting("music_volume", 1.0)
	check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "unmuted")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))) < 0.01, "full volume is 0 dB")
	return true


func test_tool_catalog_has_the_hand() -> bool:
	var hand := ToolCatalog.get_tool("hand")
	check(hand != null, "hand loaded from data/tools")
	if hand != null:
		check_eq(hand.category, ToolDef.Category.HAND, "category")
		check_eq(hand.price, 0, "free")
	return true
