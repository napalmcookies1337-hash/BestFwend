extends Node
## Renders the real game to tests/shots/ for visual review. Needs a real window,
## so don't run it headless. Uses a throwaway save folder.

const OUT := "res://tests/shots/"
const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node2D


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
	var grab: Grabber = main.grabber
	grab.manual_target = true
	await _seconds(1.3)
	await _shot("1_hello")

	await _seconds(3.0)
	var buddy: Buddy = main.buddy
	grab.grab_at(buddy.head.global_position + Vector2(0, -20))
	grab.target = Vector2(800, 330)
	await _seconds(1.0)
	await _shot("2_grabbed_head")

	grab.target = Vector2(700, 420)
	await _seconds(0.4)
	for index in 12:
		grab.target = Vector2(700 + index * 90, 420)
		await _physics(1)
	grab.release()
	await _seconds(0.12)
	await _shot("3_thrown")
	await _seconds(0.9)
	await _shot("4_slam_blood")

	await _seconds(2.0)
	buddy.take_hit({"part": &"head", "force": 4000.0, "damage": 200.0, "source": &"wall",
			"position": buddy.head.global_position + Vector2(0, -50)})
	await _seconds(1.5)
	await _shot("5_knocked_out")

	buddy.revive()
	await _seconds(0.8)
	await _shot("6_revived_dizzy")
	print("shots done")
	get_tree().quit()


func _seconds(seconds: float) -> void:
	await _physics(int(seconds * 120))


func _physics(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + shot_name + ".png"))
