class_name Hud
extends CanvasLayer
## The on-screen shell: money, toolbar, room buttons, toasts and menus.
## It never touches the world directly; it asks through its signals.

signal respawn_pressed
signal clean_up_pressed
signal slowmo_toggled(enabled: bool)
signal gravity_chosen(gravity: Vector2)
signal minigame_requested(minigame_id: StringName)
signal minigame_quit

const TOAST_SECONDS := 3.0
const MAX_TOASTS := 3
const GOLD := Color("f2c14e")
const GRAVITY_DIRECTIONS := {
	"Down": Vector2.DOWN,
	"Up": Vector2.UP,
	"Left": Vector2.LEFT,
	"Right": Vector2.RIGHT,
}

var root: Control
var money_label: Label
var health_bar: ProgressBar
var health_label: Label
var _health_fill: StyleBoxFlat
var slowmo_button: Button
var shop_button: Button
var shop_panel: ShopPanel
var goals_button: Button
var goals_panel: GoalsPanel
var minigames_button: Button
var minigames_panel: MinigamesPanel
var minigame_hud: MinigameHud
var combo_label: Label
## Tools the player has already been told they can afford, this session.
var _announced: Dictionary = {}
var settings_panel: SettingsPanel
var dev_panel: DevPanel
var gravity_panel: PanelContainer
var gravity_strength: HSlider
var category_buttons: Array[Button] = []
var slots: Array[ToolSlot] = []
var _toasts: VBoxContainer
var _slot_row: HBoxContainer
var _category := ToolDef.Category.HAND
var _gravity_direction := Vector2.DOWN
var _base_gravity := 1960.0


func _ready() -> void:
	layer = 10
	root = Control.new()
	root.name = "Root"
	root.theme = UiTheme.build()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_money()
	_build_top_buttons()
	_build_room_buttons()
	_build_toolbar()
	_build_gravity_panel()
	_toasts = VBoxContainer.new()
	_toasts.name = "Toasts"
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	root.add_child(_toasts)
	_toasts.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toasts.position.y = 28
	settings_panel = SettingsPanel.new()
	root.add_child(settings_panel)
	settings_panel.hide()
	shop_panel = ShopPanel.new()
	root.add_child(shop_panel)
	shop_panel.hide()
	goals_panel = GoalsPanel.new()
	root.add_child(goals_panel)
	goals_panel.hide()
	minigames_panel = MinigamesPanel.new()
	root.add_child(minigames_panel)
	minigames_panel.hide()
	minigames_panel.minigame_chosen.connect(minigame_requested.emit)
	minigame_hud = MinigameHud.new()
	root.add_child(minigame_hud)
	minigame_hud.quit_pressed.connect(minigame_quit.emit)
	minigame_hud.quit_pressed.connect(func() -> void: _toasts.position.y = 28.0)
	minigame_hud.again_pressed.connect(minigame_requested.emit)
	dev_panel = DevPanel.new()
	root.add_child(dev_panel)
	dev_panel.hide()
	for tool in ToolCatalog.all():
		if Game.tool_status(tool.id) == &"buyable":
			_announced[tool.id] = true

	Events.money_changed.connect(_on_money_changed)
	Events.buddy_health_changed.connect(_on_health_changed)
	Events.notification_posted.connect(show_toast)
	Events.listen(self, Events.tool_selected, func(_id: StringName) -> void: _refresh_slots())
	Events.progress_reset.connect(_refresh_slots)
	Events.tool_purchased.connect(_on_tool_purchased)
	Events.listen(self, Events.item_unlocked, func(kind: StringName, item_id: StringName) -> void:
		_refresh_slots()
		if kind == &"prestige_tool":
			var weapon := ToolCatalog.get_tool(String(item_id))
			show_toast("Prestige reward: the %s is now in the shop!" % weapon.display_name, GOLD))
	Events.combo_changed.connect(_on_combo_changed)
	Events.achievement_unlocked.connect(_on_achievement)
	Events.daily_completed.connect(_on_daily_completed)
	Events.listen(self, Events.prestiged, func(count: int) -> void:
		show_toast("Prestige %d! Everything now pays x%.2f." % [count, Game.reward_multiplier()], GOLD)
		Sfx.play(&"fanfare", -2.0))
	Events.listen(self, Events.minigame_started, func(_id: StringName) -> void: _toasts.position.y = 150.0)
	Events.listen(self, Events.minigame_finished, func(_result: Dictionary) -> void: _toasts.position.y = 28.0)
	_on_money_changed(Game.profile.money, false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("close_menu") and close_menus():
		get_viewport().set_input_as_handled()


func set_base_gravity(value: float) -> void:
	_base_gravity = value


## Returns true if a menu was open.
func close_menus() -> bool:
	var was_open := settings_panel.visible or gravity_panel.visible or shop_panel.visible or goals_panel.visible \
			or minigames_panel.visible or dev_panel.visible
	dev_panel.hide()
	minigames_panel.hide()
	settings_panel.hide()
	gravity_panel.hide()
	shop_panel.hide()
	goals_panel.hide()
	return was_open


func select_hotbar(number: int) -> void:
	var index := number - 1
	if index < 0 or index >= slots.size() or slots[index].tool_id.is_empty():
		return
	if not slots[index].usable:
		var tool := ToolCatalog.get_tool(slots[index].tool_id)
		show_toast("Get the %s in the shop first." % tool.display_name)
		return
	Game.select_tool(slots[index].tool_id)


func set_slowmo_shown(enabled: bool) -> void:
	slowmo_button.set_pressed_no_signal(enabled)


func show_toast(text: String, color := UiTheme.TEXT) -> void:
	# Only the newest few stay up, so a burst of news can't cover the room.
	var live := _toasts.get_children().filter(func(node: Node) -> bool: return not node.is_queued_for_deletion())
	while live.size() >= MAX_TOASTS:
		var oldest: Node = live.pop_front()
		_toasts.remove_child(oldest)
		oldest.queue_free()
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	panel.add_child(label)
	_toasts.add_child(panel)
	_toasts.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	_toasts.position.y = 28
	panel.modulate.a = 0.0
	var tween := panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	tween.tween_interval(TOAST_SECONDS)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)


func _build_money() -> void:
	var panel := PanelContainer.new()
	panel.name = "Money"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(24, 20)
	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 44)
	money_label.add_theme_color_override("font_color", UiTheme.MONEY)
	money_label.add_theme_color_override("font_outline_color", UiTheme.INK)
	money_label.add_theme_constant_override("outline_size", 8)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.add_child(money_label)
	column.add_child(_build_health())
	combo_label = Label.new()
	combo_label.add_theme_font_size_override("font_size", 24)
	combo_label.add_theme_color_override("font_color", UiTheme.ACCENT)
	combo_label.hide()
	column.add_child(combo_label)
	panel.add_child(column)
	root.add_child(panel)


func _build_health() -> Control:
	var row := HBoxContainer.new()
	row.name = "Health"
	row.add_theme_constant_override("separation", 10)
	health_label = Label.new()
	health_label.add_theme_font_size_override("font_size", 22)
	health_label.custom_minimum_size.x = 52
	row.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.custom_minimum_size = Vector2(220, 22)
	health_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var back := UiTheme.box(UiTheme.INK, UiTheme.PANEL_EDGE, 2, 0)
	back.set_corner_radius_all(8)
	health_bar.add_theme_stylebox_override("background", back)
	_health_fill = UiTheme.box(UiTheme.HEALTH, Color.TRANSPARENT, 0, 0)
	_health_fill.set_corner_radius_all(8)
	health_bar.add_theme_stylebox_override("fill", _health_fill)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(health_bar)
	_on_health_changed(Buddy.MAX_HEALTH, Buddy.MAX_HEALTH, false)
	return row


func _on_health_changed(health: float, max_health: float, knocked_out: bool) -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	if knocked_out:
		health_label.text = "KO!"
		health_label.add_theme_color_override("font_color", UiTheme.DANGER)
	else:
		health_label.text = "HP"
		health_label.add_theme_color_override("font_color", UiTheme.MUTED)
	var share := health / max_health
	_health_fill.bg_color = UiTheme.HEALTH if share > 0.3 else UiTheme.DANGER


func _build_top_buttons() -> void:
	var row := HBoxContainer.new()
	row.name = "TopButtons"
	row.add_theme_constant_override("separation", 12)
	root.add_child(row)
	shop_button = _button("Shop", "Buy new tools and upgrades.")
	shop_button.pressed.connect(func() -> void:
		settings_panel.hide()
		gravity_panel.hide()
		shop_panel.visible = not shop_panel.visible)
	goals_button = _button("Goals", "Achievements, daily challenges and prestige.")
	goals_button.pressed.connect(func() -> void:
		settings_panel.hide()
		gravity_panel.hide()
		shop_panel.hide()
		goals_panel.visible = not goals_panel.visible)
	minigames_button = _button("Minigames", "Zombie Mode, Target Toss and Impact Frenzy.")
	minigames_button.pressed.connect(func() -> void:
		var was_open := minigames_panel.visible
		close_menus()
		minigames_panel.visible = not was_open)
	row.add_child(minigames_button)
	row.add_child(goals_button)
	row.add_child(shop_button)
	var settings_button := _button("Settings", "Volume, fullscreen and progress.")
	settings_button.pressed.connect(func() -> void:
		gravity_panel.hide()
		settings_panel.visible = not settings_panel.visible)
	row.add_child(settings_button)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	# Grow leftward when a button's text gets longer, so nothing slides off screen.
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN


func _build_room_buttons() -> void:
	var column := VBoxContainer.new()
	column.name = "RoomButtons"
	column.add_theme_constant_override("separation", 10)
	root.add_child(column)
	var respawn := _button("Respawn", "Bring back a fresh, whole fwend.  [R]")
	respawn.pressed.connect(respawn_pressed.emit)
	column.add_child(respawn)
	var clean := _button("Clean Up", "Wipe blood and clear debris.  [C]")
	clean.pressed.connect(clean_up_pressed.emit)
	column.add_child(clean)
	slowmo_button = _button("Slow-Mo", "Toggle slow motion.  [T]")
	slowmo_button.toggle_mode = true
	slowmo_button.toggled.connect(slowmo_toggled.emit)
	column.add_child(slowmo_button)
	var gravity := _button("Gravity", "Change gravity's direction and strength.")
	gravity.pressed.connect(func() -> void:
		settings_panel.hide()
		gravity_panel.visible = not gravity_panel.visible)
	column.add_child(gravity)
	for child in column.get_children():
		(child as Button).custom_minimum_size.x = 190
	column.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	column.position.y = 110


func _build_toolbar() -> void:
	var panel := PanelContainer.new()
	panel.name = "Toolbar"
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	box.add_child(tabs)
	var group := ButtonGroup.new()
	for category: int in ToolDef.CATEGORY_NAMES:
		var tab := _button(ToolDef.CATEGORY_NAMES[category], "")
		tab.toggle_mode = true
		tab.button_group = group
		tab.add_theme_font_size_override("font_size", 20)
		tab.button_pressed = category == _category
		tab.pressed.connect(func() -> void:
			_category = category as ToolDef.Category
			_refresh_slots())
		tabs.add_child(tab)
		category_buttons.append(tab)
	_slot_row = HBoxContainer.new()
	_slot_row.add_theme_constant_override("separation", 8)
	box.add_child(_slot_row)
	for index in Controls.HOTBAR_SLOTS:
		var slot := ToolSlot.new()
		slot.pressed.connect(func() -> void:
			if not slot.usable and not slot.tool_id.is_empty():
				shop_panel.open_at(slot.tool_id)
			elif not slot.tool_id.is_empty():
				Game.select_tool(slot.tool_id)
			_refresh_slots())
		_slot_row.add_child(slot)
		slots.append(slot)
	_refresh_slots()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)


func _build_gravity_panel() -> void:
	gravity_panel = PanelContainer.new()
	gravity_panel.name = "GravityPanel"
	root.add_child(gravity_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	gravity_panel.add_child(box)
	var title := Label.new()
	title.text = "Gravity"
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)
	var directions := GridContainer.new()
	directions.columns = 2
	box.add_child(directions)
	for label: String in GRAVITY_DIRECTIONS:
		var direction: Vector2 = GRAVITY_DIRECTIONS[label]
		var button := _button(label, "")
		button.custom_minimum_size.x = 130
		button.pressed.connect(func() -> void:
			_gravity_direction = direction
			_emit_gravity())
		directions.add_child(button)
	var strength_label := Label.new()
	box.add_child(strength_label)
	gravity_strength = HSlider.new()
	gravity_strength.min_value = 0.0
	gravity_strength.max_value = 2.0
	gravity_strength.step = 0.25
	gravity_strength.value = 1.0
	gravity_strength.custom_minimum_size = Vector2(270, 32)
	var show_strength := func(value: float) -> void:
		strength_label.text = "Strength: %s" % ("Zero-G" if value == 0.0 else "%.2fx" % value)
	show_strength.call(gravity_strength.value)
	gravity_strength.value_changed.connect(func(value: float) -> void:
		show_strength.call(value)
		_emit_gravity())
	box.add_child(gravity_strength)
	var reset := _button("Normal", "Back to regular gravity.")
	reset.pressed.connect(func() -> void:
		_gravity_direction = Vector2.DOWN
		gravity_strength.value = 1.0
		_emit_gravity())
	box.add_child(reset)
	gravity_panel.hide()
	gravity_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 24)
	gravity_panel.position = Vector2(gravity_panel.position.x - 214, 110)


func _emit_gravity() -> void:
	gravity_chosen.emit(_gravity_direction * _base_gravity * gravity_strength.value)


func _refresh_slots() -> void:
	var tools := ToolCatalog.in_category(_category)
	for index in slots.size():
		var slot := slots[index]
		var tool: ToolDef = tools[index] if index < tools.size() else null
		var owned := tool != null and Game.can_use_tool(tool.id)
		if owned:
			slot.setup(tool.id, index + 1, "%s\n%s" % [tool.display_name, tool.description])
		elif tool != null:
			var where := "a prestige reward" if Game.tool_status(tool.id) == &"prestige_locked" else "%s in the shop" % Fmt.money(tool.price)
			slot.setup(tool.id, index + 1, "%s  (%s)\n%s" % [tool.display_name, where, tool.description], false, tool.price)
			slot.prestige = tool.prestige
			slot.prestige_locked = Game.tool_status(tool.id) == &"prestige_locked"
		else:
			slot.setup("", 0, "")
		slot.set_pressed_no_signal(owned and tool.id == Game.profile.selected_tool)
		slot.queue_redraw()


func _on_money_changed(total: int, animate := true) -> void:
	money_label.text = Fmt.money(total)
	_announce_new_tools()
	if not animate:
		return
	money_label.pivot_offset = money_label.size / 2
	var tween := money_label.create_tween()
	tween.tween_property(money_label, "scale", Vector2(1.18, 1.18), 0.06)
	tween.tween_property(money_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)


func _button(text: String, tooltip: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	return button


## Tells the player once when a new tool becomes affordable, and marks the Shop.
func _announce_new_tools() -> void:
	var newest: ToolDef = null
	var any_buyable := false
	for tool in ToolCatalog.all():
		if Game.tool_status(tool.id) != &"buyable":
			continue
		any_buyable = true
		if not _announced.has(tool.id):
			_announced[tool.id] = true
			if newest == null or tool.price > newest.price:
				newest = tool
	if shop_button != null:
		shop_button.text = "Shop (!)" if any_buyable else "Shop"
	if newest != null:
		show_toast("New in the shop: %s  (%s)" % [newest.display_name, Fmt.money(newest.price)])


func _on_tool_purchased(tool_id: StringName) -> void:
	var tool := ToolCatalog.get_tool(String(tool_id))
	Sfx.play(&"cha_ching", -2.0)
	var level := Game.tool_level(String(tool_id))
	if level == 0:
		show_toast("Bought the %s!" % tool.display_name)
		_category = tool.category
		for index in category_buttons.size():
			category_buttons[index].set_pressed_no_signal(index == tool.category)
		Game.select_tool(String(tool_id))
	else:
		show_toast("%s upgraded to level %d!" % [tool.display_name, level])
	_refresh_slots()
	_announce_new_tools()


func _on_combo_changed(multiplier: float) -> void:
	combo_label.visible = multiplier > 1.01
	combo_label.text = "COMBO  x%.2f" % multiplier
	if combo_label.visible:
		combo_label.pivot_offset = combo_label.size / 2
		var tween := combo_label.create_tween()
		tween.tween_property(combo_label, "scale", Vector2(1.2, 1.2), 0.06)
		tween.tween_property(combo_label, "scale", Vector2.ONE, 0.15)

func _on_achievement(achievement_id: StringName) -> void:
	var spec: Array = GoalData.ACHIEVEMENTS[String(achievement_id)]
	show_toast("Achievement: %s!  +%s" % [spec[0], Fmt.money(spec[4])], GOLD)
	Sfx.play(&"fanfare", -2.0)


func _on_daily_completed(index: int) -> void:
	var challenge: Dictionary = Game.daily()["challenges"][index]
	show_toast("Daily done: %s  +%s" % [Goals.daily_text(challenge), Fmt.money(challenge["reward"])], GOLD)
	Sfx.play(&"fanfare", -2.0)