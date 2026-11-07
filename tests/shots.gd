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
	await _seconds(4.0)
	var buddy := main.buddy

	# Toolbar on the Boom tab with dynamite stuck to a leg and a mine nearby.
	main.hud.category_buttons[2].pressed.emit()
	main.hud.category_buttons[2].button_pressed = true
	Game.select_tool("dynamite")
	main.tools.press(buddy.parts[&"leg_l"].global_position)
	main.place_landmine(Vector2(buddy.torso.global_position.x + 260, 400))
	main.tools.cursor = buddy.torso.global_position + Vector2(-200, -150)
	await _seconds(0.6)
	await _shot("1_boom_tab_dynamite")
	await _seconds(1.95)
	await _shot("2_explosion")
	await _seconds(1.5)
	await _shot("3_missing_leg")

	main.respawn()
	await _seconds(4.0)
	buddy = main.buddy
	buddy.ignite(6.0)
	await _seconds(1.2)
	await _shot("4_on_fire")

	main.respawn()
	await _seconds(4.0)
	buddy = main.buddy
	buddy.freeze(6.0)
	await _seconds(1.0)
	await _shot("5_frozen")

	main.clean_up()
	main.respawn()
	await _seconds(4.0)
	buddy = main.buddy
	main.hud.category_buttons[3].pressed.emit()
	main.hud.category_buttons[3].button_pressed = true
	Game.select_tool("lightning")
	main.tools.press(buddy.torso.global_position)
	await _seconds(0.05)
	await _shot("6_lightning")

	await _seconds(2.0)
	main.spawn_black_hole(buddy.torso.global_position + Vector2(-380, -250), 4.0)
	for index in 6:
		main.spawn_object(&"brick", Vector2(300 + index * 60, 200))
	await _seconds(1.4)
	await _shot("7_black_hole")

	await _seconds(4.0)
	main.hud.category_buttons[1].pressed.emit()
	main.hud.category_buttons[1].button_pressed = true
	Game.select_tool("katana")
	main.tools.cursor = buddy.torso.global_position + Vector2(150, -120)
	await _seconds(0.1)
	await _shot("8_katana_cursor")
	print("shots done")
	get_tree().quit()


func _seconds(seconds: float) -> void:
	for _i in int(seconds * 120):
		await get_tree().physics_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + shot_name + ".png"))
