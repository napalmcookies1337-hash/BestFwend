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
	await _seconds(5.0)
	await _shot("1_standing")

	var buddy: Buddy = main.buddy
	grab.grab_at(buddy.head.global_position + Vector2(0, -20))
	grab.target = Vector2(700, 300)
	await _seconds(0.9)
	await _shot("2_dangling_by_head")

	grab.target = Vector2(500, 400)
	await _seconds(0.4)
	for index in 10:
		grab.target = Vector2(500 + index * 80, 400)
		await _physics(1)
	grab.release()
	await _seconds(0.08)
	await _shot("3_thrown_scream")
	while buddy.torso.global_position.x < 1700 and buddy.torso.linear_velocity.x > 0:
		await _physics(1)
	await _physics(2)
	await _shot("4_wall_impact_squash")

	await _seconds(4.0)
	main.spawn_test_ball(Vector2(400, 200))
	main.set_gravity(Vector2(-1960, 0))
	await _seconds(4.0)
	await _shot("5_gravity_left")
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
