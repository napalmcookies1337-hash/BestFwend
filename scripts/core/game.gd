extends Node
## The player's profile and its save file: loads at start, autosaves, saves on quit,
## and is the one place money is earned or spent.

const SAVE_FOLDER := "user://save"
const SANDBOX_FOLDER := "user://sandbox"
const TEST_FOLDER := "user://tests/default"
const AUTOSAVE_SECONDS := 30.0
const AUDIO_BUSES := ["Music", "SFX"]

var profile := Profile.new()
var store: SaveStore
## False when the save on disk couldn't be read or is from a newer game,
## so this session never overwrites it.
var saving_enabled := true
## Shown to the player once the room is up, when loading needed explaining.
var load_notice := ""
var _dirty := false


func _ready() -> void:
	Controls.register()
	_ensure_audio_buses()
	use_folder(_choose_folder())
	var timer := Timer.new()
	timer.name = "Autosave"
	timer.wait_time = AUTOSAVE_SECONDS
	timer.autostart = true
	timer.timeout.connect(save_if_dirty)
	add_child(timer)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_if_dirty()


## Points the game at a save folder and loads it. Tests use this with throwaway folders.
func use_folder(folder: String) -> void:
	store = SaveStore.new(folder)
	load_profile()


func load_profile() -> void:
	saving_enabled = true
	load_notice = ""
	_dirty = false
	profile = Profile.new()
	var result := store.read()
	if result.has("error"):
		if result["error"] == "corrupt":
			_refuse_save("Your save file couldn't be read, so this session won't save over it.")
		apply_settings()
		return
	var version: int = result["version"]
	if version > SaveMigrations.CURRENT_VERSION:
		_refuse_save("Your save is from a newer version of Best Fwend, so this session won't save over it.")
		apply_settings()
		return
	var data := SaveMigrations.migrate(result["data"], version)
	if data.is_empty() and version != SaveMigrations.CURRENT_VERSION:
		_refuse_save("Your save couldn't be upgraded, so this session won't save over it.")
		apply_settings()
		return
	if version < SaveMigrations.CURRENT_VERSION:
		store.keep_original(version)
		_dirty = true
	profile = Profile.from_dict(data)
	if result["source"] != SaveStore.MAIN:
		load_notice = "Your save was recovered from a backup copy."
		_dirty = true
	apply_settings()


func save_now() -> bool:
	if not saving_enabled:
		return false
	var err := store.write(profile.to_dict(), SaveMigrations.CURRENT_VERSION)
	if err != OK:
		push_warning("Saving failed: %s" % error_string(err))
		return false
	_dirty = false
	Events.game_saved.emit()
	return true


func save_if_dirty() -> void:
	if _dirty:
		save_now()


func mark_dirty() -> void:
	_dirty = true


func is_dirty() -> bool:
	return _dirty


func earn(amount: int, reason: StringName) -> void:
	if amount <= 0:
		return
	profile.money += amount
	profile.lifetime_money += amount
	profile.run_earned += amount
	mark_dirty()
	Events.money_earned.emit(amount, reason)
	Events.money_changed.emit(profile.money)
	# Rewards don't count toward "earn" goals, or goals would pay for themselves.
	if reason != &"achievement" and reason != &"daily":
		record("earned", amount)


func spend(amount: int, reason: StringName) -> bool:
	if amount < 0 or amount > profile.money:
		return false
	profile.money -= amount
	mark_dirty()
	Events.money_spent.emit(amount, reason)
	Events.money_changed.emit(profile.money)
	return true


## When true every tool is usable without buying it (used before the shop existed).
const TOOLS_FREE := false
const MAX_UPGRADE := 3
## Each upgrade level adds this much power: force, blast, damage or duration.
const UPGRADE_STEP := 0.25
## Upgrades cost UPGRADE_PRICE x 2^level times the tool's price, at least this base.
const UPGRADE_PRICE := 0.6
const MIN_UPGRADE_BASE := 400


func can_use_tool(tool_id: String) -> bool:
	if ToolCatalog.get_tool(tool_id) == null:
		return false
	return TOOLS_FREE or profile.owned_tools.has(tool_id)


func owns_tool(tool_id: String) -> bool:
	return profile.owned_tools.has(tool_id)


## &"owned", &"prestige_locked" (a prestige weapon not unlocked yet), &"locked"
## (needs another tool first), &"too_expensive" or &"buyable".
func tool_status(tool_id: String) -> StringName:
	var tool := ToolCatalog.get_tool(tool_id)
	if tool == null:
		return &"locked"
	if owns_tool(tool_id):
		return &"owned"
	if tool.prestige and not profile.prestige_unlocks.has(tool_id):
		return &"prestige_locked"
	if not tool.requires.is_empty() and not owns_tool(tool.requires):
		return &"locked"
	if profile.money < tool.price:
		return &"too_expensive"
	return &"buyable"


func buy_tool(tool_id: String) -> bool:
	if tool_status(tool_id) != &"buyable":
		return false
	var tool := ToolCatalog.get_tool(tool_id)
	if not spend(tool.price, &"shop"):
		return false
	profile.owned_tools.append(tool_id)
	mark_dirty()
	Events.tool_purchased.emit(StringName(tool_id))
	Events.item_unlocked.emit(&"tool", StringName(tool_id))
	save_now()
	return true


func tool_level(tool_id: String) -> int:
	return clampi(int(profile.tool_upgrades.get(tool_id, 0)), 0, MAX_UPGRADE)


## Price of the next upgrade, or -1 when maxed out or not owned.
func upgrade_cost(tool_id: String) -> int:
	var tool := ToolCatalog.get_tool(tool_id)
	var level := tool_level(tool_id)
	if tool == null or not owns_tool(tool_id) or level >= MAX_UPGRADE:
		return -1
	return roundi(maxi(tool.price, MIN_UPGRADE_BASE) * UPGRADE_PRICE * pow(2.0, level))


func upgrade_tool(tool_id: String) -> bool:
	var cost := upgrade_cost(tool_id)
	if cost < 0 or not spend(cost, &"upgrade"):
		return false
	profile.tool_upgrades[tool_id] = tool_level(tool_id) + 1
	mark_dirty()
	Events.tool_purchased.emit(StringName(tool_id))
	save_now()
	return true


## Owned colour, skin or room ids for `kind` (&"color", &"skin", &"room").
func owned_looks(kind: StringName) -> Array[String]:
	match kind:
		&"color":
			return profile.owned_colors
		&"skin":
			return profile.owned_skins
		_:
			return profile.owned_backgrounds


## The equipped colour, skin or room id.
func equipped_look(kind: StringName) -> String:
	match kind:
		&"color":
			return Cosmetics.color_id_for(profile.buddy_color)
		&"skin":
			return profile.skin
		_:
			return profile.background


## &"equipped", &"owned", &"too_expensive" or &"buyable".
func look_status(kind: StringName, item_id: String) -> StringName:
	if equipped_look(kind) == item_id:
		return &"equipped"
	if owned_looks(kind).has(item_id):
		return &"owned"
	var item: Dictionary = Cosmetics.table(kind).get(item_id, {})
	if item.is_empty() or profile.money < int(item["price"]):
		return &"too_expensive"
	return &"buyable"


## Buys a look and puts it on straight away.
func buy_look(kind: StringName, item_id: String) -> bool:
	if look_status(kind, item_id) != &"buyable":
		return false
	if not spend(int(Cosmetics.table(kind)[item_id]["price"]), &"looks"):
		return false
	owned_looks(kind).append(item_id)
	Events.item_unlocked.emit(kind, StringName(item_id))
	equip_look(kind, item_id)
	return true


func equip_look(kind: StringName, item_id: String) -> bool:
	if not owned_looks(kind).has(item_id):
		return false
	match kind:
		&"color":
			profile.buddy_color = Cosmetics.COLORS[item_id]["hex"]
		&"skin":
			profile.skin = item_id
		_:
			profile.background = item_id
	mark_dirty()
	save_now()
	Events.looks_changed.emit(kind)
	return true


## Debug cheat and test helper: owns every tool.
func unlock_all_tools() -> void:
	for tool in ToolCatalog.all():
		if not profile.owned_tools.has(tool.id):
			profile.owned_tools.append(tool.id)
		if tool.prestige and not profile.prestige_unlocks.has(tool.id):
			profile.prestige_unlocks.append(tool.id)
	mark_dirty()
	Events.item_unlocked.emit(&"tool", &"all")


## Debug cheat and test helper: owns every colour, skin and room.
func unlock_all_looks() -> void:
	for kind: StringName in [&"color", &"skin", &"room"]:
		var owned := owned_looks(kind)
		for look_id: String in Cosmetics.table(kind):
			if not owned.has(look_id):
				owned.append(look_id)
		Events.looks_changed.emit(kind)
	mark_dirty()


## Debug cheat and test helper: every owned tool to its top upgrade.
func max_upgrades() -> void:
	for tool_id in profile.owned_tools:
		if tool_id != "hand":
			profile.tool_upgrades[tool_id] = MAX_UPGRADE
	mark_dirty()
	Events.item_unlocked.emit(&"tool", &"all")


## Debug cheat and test helper: unlocks every achievement (and pays for them).
func unlock_all_achievements() -> void:
	for achievement_id: String in GoalData.ACHIEVEMENTS:
		if not profile.achievements.has(achievement_id):
			profile.achievements[achievement_id] = {"unlocked_at": int(Time.get_unix_time_from_system())}
			Events.achievement_unlocked.emit(StringName(achievement_id))
	mark_dirty()


## Debug cheat: earns exactly what the next prestige still needs.
func ready_prestige() -> void:
	earn(maxi(prestige_goal() - profile.run_earned, 0), &"dev")


## Debug cheat and test helper: a save that has seen everything — every tool,
## upgrade, look and achievement, five prestiges and a pile of $$$.
func max_everything() -> void:
	profile.prestige_count = maxi(profile.prestige_count, 5)
	unlock_all_tools()
	max_upgrades()
	unlock_all_looks()
	unlock_all_achievements()
	for minigame_id: String in ["zombies", "toss", "frenzy"]:
		profile.best_scores[minigame_id] = maxf(float(profile.best_scores.get(minigame_id, 0.0)), 10.0)
	earn(10000000, &"dev")
	save_now()


## How much stronger upgrades make a tool: 1.0, 1.25, 1.5, 1.75.
func tool_power(tool_id: String) -> float:
	return 1.0 + UPGRADE_STEP * tool_level(tool_id)


## Applied to every payout. Each prestige adds PRESTIGE_BONUS.
func reward_multiplier() -> float:
	return 1.0 + PRESTIGE_BONUS * profile.prestige_count


# --- Goals: stats, achievements, daily challenges -----------------------------

## For tests: pretend today is this date ("YYYY-MM-DD"). Empty uses the clock.
var date_override := ""


func today() -> String:
	return date_override if not date_override.is_empty() else Time.get_date_string_from_system()


## Counts something toward stats, achievements and today's challenges. Stats in
## GoalData.MAX_STATS keep the best value; others add up.
func record(stat: String, amount := 1.0) -> void:
	var keep_max := GoalData.MAX_STATS.has(stat)
	var old := float(profile.stats.get(stat, 0.0))
	profile.stats[stat] = maxf(old, amount) if keep_max else old + amount
	mark_dirty()
	_record_daily(stat, amount, keep_max)
	check_achievements()


## Remembers that a tool was used today, for the "use N tools" challenge.
func note_tool_used(tool_id: String) -> void:
	record("used_" + tool_id)
	var tools_today: Array = daily()["tools_today"]
	if not tools_today.has(tool_id):
		tools_today.append(tool_id)
		_record_daily("tools_used", tools_today.size(), true)


func check_achievements() -> void:
	var any := false
	for achievement_id in Goals.pending_unlocks(profile):
		profile.achievements[achievement_id] = {"unlocked_at": int(Time.get_unix_time_from_system())}
		mark_dirty()
		any = true
		Events.achievement_unlocked.emit(StringName(achievement_id))
		earn(int(GoalData.ACHIEVEMENTS[achievement_id][4]), &"achievement")
	if any:
		save_now()


## Today's challenges, made fresh when the date changes.
func daily() -> Dictionary:
	if profile.daily.get("date", "") != today() or not profile.daily.has("challenges"):
		profile.daily = Goals.make_daily(today(), profile.owned_tools)
		mark_dirty()
		Events.daily_refreshed.emit()
	return profile.daily


func _record_daily(stat: String, amount: float, keep_max: bool) -> void:
	var current := daily()
	for index in Goals.record_daily(current, stat, amount, keep_max):
		var challenge: Dictionary = current["challenges"][index]
		Events.daily_completed.emit(index)
		earn(int(challenge["reward"]), &"daily")


# --- Prestige -------------------------------------------------------------------

const PRESTIGE_BASE := 300000
const PRESTIGE_BONUS := 0.25


## Unlocks one random prestige weapon for purchase. Returns its id, or "" when
## every one is already unlocked.
func unlock_prestige_weapon(rng: RandomNumberGenerator = null) -> String:
	var waiting: Array[String] = []
	for tool in ToolCatalog.all():
		if tool.prestige and not profile.prestige_unlocks.has(tool.id):
			waiting.append(tool.id)
	if waiting.is_empty():
		return ""
	var pick := waiting[(rng.randi() if rng != null else randi()) % waiting.size()]
	profile.prestige_unlocks.append(pick)
	mark_dirty()
	return pick


## $$$ to earn this run before the next prestige is allowed.
func prestige_goal() -> int:
	return PRESTIGE_BASE * (profile.prestige_count + 1)


func can_prestige() -> bool:
	return profile.run_earned >= prestige_goal()


## Wipes $$$, tools and upgrades for a permanent payout bonus. Looks,
## achievements, stats, best scores and settings stay.
func prestige() -> bool:
	if not can_prestige():
		return false
	profile.prestige_count += 1
	profile.money = 0
	profile.run_earned = 0
	# Bought prestige weapons (and their upgrades) are kept; everything else goes.
	var kept: Array[String] = ["hand"]
	var kept_upgrades := {}
	for tool_id in profile.owned_tools:
		var tool := ToolCatalog.get_tool(tool_id)
		if tool != null and tool.prestige:
			kept.append(tool_id)
			if profile.tool_upgrades.has(tool_id):
				kept_upgrades[tool_id] = profile.tool_upgrades[tool_id]
	profile.owned_tools = kept
	profile.selected_tool = "hand"
	profile.tool_upgrades = kept_upgrades
	var unlocked := unlock_prestige_weapon()
	mark_dirty()
	save_now()
	Events.prestiged.emit(profile.prestige_count)
	if not unlocked.is_empty():
		Events.item_unlocked.emit(&"prestige_tool", StringName(unlocked))
	Events.progress_reset.emit()
	Events.money_changed.emit(profile.money)
	return true


func select_tool(tool_id: String) -> bool:
	if not can_use_tool(tool_id):
		return false
	if profile.selected_tool != tool_id:
		profile.selected_tool = tool_id
		mark_dirty()
	Events.tool_selected.emit(StringName(tool_id))
	return true


func set_setting(key: String, value: Variant) -> void:
	if not Profile.DEFAULT_SETTINGS.has(key):
		push_warning("Unknown setting %s" % key)
		return
	profile.settings[key] = value
	apply_settings()
	mark_dirty()
	Events.settings_changed.emit()


func apply_settings() -> void:
	_set_bus_volume("Master", profile.settings["master_volume"])
	_set_bus_volume("Music", profile.settings["music_volume"])
	_set_bus_volume("SFX", profile.settings["sfx_volume"])
	if DisplayServer.get_name() == "headless":
		return
	var window := get_window()
	var fullscreen: bool = profile.settings["fullscreen"]
	var is_fullscreen := window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	if fullscreen != is_fullscreen:
		window.mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED


## Wipes progress but keeps settings. Prestige (Milestone 7) is separate from this.
func reset_progress() -> void:
	var settings := profile.settings.duplicate()
	profile = Profile.new()
	profile.settings = settings
	mark_dirty()
	save_now()
	Events.progress_reset.emit()
	Events.money_changed.emit(profile.money)


func _refuse_save(message: String) -> void:
	saving_enabled = false
	load_notice = message
	push_warning(message)


func _choose_folder() -> String:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("res://tests/"):
			return TEST_FOLDER
	if OS.get_cmdline_user_args().has("--sandbox"):
		return SANDBOX_FOLDER
	return SAVE_FOLDER


func _ensure_audio_buses() -> void:
	for bus_name: String in AUDIO_BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	AudioServer.set_bus_mute(index, linear <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(linear, 0.001)))
