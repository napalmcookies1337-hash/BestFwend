extends TestSuite
## The main scene: room walls, HUD wiring, slow motion, gravity and clean up.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node2D


func before_each() -> void:
	reset_game("main_scene")
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)


func after_each() -> void:
	main.queue_free()
	await frames(1)
	Engine.time_scale = 1.0


func test_room_has_four_walls() -> bool:
	var walls: StaticBody2D = main.room.walls
	check_eq(walls.get_child_count(), 4, "floor, ceiling, two walls")
	return true


func test_money_label_follows_wallet() -> bool:
	var label: Label = main.hud.money_label
	check_eq(label.text, "$$$ 0", "starts at zero")
	Game.earn(1500, &"test")
	check_eq(label.text, "$$$ 1,500", "updates")
	return true


func test_toolbar_shows_hand_selected() -> bool:
	var slots: Array[ToolSlot] = main.hud.slots
	check_eq(slots.size(), Controls.HOTBAR_SLOTS, "nine slots")
	check_eq(slots[0].tool_id, "hand", "hand in the first slot")
	check(slots[0].button_pressed, "hand highlighted")
	check_eq(slots[1].tool_id, "poke", "poke next")
	check(not slots[1].usable, "but it isn't owned yet")
	check_eq(slots[1].price, 50, "and shows its price")
	check(slots[6].disabled, "empty slots are disabled")
	var counts := {}
	for tool in ToolCatalog.all():
		counts[tool.category] = counts.get(tool.category, 0) + 1
	check_eq(ToolCatalog.all().size(), 21, "21 tools")
	check_eq(counts, {0: 5, 1: 5, 2: 6, 3: 5}, "tools per category")
	main.hud.category_buttons[2].pressed.emit()
	check_eq(slots[5].tool_id, "mini_nuke", "Boom tab shows the nuke in slot 6")
	return true


func test_slowmo_toggle() -> bool:
	main.set_slowmo(true)
	check_eq(Engine.time_scale, main.SLOWMO_SCALE, "slow")
	check(main.hud.slowmo_button.button_pressed, "button shows it")
	# Slow-mo should shrink each physics step, not drop steps, so motion stays smooth.
	await physics_frames(2)
	var step := get_physics_process_delta_time()
	check(is_equal_approx(step, main.SLOWMO_SCALE / 120.0), "physics step shrinks in slow-mo (%.5f)" % step)
	main.hud.slowmo_button.toggled.emit(false)
	check_eq(Engine.time_scale, 1.0, "button turns it off")
	return true


func test_gravity_changes_the_space() -> bool:
	var space: RID = main.get_world_2d().space
	main.set_gravity(Vector2(-980, 0))
	check_eq(PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY), 980.0, "strength")
	check_eq(PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR), Vector2.LEFT, "direction")
	main.hud.gravity_strength.value = 0.0
	check_eq(PhysicsServer2D.area_get_param(space, PhysicsServer2D.AREA_PARAM_GRAVITY), 0.0, "slider to zero-G")
	main.set_gravity(Vector2(0, main.BASE_GRAVITY))
	return true


func test_falling_object_lands_on_the_floor() -> bool:
	main.buddy.torso.global_position = Vector2(1700, 700) # Out of the ball's way.
	var ball: TestBall = main.spawn_test_ball(Vector2(200, 300))
	await physics_frames(480)
	check(ball.position.y < Room.FLOOR_Y, "stays above the floor (y=%.0f)" % ball.position.y)
	check(ball.position.y > Room.FLOOR_Y - TestBall.RADIUS - 20, "came down onto it (y=%.0f)" % ball.position.y)
	main.clean_up()
	await frames(1)
	check(not is_instance_valid(ball), "clean up removes debris")
	return true


func test_settings_panel_writes_settings() -> bool:
	var panel: SettingsPanel = main.hud.settings_panel
	panel.show()
	(panel.sliders["sfx_volume"] as HSlider).value = 0.35
	check_eq(Game.profile.settings["sfx_volume"], 0.35, "slider saved to settings")
	check(main.hud.close_menus(), "esc closes it")
	check(not panel.visible, "hidden")
	return true


func test_hotkey_selects_owned_tool() -> bool:
	main.hud.select_hotbar(1)
	check_eq(Game.profile.selected_tool, "hand", "slot 1 is the hand")
	main.hud.select_hotbar(5)
	check_eq(Game.profile.selected_tool, "hand", "an unowned tool can't be picked")
	Game.profile.owned_tools.append("pin")
	main.hud._refresh_slots()
	main.hud.select_hotbar(5)
	check_eq(Game.profile.selected_tool, "pin", "slot 5 is the pin once owned")
	main.hud.select_hotbar(8)
	check_eq(Game.profile.selected_tool, "pin", "an empty slot changes nothing")
	Game.select_tool("hand")
	return true
