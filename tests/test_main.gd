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
	check(slots[1].disabled, "empty slots are locked")
	return true


func test_slowmo_toggle() -> bool:
	main.set_slowmo(true)
	check_eq(Engine.time_scale, main.SLOWMO_SCALE, "slow")
	check(main.hud.slowmo_button.button_pressed, "button shows it")
	# Slow-mo should shrink each physics step, not drop steps, so motion stays smooth.
	var start := Time.get_ticks_msec()
	await physics_frames(60)
	var real_seconds := (Time.get_ticks_msec() - start) / 1000.0
	check(real_seconds < 0.8, "60 physics steps took %.2f real seconds in slow-mo" % real_seconds)
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
	var ball := RigidBody2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40
	shape.shape = circle
	ball.add_child(shape)
	ball.position = main.room.spawn_point()
	ball.add_to_group(main.DEBRIS_GROUP)
	main.world.add_child(ball)
	await physics_frames(240)
	check(ball.position.y < Room.FLOOR_Y, "stays above the floor (y=%.0f)" % ball.position.y)
	check(ball.position.y > Room.FLOOR_Y - 60, "came to rest on it (y=%.0f)" % ball.position.y)
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
	check_eq(Game.profile.selected_tool, "hand", "an empty slot changes nothing")
	return true
