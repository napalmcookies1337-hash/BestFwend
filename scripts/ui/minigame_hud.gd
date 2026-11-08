class_name MinigameHud
extends Control
## The minigame's banner (title, clock, score, hint, Quit) and its results card.

signal quit_pressed
signal again_pressed(minigame_id: StringName)

var banner: PanelContainer
var results: PanelContainer
var title_label: Label
var clock_label: Label
var score_label: Label
var hint_label: Label
var result_title: Label
var result_score: Label
var result_best: Label
var result_reward: Label
var _last_id: StringName


func _ready() -> void:
	name = "MinigameHud"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	banner = PanelContainer.new()
	add_child(banner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	banner.add_child(row)
	var info := VBoxContainer.new()
	row.add_child(info)
	title_label = _label(30, Color("f2c14e"))
	info.add_child(title_label)
	hint_label = _label(18, UiTheme.MUTED)
	info.add_child(hint_label)
	clock_label = _label(44, UiTheme.TEXT)
	clock_label.custom_minimum_size.x = 110
	row.add_child(clock_label)
	score_label = _label(44, UiTheme.MONEY)
	score_label.custom_minimum_size.x = 260
	row.add_child(score_label)
	var quit := Button.new()
	quit.text = "Quit"
	quit.focus_mode = Control.FOCUS_NONE
	quit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	quit.pressed.connect(quit_pressed.emit)
	row.add_child(quit)
	banner.hide()

	results = PanelContainer.new()
	add_child(results)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	results.add_child(column)
	result_title = _label(34, Color("f2c14e"))
	column.add_child(result_title)
	result_score = _label(56, UiTheme.TEXT)
	column.add_child(result_score)
	result_best = _label(22, UiTheme.ACCENT)
	column.add_child(result_best)
	result_reward = _label(28, UiTheme.MONEY)
	column.add_child(result_reward)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	column.add_child(buttons)
	var again := Button.new()
	again.text = "Play again"
	again.focus_mode = Control.FOCUS_NONE
	again.pressed.connect(func() -> void:
		results.hide()
		again_pressed.emit(_last_id))
	buttons.add_child(again)
	var done := Button.new()
	done.text = "Done"
	done.focus_mode = Control.FOCUS_NONE
	done.pressed.connect(results.hide)
	buttons.add_child(done)
	for label: Label in [result_title, result_score, result_best, result_reward]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results.hide()

	Events.listen(self, Events.minigame_started, func(_id: StringName) -> void:
		results.hide()
		banner.show())
	Events.minigame_updated.connect(show_info)
	Events.minigame_finished.connect(show_results)


func show_info(info: Dictionary) -> void:
	banner.show()
	title_label.text = info.get("title", "")
	hint_label.text = info.get("hint", "")
	var left: float = info.get("time_left", -1.0)
	clock_label.text = ("%d:%02d" % [int(left) / 60, int(left) % 60]) if left >= 0.0 else ""
	score_label.text = info.get("score_text", "")
	banner.reset_size()
	banner.position = Vector2((size.x - banner.size.x) / 2.0, 18.0)


func show_results(result: Dictionary) -> void:
	banner.hide()
	_last_id = result["id"]
	result_title.text = "%s: results" % result["title"]
	result_score.text = result["score_text"]
	result_best.text = "NEW BEST!" if result["new_best"] else "Best: " + Minigames.best_text(result["id"], result["best"])
	result_reward.text = "+" + Fmt.money(result["reward"])
	results.show()
	results.reset_size()
	results.custom_minimum_size = Vector2(520, 0)
	results.reset_size()
	results.position = ((size - results.size) / 2.0).round()


func hide_all() -> void:
	banner.hide()
	results.hide()


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
