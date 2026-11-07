class_name SettingsPanel
extends PanelContainer
## Volume sliders, fullscreen and resetting progress. Writes straight to Game's settings.

const VOLUMES := {
	"master_volume": "Master volume",
	"music_volume": "Music",
	"sfx_volume": "Sound effects",
}

var sliders: Dictionary = {}
var fullscreen_toggle: CheckButton
var reset_dialog: ConfirmationDialog


func _ready() -> void:
	name = "SettingsPanel"
	custom_minimum_size = Vector2(560, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)

	for key: String in VOLUMES:
		var label := Label.new()
		label.text = VOLUMES[key]
		box.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.custom_minimum_size.y = 32
		slider.value_changed.connect(func(value: float) -> void: Game.set_setting(key, value))
		box.add_child(slider)
		sliders[key] = slider

	fullscreen_toggle = CheckButton.new()
	fullscreen_toggle.text = "Fullscreen  [F11]"
	fullscreen_toggle.focus_mode = Control.FOCUS_NONE
	fullscreen_toggle.toggled.connect(func(on: bool) -> void: Game.set_setting("fullscreen", on))
	box.add_child(fullscreen_toggle)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	var reset := Button.new()
	reset.text = "Reset all progress"
	reset.focus_mode = Control.FOCUS_NONE
	reset.add_theme_color_override("font_color", UiTheme.DANGER)
	reset.pressed.connect(func() -> void: reset_dialog.popup_centered())
	buttons.add_child(reset)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(spacer)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(hide)
	buttons.add_child(close)

	reset_dialog = ConfirmationDialog.new()
	reset_dialog.title = "Reset all progress?"
	reset_dialog.dialog_text = "This wipes your $$$, tools, skins and achievements.\nSettings are kept. This can't be undone."
	reset_dialog.ok_button_text = "Reset everything"
	reset_dialog.confirmed.connect(func() -> void:
		Game.reset_progress()
		Events.notification_posted.emit("Fresh start. Your fwend has forgotten everything."))
	add_child(reset_dialog)

	visibility_changed.connect(_on_visibility_changed)
	Events.settings_changed.connect(_refresh)
	_refresh()
	set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _on_visibility_changed() -> void:
	if visible:
		_refresh()
		set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _refresh() -> void:
	for key: String in sliders:
		(sliders[key] as HSlider).set_value_no_signal(Game.profile.settings[key])
	fullscreen_toggle.set_pressed_no_signal(Game.profile.settings["fullscreen"])
