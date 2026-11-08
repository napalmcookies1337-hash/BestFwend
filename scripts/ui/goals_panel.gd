class_name GoalsPanel
extends PanelContainer
## Optional goals: achievements, today's challenges, minigames and prestige.
## Reads everything from Game; playing a minigame is asked for through a signal.

signal minigame_chosen(minigame_id: StringName)

const PAGES := ["Achievements", "Daily", "Minigames", "Prestige"]

var page := 0
var tabs: Array[Button] = []
var body: VBoxContainer
var prestige_button: Button
var confirm: ConfirmationDialog


func _ready() -> void:
	name = "GoalsPanel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	header.add_child(_label("Goals", 40, UiTheme.TEXT))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(hide)
	header.add_child(close)
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	box.add_child(tab_row)
	var group := ButtonGroup.new()
	for index in PAGES.size():
		var tab := Button.new()
		tab.text = PAGES[index]
		tab.toggle_mode = true
		tab.button_group = group
		tab.focus_mode = Control.FOCUS_NONE
		tab.button_pressed = index == page
		tab.pressed.connect(func() -> void: show_page(index))
		tab_row.add_child(tab)
		tabs.append(tab)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)

	confirm = ConfirmationDialog.new()
	confirm.title = "Prestige?"
	confirm.ok_button_text = "Prestige!"
	confirm.confirmed.connect(func() -> void: Game.prestige())
	add_child(confirm)

	for event: Signal in [Events.achievement_unlocked, Events.daily_completed, Events.daily_refreshed, Events.prestiged]:
		Events.listen(self, event, func(_value: Variant = null) -> void: _rebuild_if_open())
	Events.listen(self, Events.money_changed, func(_total: int) -> void:
		if visible and page == 3:
			_rebuild())
	visibility_changed.connect(func() -> void:
		if visible:
			_rebuild())
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	_rebuild()


func show_page(index: int) -> void:
	page = index
	for tab_index in tabs.size():
		tabs[tab_index].set_pressed_no_signal(tab_index == index)
	_rebuild()


func _rebuild_if_open() -> void:
	if visible:
		_rebuild()


func _rebuild() -> void:
	if body == null:
		return
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	match page:
		0:
			_build_achievements()
		1:
			_build_daily()
		2:
			_build_minigames()
		_:
			_build_prestige()
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0
	reset_size()
	_recenter.call_deferred()


func _recenter() -> void:
	var area := get_parent_area_size()
	if area != Vector2.ZERO:
		position = ((area - size) / 2.0).round()


func _build_achievements() -> void:
	var total := GoalData.ACHIEVEMENTS.size()
	body.add_child(_label("%d / %d unlocked" % [Game.profile.achievements.size(), total], 22, UiTheme.MUTED))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	body.add_child(grid)
	for achievement_id: String in GoalData.ACHIEVEMENTS:
		var spec: Array = GoalData.ACHIEVEMENTS[achievement_id]
		var won := Game.profile.achievements.has(achievement_id)
		var card := _card()
		card.custom_minimum_size = Vector2(420, 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		row.add_child(PreviewBox.new(func(canvas: CanvasItem) -> void:
			ToolArt.trophy(canvas, Transform2D(0.0, Vector2.ONE * 0.62, 0.0, Vector2(29, 30)), 2.5, won), Vector2(58, 58)))
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var title := HBoxContainer.new()
		column.add_child(title)
		title.add_child(_label(spec[0], 20, Color("f2c14e") if won else UiTheme.TEXT))
		var gap := Control.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title.add_child(gap)
		title.add_child(_label("+" + Fmt.money(spec[4]), 16, UiTheme.MONEY if not won else UiTheme.MUTED))
		column.add_child(_label(spec[1], 15, UiTheme.MUTED))
		var progress := Goals.achievement_progress(Game.profile, achievement_id)
		column.add_child(_bar(progress, 10.0))
		grid.add_child(card)


func _build_daily() -> void:
	var daily := Game.daily()
	body.add_child(_label("Today's challenges  ·  new ones in %s" % _until_midnight(), 22, UiTheme.MUTED))
	for challenge: Dictionary in daily["challenges"]:
		var card := _card()
		card.custom_minimum_size = Vector2(720, 0)
		var column := VBoxContainer.new()
		card.add_child(column)
		var row := HBoxContainer.new()
		column.add_child(row)
		var done: bool = challenge["done"]
		row.add_child(_label(("DONE:  " if done else "") + Goals.daily_text(challenge), 24, Color("7be08f") if done else UiTheme.TEXT))
		var gap := Control.new()
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(gap)
		row.add_child(_label("+" + Fmt.money(challenge["reward"]), 22, UiTheme.MONEY))
		var share := clampf(float(challenge["progress"]) / float(challenge["goal"]), 0.0, 1.0)
		column.add_child(_bar(share, 14.0))
		body.add_child(card)


func _build_minigames() -> void:
	for minigame_id: StringName in Minigames.LIST:
		var spec: Array = Minigames.LIST[minigame_id]
		var card := _card()
		card.custom_minimum_size = Vector2(720, 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		card.add_child(row)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		column.add_child(_label(spec[1], 28, UiTheme.TEXT))
		var how := _label(spec[2], 17, UiTheme.MUTED)
		how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		how.custom_minimum_size.x = 500
		column.add_child(how)
		var best := float(Game.profile.best_scores.get(String(minigame_id), 0.0))
		column.add_child(_label("Best: " + (Minigames.best_text(minigame_id, best) if best > 0.0 else "none yet"), 18, UiTheme.ACCENT))
		var play := Button.new()
		play.text = "Play"
		play.focus_mode = Control.FOCUS_NONE
		play.custom_minimum_size = Vector2(140, 60)
		play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		play.add_theme_font_size_override("font_size", 26)
		play.pressed.connect(func() -> void:
			hide()
			minigame_chosen.emit(minigame_id))
		row.add_child(play)
		body.add_child(card)


func _build_prestige() -> void:
	var count := Game.profile.prestige_count
	var card := _card()
	card.custom_minimum_size = Vector2(720, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	card.add_child(column)
	column.add_child(_label("Prestige level %d  ·  everything pays x%.2f" % [count, Game.reward_multiplier()], 28, Color("f2c14e")))
	var about := _label("Start over with only the Hand and no $$$, and earn %d%% more forever after. You keep your looks, achievements, stats and best scores." % roundi(Game.PRESTIGE_BONUS * 100.0), 18, UiTheme.MUTED)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size.x = 680
	column.add_child(about)
	var goal := Game.prestige_goal()
	column.add_child(_label("Earned this run: %s / %s" % [Fmt.money(Game.profile.run_earned), Fmt.money(goal)], 20, UiTheme.TEXT))
	column.add_child(_bar(float(Game.profile.run_earned) / goal, 16.0))
	prestige_button = Button.new()
	prestige_button.focus_mode = Control.FOCUS_NONE
	prestige_button.add_theme_font_size_override("font_size", 24)
	prestige_button.disabled = not Game.can_prestige()
	prestige_button.text = "Prestige for x%.2f" % (Game.reward_multiplier() + Game.PRESTIGE_BONUS) if Game.can_prestige() else "Not yet"
	prestige_button.pressed.connect(func() -> void:
		confirm.dialog_text = "Reset your $$$, tools and upgrades?\nYou'll earn x%.2f from now on. This can't be undone." % (Game.reward_multiplier() + Game.PRESTIGE_BONUS)
		confirm.popup_centered())
	column.add_child(prestige_button)
	body.add_child(card)


func _card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BUTTON.darkened(0.15), UiTheme.PANEL_EDGE, 2, 12))
	return card


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _bar(share: float, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.value = clampf(share, 0.0, 1.0)
	bar.custom_minimum_size = Vector2(0, height)
	var back := UiTheme.box(UiTheme.INK, UiTheme.PANEL_EDGE, 1, 0)
	back.set_corner_radius_all(int(height / 2))
	bar.add_theme_stylebox_override("background", back)
	var fill := UiTheme.box(Color("7be08f") if share >= 1.0 else UiTheme.ACCENT, Color.TRANSPARENT, 0, 0)
	fill.set_corner_radius_all(int(height / 2))
	bar.add_theme_stylebox_override("fill", fill)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


static func _until_midnight() -> String:
	var now := Time.get_time_dict_from_system()
	var left := 86400 - (int(now["hour"]) * 3600 + int(now["minute"]) * 60 + int(now["second"]))
	return "%dh %dm" % [left / 3600, (left % 3600) / 60]
