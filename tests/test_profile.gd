extends TestSuite
## Profile: defaults, JSON round trips and defending against bad data.


func test_defaults() -> bool:
	var profile := Profile.new()
	check_eq(profile.money, 0, "money")
	check_eq(profile.owned_tools, ["hand"] as Array[String], "starts with the hand")
	check_eq(profile.selected_tool, "hand", "hand selected")
	check_eq(profile.settings, Profile.DEFAULT_SETTINGS, "settings")
	return true


func test_json_round_trip() -> bool:
	var profile := Profile.new()
	profile.money = 1234
	profile.lifetime_money = 5000
	profile.owned_tools.append("brick")
	profile.selected_tool = "brick"
	profile.tool_upgrades = {"brick": 2}
	profile.stats = {"limbs_lost": 7}
	profile.best_scores = {"launch": 812.5}
	profile.prestige_count = 1
	profile.settings["music_volume"] = 0.25
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(profile.to_dict()))
	var loaded := Profile.from_dict(parsed)
	check_eq(loaded.money, 1234, "money")
	check_eq(loaded.lifetime_money, 5000, "lifetime")
	check_eq(loaded.owned_tools, ["hand", "brick"] as Array[String], "tools")
	check_eq(loaded.selected_tool, "brick", "selection")
	check_eq(int(loaded.tool_upgrades["brick"]), 2, "upgrades")
	check_eq(int(loaded.stats["limbs_lost"]), 7, "stats")
	check_eq(loaded.best_scores["launch"], 812.5, "scores")
	check_eq(loaded.prestige_count, 1, "prestige")
	check_eq(loaded.settings["music_volume"], 0.25, "settings")
	return true


func test_bad_values_fall_back() -> bool:
	var loaded := Profile.from_dict({
		"money": "lots",
		"lifetime_money": -50,
		"owned_tools": "hand",
		"selected_tool": "nuke",
		"skin": "ghost",
		"buddy_color": "not a color",
		"stats": [1, 2],
		"settings": {"master_volume": 7, "fullscreen": "yes", "music_volume": -1},
	})
	check_eq(loaded.money, 0, "text money ignored")
	check_eq(loaded.lifetime_money, 0, "negative clamped")
	check_eq(loaded.owned_tools, ["hand"] as Array[String], "bad tool list")
	check_eq(loaded.selected_tool, "hand", "can't select an unowned tool")
	check_eq(loaded.skin, "classic", "can't wear an unowned skin")
	check_eq(loaded.buddy_color, Profile.new().buddy_color, "bad color")
	check_eq(loaded.stats, {}, "stats must be a table")
	check_eq(loaded.settings["master_volume"], 1.0, "volume clamped")
	check_eq(loaded.settings["music_volume"], 0.0, "volume clamped low")
	check_eq(loaded.settings["fullscreen"], false, "non-bool ignored")
	return true


func test_hand_always_owned() -> bool:
	var loaded := Profile.from_dict({"owned_tools": ["brick", "brick", 5]})
	check_eq(loaded.owned_tools, ["hand", "brick"] as Array[String], "hand added, duplicates and junk removed")
	return true


func test_unknown_keys_survive() -> bool:
	var loaded := Profile.from_dict({"money": 3, "from_the_future": {"x": 1}})
	check_eq(loaded.to_dict().get("from_the_future"), {"x": 1}, "kept for newer versions")
	return true


func test_money_format() -> bool:
	check_eq(Fmt.money(0), "$$$ 0", "zero")
	check_eq(Fmt.money(999), "$$$ 999", "small")
	check_eq(Fmt.money(1000), "$$$ 1,000", "thousand")
	check_eq(Fmt.money(1234567), "$$$ 1,234,567", "million")
	return true
