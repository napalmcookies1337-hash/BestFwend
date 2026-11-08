class_name MinigamesPanel
extends PanelContainer
## The minigame menu: each game with how to play, your best score and a Play button.

signal minigame_chosen(minigame_id: StringName)

var body: VBoxContainer


func _ready() -> void:
	name = "MinigamesPanel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "Minigames"
	title.add_theme_font_size_override("font_size", 40)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(hide)
	header.add_child(close)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	box.add_child(body)
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


func _rebuild() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for minigame_id: StringName in Minigames.LIST:
		var spec: Array = Minigames.LIST[minigame_id]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BUTTON.darkened(0.15), UiTheme.PANEL_EDGE, 2, 14))
		card.custom_minimum_size = Vector2(760, 0)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		card.add_child(row)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var name_label := Label.new()
		name_label.text = spec[1]
		name_label.add_theme_font_size_override("font_size", 30)
		column.add_child(name_label)
		var how := Label.new()
		how.text = spec[2]
		how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		how.custom_minimum_size.x = 540
		how.add_theme_font_size_override("font_size", 17)
		how.add_theme_color_override("font_color", UiTheme.MUTED)
		column.add_child(how)
		var best := float(Game.profile.best_scores.get(String(minigame_id), 0.0))
		var best_label := Label.new()
		best_label.text = "Best: " + (Minigames.best_text(minigame_id, best) if best > 0.0 else "none yet")
		best_label.add_theme_font_size_override("font_size", 18)
		best_label.add_theme_color_override("font_color", UiTheme.ACCENT)
		column.add_child(best_label)
		var play := Button.new()
		play.text = "Play"
		play.focus_mode = Control.FOCUS_NONE
		play.custom_minimum_size = Vector2(140, 64)
		play.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		play.add_theme_font_size_override("font_size", 28)
		play.pressed.connect(func() -> void:
			hide()
			minigame_chosen.emit(minigame_id))
		row.add_child(play)
		body.add_child(card)
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
