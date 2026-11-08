class_name TargetBoard
extends Node2D
## The bullseye in Target Toss. Pops in when it moves and bobs gently.

const RADIUS := 70.0

var _age := 0.0


func _ready() -> void:
	name = "TargetBoard"
	z_index = 3


func place(at: Vector2) -> void:
	position = at
	_age = 0.0


func _process(delta: float) -> void:
	_age += delta
	scale = Vector2.ONE * (minf(_age / 0.2, 1.0) * (1.0 + sin(_age * 3.0) * 0.03))
	queue_redraw()


func _draw() -> void:
	var origin := Transform2D.IDENTITY
	Art.shape(self, origin, Art.circle(RADIUS, Vector2.ZERO, 48), Color("e8473c"), 5.0)
	Art.flat(self, origin, Art.circle(RADIUS * 0.72, Vector2.ZERO, 40), Color("fff6ea"))
	Art.flat(self, origin, Art.circle(RADIUS * 0.46, Vector2.ZERO, 32), Color("e8473c"))
	Art.flat(self, origin, Art.circle(RADIUS * 0.2, Vector2.ZERO, 20), Color("fff6ea"))
