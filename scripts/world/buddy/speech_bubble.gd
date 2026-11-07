class_name SpeechBubble
extends Node2D
## A comic speech bubble that follows the Buddy's head, types its text out with
## babble sounds, and stays on screen. Always upright, whatever the head is doing.

const FONT_SIZE := 30
const MAX_WIDTH := 380.0
const CHARS_PER_SECOND := 38.0
const BASE_SECONDS := 1.4
const SECONDS_PER_CHAR := 0.045
const ABOVE_HEAD := 26.0
const TAIL := 22.0
const SCREEN_MARGIN := 16.0
const FILL := Color("fffaf2")
const EDGE := Color("1e1426")
const INK := Color("1e1426")
## Babble once per this many typed letters.
const LETTERS_PER_BLIP := 2

var buddy: Buddy
var text := ""
var priority := -1
var time_left := 0.0
var panel: PanelContainer
var label: Label
var _typed := 0.0
var _blips := 0


func _ready() -> void:
	z_index = 20
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = FILL
	style.border_color = EDGE
	style.set_border_width_all(4)
	style.set_corner_radius_all(22)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 12
	style.anti_aliasing = true
	panel.add_theme_stylebox_override("panel", style)
	label = Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	add_child(panel)
	hide()


func is_talking() -> bool:
	return visible and time_left > 0.0


func say(line: String, line_priority: int) -> void:
	text = line
	priority = line_priority
	time_left = BASE_SECONDS + SECONDS_PER_CHAR * line.length()
	_typed = 0.0
	_blips = 0
	label.text = line
	label.visible_characters = 0
	# Measure one line first; wrap only if it's too wide.
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size = Vector2.ZERO
	panel.reset_size()
	if label.get_minimum_size().x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(MAX_WIDTH, 0)
	panel.reset_size()
	show()
	scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play(&"pop", -10.0)


func silence() -> void:
	time_left = 0.0
	priority = -1
	hide()


func _process(delta: float) -> void:
	if not visible:
		return
	time_left -= delta
	if time_left <= 0.0:
		silence()
		return
	if label.visible_characters >= 0 and label.visible_characters < text.length():
		_typed += delta * CHARS_PER_SECOND
		var shown := mini(int(_typed), text.length())
		for index in range(label.visible_characters, shown):
			var letter := text[index]
			if letter != " " and letter != "." and letter != "*":
				_blips += 1
				if _blips % LETTERS_PER_BLIP == 1:
					Sfx.babble(buddy.voice_pitch)
		label.visible_characters = shown
		if shown >= text.length():
			label.visible_characters = -1
	_place()
	queue_redraw()


func _place() -> void:
	var head := buddy.head
	var anchor := head.global_position - Vector2(0, head.radius + ABOVE_HEAD)
	var box := panel.size
	# Keep below the money counter and the top button row.
	var screen := Rect2(SCREEN_MARGIN, 110.0, Room.SIZE.x - SCREEN_MARGIN * 2, Room.FLOOR_Y - 110.0)
	var left := clampf(anchor.x - box.x / 2, screen.position.x, screen.end.x - box.x)
	var top := clampf(anchor.y - box.y - TAIL, screen.position.y, screen.end.y - box.y)
	global_position = Vector2(left + box.x / 2, top + box.y)
	panel.position = Vector2(-box.x / 2, -box.y)


func _draw() -> void:
	if not visible:
		return
	var head := buddy.head
	var mouth := to_local(head.global_position - Vector2(0, head.radius * 0.6))
	var tip := mouth.limit_length(maxf(mouth.length() - 8.0, 0.0))
	tip = tip.limit_length(TAIL + 40.0)
	var base_half := 14.0
	var left := Vector2(-base_half, -6)
	var right := Vector2(base_half, -6)
	draw_colored_polygon(PackedVector2Array([left + Vector2(-4, 0), right + Vector2(4, 0), tip + tip.normalized() * 5.0]), EDGE)
	draw_colored_polygon(PackedVector2Array([left, right, tip]), FILL)
