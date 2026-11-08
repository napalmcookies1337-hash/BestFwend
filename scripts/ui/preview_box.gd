class_name PreviewBox
extends Control
## A small drawing area whose picture comes from a function: painter.call(self).

var painter: Callable


func _init(paint: Callable = Callable(), box_size := Vector2(120, 120)) -> void:
	painter = paint
	custom_minimum_size = box_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
