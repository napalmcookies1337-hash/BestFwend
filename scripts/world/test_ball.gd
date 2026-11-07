class_name TestBall
extends RigidBody2D
## A plain bouncy ball for testing collisions (F8 in debug runs). Real throwable
## objects arrive with the tools in Milestone 4.

const RADIUS := 40.0
const FILL := Color("e8534a")
const OUTLINE := Color("1e1426")


func _init() -> void:
	name = "TestBall"
	mass = 1.0
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	collider.shape = circle
	add_child(collider)
	collision_layer = Layers.OBJECTS
	collision_mask = Layers.WALLS | Layers.BUDDY | Layers.OBJECTS
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	var surface := PhysicsMaterial.new()
	surface.bounce = 0.35
	surface.friction = 0.6
	physics_material_override = surface
	add_to_group(&"grabbable")
	add_to_group(&"debris")


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS + 5, OUTLINE)
	draw_circle(Vector2.ZERO, RADIUS, FILL)
	draw_arc(Vector2.ZERO, RADIUS * 0.6, -PI * 0.9, -PI * 0.5, 8, Color(1, 1, 1, 0.5), 6.0, true)
	draw_line(Vector2(-RADIUS, 0), Vector2(RADIUS, 0), FILL.darkened(0.3), 4.0)
