extends Node
## Renders the real game to tests/shots/ for visual review. Needs a real window,
## so don't run it headless. Uses a throwaway save folder.

const OUT := "res://tests/shots/"
const MAIN_SCENE := preload("res://scenes/main.tscn")


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
	var main: Node2D = MAIN_SCENE.instantiate()
	add_child(main)
	await _wait()
	await _shot("1_room")

	Game.earn(12345, &"shots")
	Events.notification_posted.emit("Squeaky clean.")
	main.hud.gravity_panel.show()
	await get_tree().create_timer(0.4).timeout
	await _shot("2_money_toast_gravity")

	main.hud.gravity_panel.hide()
	main.hud.settings_panel.show()
	await _wait()
	await _shot("3_settings")

	main.hud.settings_panel.hide()
	main.hud.category_buttons[2].pressed.emit()
	main.hud.category_buttons[2].button_pressed = true
	var ball := RigidBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 50
	shape.shape = circle
	ball.add_child(shape)
	ball.position = main.room.spawn_point()
	main.world.add_child(ball)
	await get_tree().create_timer(1.0).timeout
	await _shot("4_other_tab")
	print("shots done")
	get_tree().quit()


func _wait() -> void:
	for _i in 4:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + shot_name + ".png"))
