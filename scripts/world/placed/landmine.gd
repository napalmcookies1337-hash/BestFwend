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
var power_scale := 1.0
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
	sandbox.explode(global_position + up * 20.0, BLAST[0] * sqrt(power_scale), BLAST[1] * power_scale, BLAST[2] * power_scale, BLAST[3], &"landmine")
	queue_free()


func _physics_process(delta: float) -> void:
	_age += delta
	if not armed and _age >= ARM_TIME:
		armed = true
	if armed and not _done and not get_overlapping_bodies().is_empty():
		detonate()
	queue_redraw()


func _draw() -> void:
	var lit := armed and fmod(_age, 0.6) < 0.2
	ToolArt.landmine(self, Art.place(Transform2D.IDENTITY, Vector2(0, -8), 0.0, 0.85), 4.0, lit)
