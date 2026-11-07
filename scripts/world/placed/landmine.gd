class_name Landmine
extends Area2D
## Sits on a surface and blows up when the Buddy or anything else touches it.

const ARM_TIME := 0.7
const BLAST := [260.0, 3000.0, 60.0, 0.6]
const SIZE := Vector2(70, 22)

var sandbox: Node
## Points away from the surface it sits on.
var up := Vector2.UP
var armed := false
var _age := 0.0
var _done := false


func setup(owner_sandbox: Node, surface_up: Vector2) -> void:
	sandbox = owner_sandbox
	up = surface_up
	name = "Landmine"
	rotation = up.angle() + PI / 2
	var shape := RectangleShape2D.new()
	shape.size = SIZE + Vector2(0, 30)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(0, -12)
	add_child(collider)
	collision_layer = 0
	collision_mask = Layers.BUDDY | Layers.OBJECTS
	monitoring = true
	add_to_group(&"debris")
	add_to_group(&"explosive")


func prime(seconds: float) -> void:
	if not _done:
		get_tree().create_timer(seconds, false).timeout.connect(detonate)


func detonate() -> void:
	if _done:
		return
	_done = true
	sandbox.explode(global_position + up * 20.0, BLAST[0], BLAST[1], BLAST[2], BLAST[3], &"landmine")
	queue_free()


func _physics_process(delta: float) -> void:
	_age += delta
	if not armed and _age >= ARM_TIME:
		armed = true
	if armed and not _done and not get_overlapping_bodies().is_empty():
		detonate()
	queue_redraw()


func _draw() -> void:
	var outline := Color("1e1426")
	draw_rect(Rect2(-SIZE.x / 2 - 4, -SIZE.y - 4, SIZE.x + 8, SIZE.y + 4), outline)
	draw_rect(Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y), Color("5d6650"))
	draw_rect(Rect2(-14, -SIZE.y - 10, 28, 10), outline)
	draw_rect(Rect2(-10, -SIZE.y - 8, 20, 8), Color("8b8f99"))
	var lit := armed and fmod(_age, 0.6) < 0.2
	draw_circle(Vector2(22, -SIZE.y + 7), 4.0, Color("ff3b3b") if lit else Color("5c1a1a"))
