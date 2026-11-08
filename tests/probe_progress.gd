extends Node
## Plays the real game from a fresh save like a normal player would, and prints
## when each base tool gets bought. For balancing the ~2 hour pace, and as an
## end-to-end QA run of saving, earning, buying and every tool.
## Run headless with --fixed-fps 120: res://tests/probe_progress.tscn
## Optional: ++ --hours=3 --seed=1

const MAIN_SCENE := preload("res://scenes/main.tscn")
const HZ := 120
const ACTION_GAP := 2.0
const THROW_SHARE := 0.3

var main: Sandbox
var rng := RandomNumberGenerator.new()
var frames := 0
var bought: Array[String] = []
var _missing_limbs_since := -1.0
var _uses: Dictionary = {}
var _by_reason: Dictionary = {}


func _ready() -> void:
	var hours := 3.0
	var resume := false
	rng.seed = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hours="):
			hours = float(arg.get_slice("=", 1))
		elif arg.begins_with("--seed="):
			rng.seed = int(arg.get_slice("=", 1))
		elif arg == "--resume":
			resume = true
	var folder := "user://tests/progress"
	if not resume and DirAccess.dir_exists_absolute(folder):
		for file_name in DirAccess.get_files_at(folder):
			DirAccess.remove_absolute(folder.path_join(file_name))
	Game.use_folder(folder)
	if not resume:
		Game.reset_progress()
	# Continue the clock from an earlier chunk.
	frames = int(float(Game.profile.extra.get("probe_minutes", 0.0)) * 60.0 * HZ)
	rng.seed += frames
	hours += frames / float(HZ) / 3600.0
	Events.money_earned.connect(func(amount: int, reason: StringName) -> void:
		_by_reason[reason] = _by_reason.get(reason, 0) + amount)
	main = MAIN_SCENE.instantiate()
	add_child(main)
	main.tools.manual_cursor = true
	main.grabber.manual_target = true
	await _seconds(3.0)
	await _play(hours * 3600.0)
	Game.profile.extra["probe_minutes"] = _minutes()
	Game.save_now()
	_report()
	get_tree().quit()


func _minutes() -> float:
	return frames / float(HZ) / 60.0


func _play(limit: float) -> void:
	var base_count := ToolCatalog.all().filter(func(tool: ToolDef) -> bool: return not tool.prestige).size()
	var next_report := floorf(_minutes() / 10.0) * 10.0 + 10.0
	while frames < limit * HZ:
		_buy()
		if Game.profile.owned_tools.size() >= base_count:
			print("ALL %d BASE TOOLS OWNED at %.1f min" % [base_count, _minutes()])
			return
		_tend_buddy()
		await _act()
		await _seconds(rng.randf_range(ACTION_GAP * 0.6, ACTION_GAP * 1.4))
		if _minutes() >= next_report:
			print("  %3.0f min: $$$ %s earned, %d tools, $$$ %s on hand" % [_minutes(),
					Fmt.grouped(Game.profile.lifetime_money), Game.profile.owned_tools.size(), Fmt.grouped(Game.profile.money)])
			next_report += 10.0
			main.clean_up(true)
			Game.profile.extra["probe_minutes"] = _minutes()
			Game.save_now()
	print("Stopped at %.0f min with %d tools" % [_minutes(), Game.profile.owned_tools.size()])


## Buys the cheapest tool it can, like a player eyeing the shop.
func _buy() -> void:
	var cheapest: ToolDef = null
	for tool in ToolCatalog.all():
		if tool.prestige or Game.tool_status(tool.id) != &"buyable":
			continue
		if cheapest == null or tool.price < cheapest.price:
			cheapest = tool
	if cheapest != null and Game.buy_tool(cheapest.id):
		bought.append(cheapest.id)
		print("[%5.1f min] bought %-12s for %7s  (earned so far %s)" % [_minutes(), cheapest.display_name,
				Fmt.grouped(cheapest.price), Fmt.grouped(Game.profile.lifetime_money)])


func _tend_buddy() -> void:
	var buddy := main.buddy
	if buddy == null or not is_instance_valid(buddy):
		return
	if buddy.is_knocked_out and rng.randf() < 0.5:
		buddy.revive()
	if buddy.severed.size() >= 2:
		if _missing_limbs_since < 0.0:
			_missing_limbs_since = _minutes()
		elif _minutes() - _missing_limbs_since > 0.4:
			main.respawn()
			_missing_limbs_since = -1.0
	else:
		_missing_limbs_since = -1.0


func _act() -> void:
	var buddy := main.buddy
	if buddy == null or not is_instance_valid(buddy) or buddy.part_list.is_empty():
		return
	var owned: Array[String] = []
	for tool_id in Game.profile.owned_tools:
		if tool_id != "hand":
			owned.append(tool_id)
	if owned.is_empty() or rng.randf() < THROW_SHARE:
		_throw(buddy)
		return
	# Players favour their newest toys.
	var pick: String = owned[rng.randi() % owned.size()]
	if rng.randf() < 0.4:
		pick = owned[owned.size() - 1 - rng.randi() % mini(3, owned.size())]
	_uses[pick] = _uses.get(pick, 0) + 1
	var tool := ToolCatalog.get_tool(pick)
	Game.select_tool(pick)
	var part: BuddyPart = buddy.part_list[rng.randi() % buddy.part_list.size()]
	var at := part.global_position
	main.tools.cursor = at
	if not main.tools.press(at):
		return
	if main.tools.active != null:
		# Hold and drag tools: a second of following, wiggling or swiping.
		var from := at + Vector2(-260, -60)
		for step in HZ:
			if not is_instance_valid(buddy) or buddy.part_list.is_empty():
				break
			var target := buddy.torso.global_position
			if pick == "bat" or pick == "katana":
				target = from.lerp(target + Vector2(260, 60), step / float(HZ) * 3.0)
			elif pick == "tickle":
				target += Vector2(sin(step * 0.6) * 30.0, 0)
			main.tools.cursor = target
			await get_tree().physics_frame
			frames += 1
		main.tools.release(main.tools.cursor)
	main.grabber.release()
	Game.select_tool("hand")


func _throw(buddy: Buddy) -> void:
	var velocity := Vector2(rng.randf_range(-2600, 2600), rng.randf_range(-2600, -600))
	buddy.launch(velocity)
	Events.buddy_released.emit(&"torso", velocity)
	_uses["hand"] = _uses.get("hand", 0) + 1


func _report() -> void:
	print("Lifetime $$$: %s, achievements %d, uses %s" % [Fmt.grouped(Game.profile.lifetime_money),
			Game.profile.achievements.size(), _uses])
	print("Earned by reason: %s" % [_by_reason])


func _seconds(seconds: float) -> void:
	for _i in int(seconds * HZ):
		await get_tree().physics_frame
		frames += 1
