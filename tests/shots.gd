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

	# A fresh player: only the Hand, everything else locked with prices.
	Game.earn(380, &"shots")
	await _seconds(0.2)
	await _shot("1_fresh_toolbar")

	# Earning: a combo of different hits with +$$$ popups.
	Game.buy_tool("ball")
	Game.buy_tool("poke")
	buddy.take_hit({"part": &"torso", "force": 3200.0, "source": &"wall", "position": buddy.torso.global_position + Vector2(-40, 0)})
	await _seconds(0.3)
	buddy.notice(&"poke", &"head")
	await _seconds(0.3)
	buddy.take_hit({"part": &"head", "force": 2600.0, "source": &"ball", "position": buddy.head.global_position})
	await _seconds(0.3)
	await _shot("2_money_popups_combo")

	# The shop, part way through: some owned, some buyable, some locked.
	Game.earn(5200, &"shots")
	Game.buy_tool("brick")
	Game.buy_tool("bat")
	Game.upgrade_tool("bat")
	main.hud.shop_panel.show_category(1)
	main.hud.shop_panel.show()
	await _seconds(0.3)
	await _shot("3_shop_throw_tab")
	main.hud.shop_panel.show_category(2)
	await _seconds(0.2)
	await _shot("4_shop_boom_tab")
	print("shots done")
	get_tree().quit()


func _seconds(seconds: float) -> void:
	for _i in int(seconds * 120):
		await get_tree().physics_frame


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(ProjectSettings.globalize_path(OUT + shot_name + ".png"))
