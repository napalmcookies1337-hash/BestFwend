class_name PinNail
extends Node2D
## Nails a Buddy part (or any loose object) to the wall behind it.

var target: RigidBody2D
var anchor: StaticBody2D
var joint: PinJoint2D


func setup(at: Vector2, body: RigidBody2D) -> void:
	name = "PinNail"
	global_position = at
	target = body
	z_index = 9
	add_to_group(&"debris")
	add_to_group(&"pins")
	anchor = StaticBody2D.new()
	anchor.collision_layer = 0
	anchor.collision_mask = 0
	add_child(anchor)
	joint = PinJoint2D.new()
	joint.bias = 0.6
	joint.disable_collision = true
	add_child(joint)
	joint.node_a = joint.get_path_to(anchor)
	joint.node_b = joint.get_path_to(body)


func _process(_delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 11.0, Color("1e1426"))
	draw_circle(Vector2.ZERO, 8.0, Color("b8bec9"))
	draw_circle(Vector2(-2, -2), 3.0, Color("eef1f5"))
