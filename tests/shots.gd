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
	main.hud.goals_panel.show_page(2)
	await _seconds(0.2)
	await _shot("4_goals_minigames")
	Game.earn(40000, &"shots")
	main.hud.goals_panel.show_page(3)
	await _seconds(0.2)
	await _shot("5_goals_prestige")
	main.hud.goals_panel.hide()

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
	print("shots done")
	get_tree().quit()


func _seconds(seconds: float) -> void:
	for _i in int(seconds * 120):
		await get_tree().physics_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + shot_name + ".png"))
