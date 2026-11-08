extends Node
## Renders the real game to tests/shots/ for visual review. Needs a real window,
## so don't run it headless. Uses a throwaway save folder.

const OUT := "res://tests/shots/"
const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Sandbox


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	get_window().size = Vector2i(1600, 900)
	var folder := "user://tests/shots"
	if DirAccess.dir_exists_absolute(folder):
		for file_name in DirAccess.get_files_at(folder):
			DirAccess.remove_absolute(folder.path_join(file_name))
	Game.use_folder(folder)
	_capture.call_deferred()


func _capture() -> void:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	main.tools.manual_cursor = true
	main.grabber.manual_target = true
	await _seconds(3.0)

	# Some progress, an achievement popping, and the Goals window.
	Game.earn(12000, &"shots")
	for _index in 3:
		Game.record("throws")
	Game.record("knockouts")
	Game.record("biggest_hit", 4200.0)
	await _seconds(0.3)
	await _shot("1_achievement_toasts")
	main.hud.goals_panel.show()
	main.hud.goals_panel.show_page(0)
	await _seconds(0.3)
	await _shot("2_goals_achievements")
	main.hud.goals_panel.show_page(1)
	await _seconds(0.2)
	await _shot("3_goals_daily")
	Game.earn(40000, &"shots")
	main.hud.goals_panel.show_page(2)
	await _seconds(0.2)
	await _shot("4_goals_prestige")
	main.hud.goals_panel.hide()
	main.hud.minigames_panel.show()
	await _seconds(0.2)
	await _shot("5_minigames_panel")
	main.hud.minigames_panel.hide()

	# Prestige weapons in action.
	Game.unlock_all_tools()
	await _seconds(0.2)
	main.hud.category_buttons[3].pressed.emit()
	_use("tornado", main.buddy.torso.global_position + Vector2(-200, 0))
	await _seconds(1.6)
	await _shot("8_tornado")
	await _seconds(5.0)
	main.respawn()
	await _seconds(2.0)
	Game.select_tool("orbital_laser")
	main.tools.cursor = main.buddy.torso.global_position
	main.tools.press(main.tools.cursor)
	for _i in 60:
		main.tools.cursor = main.buddy.torso.global_position
		await get_tree().physics_frame
	await _shot("9_orbital_laser")
	main.tools.release(main.tools.cursor)
	main.respawn()
	await _seconds(2.0)
	_use("land_shark", Vector2(300, 800))
	var shark: Node = null
	for _i in 600:
		await get_tree().physics_frame
		for node in get_tree().get_nodes_in_group(&"debris"):
			if node is LandShark and (node as LandShark).phase == LandShark.Phase.LEAP and (node as LandShark)._phase_time > 0.3:
				shark = node
		if shark != null:
			break
	await _shot("10_land_shark")
	await _seconds(1.5)
	main.respawn()
	await _seconds(2.0)
	main.hud.category_buttons[2].pressed.emit()
	_use("rocket_pack", main.buddy.torso.global_position)
	await _seconds(1.5)
	await _shot("11_rocket_pack")
	await _seconds(3.0)
	main.respawn()
	await _seconds(2.0)
	main.hud.category_buttons[1].pressed.emit()
	_use("wrecking_ball", main.buddy.torso.global_position)
	await _seconds(0.5)
	await _shot("12_wrecking_ball")
	main.clean_up(true)
	main.respawn()
	await _seconds(1.0)

	# Zombie Mode.
	var horde: Minigame = main.minigames.start(&"zombies")
	await _seconds(4.0)
	await _shot("13_zombie_mode")
	main.minigames.stop()
	await _seconds(1.0)

	# Target Toss in progress, then its results.
	var game: Minigame = main.minigames.start(&"toss")
	await _seconds(2.0)
	game.score = 3.0
	await _seconds(0.2)
	await _shot("6_toss_running")
	game.score = 7.0
	game.time_left = 0.01
	await _seconds(0.3)
	await _shot("7_results")
	# Other window sizes: the UI scales with the window and keeps 16:9.
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1680, 1050)]:
		get_window().size = size
		await _seconds(0.5)
		await _shot("res_%dx%d" % [size.x, size.y])
	print("shots done")
	get_tree().quit()


func _use(tool_id: String, at: Vector2) -> void:
	Game.select_tool(tool_id)
	main.tools.cursor = at
	main.tools.press(at)
	if main.tools.active != null:
		main.tools.release(at)


func _seconds(seconds: float) -> void:
	for _i in int(seconds * 120):
		await get_tree().physics_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + shot_name + ".png"))
