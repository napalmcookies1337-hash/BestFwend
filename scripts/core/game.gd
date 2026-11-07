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
	mark_dirty()
	Events.money_earned.emit(amount, reason)
	Events.money_changed.emit(profile.money)


func spend(amount: int, reason: StringName) -> bool:
	if amount < 0 or amount > profile.money:
		return false
	profile.money -= amount
	mark_dirty()
	Events.money_spent.emit(amount, reason)
	Events.money_changed.emit(profile.money)
	return true


## Until the shop opens (Milestone 5), every tool is free to try.
const TOOLS_FREE := true


func can_use_tool(tool_id: String) -> bool:
	if ToolCatalog.get_tool(tool_id) == null:
		return false
	return TOOLS_FREE or profile.owned_tools.has(tool_id)


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
