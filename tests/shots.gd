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
	Game.earn(60000, &"shots")
	await _seconds(0.5)

	Game.buy_look(&"room", "kitchen")
	Game.buy_look(&"skin", "cat")
	Game.buy_look(&"color", "mint")
	await _seconds(4.0)
	await _shot("1_kitchen_cat")

	Game.buy_look(&"room", "space")
	Game.buy_look(&"skin", "crown")
	Game.buy_look(&"color", "grape")
	await _seconds(3.0)
	main.grabber.grab_at(main.buddy.head.global_position)
	main.grabber.target = Vector2(700, 380)
	await _seconds(0.8)
	await _shot("2_space_crown_dangling")
	main.grabber.release()

	Game.buy_look(&"room", "dungeon")
	Game.buy_look(&"skin", "tophat")
	await _seconds(3.0)
	await _shot("3_dungeon_tophat")

	Game.buy_look(&"room", "backyard")
	main.hud.shop_panel.show()
	main.hud.shop_panel.show_category(ShopPanel.TOOL_TABS + 1)
	await _seconds(0.3)
	await _shot("4_shop_skins")
	main.hud.shop_panel.show_category(ShopPanel.TOOL_TABS + 2)
	await _seconds(0.3)
	await _shot("5_shop_rooms")
	main.hud.shop_panel.show_category(ShopPanel.TOOL_TABS)
	await _seconds(0.3)
	await _shot("6_shop_colors")
	print("shots done")
	get_tree().quit()


func _seconds(seconds: float) -> void:
	for _i in int(seconds * 120):
		await get_tree().physics_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + shot_name + ".png"))
