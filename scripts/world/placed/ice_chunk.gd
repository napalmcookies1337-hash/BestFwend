class_name IceChunk
extends RigidBody2D
## A frozen piece of a shattered Buddy: a jagged shard of skin-coloured ice that
## tumbles, can be grabbed and thrown, and melts away after a while.

const MELT_AFTER := 9.0
const MELT_TIME := 1.5
const ICE := Color("bfe9ff")

var tint := Color("ffa646")
var points := PackedVector2Array()
var _age := 0.0


func setup(skin: Color, size: float, rng: RandomNumberGenerator) -> void:
	name = "IceChunk"
	tint = skin.lerp(ICE, 0.55)
	var corners := rng.randi_range(5, 7)
	for index in corners:
		var angle := TAU * index / corners + rng.randf_range(-0.3, 0.3)
		points.append(Vector2.from_angle(angle) * size * rng.randf_range(0.55, 1.0))
	# Random jitter can make a dent; physics needs the shape convex.
	var hull := Geometry2D.convex_hull(points)
	if hull.size() > 1 and hull[0] == hull[hull.size() - 1]:
		hull.remove_at(hull.size() - 1)
	points = hull
	var shape := ConvexPolygonShape2D.new()
	shape.points = points
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	mass = maxf(size / 30.0, 0.3)
	collision_layer = Layers.OBJECTS
	collision_mask = Layers.WALLS | Layers.BUDDY | Layers.OBJECTS
	var surface := PhysicsMaterial.new()
	surface.bounce = 0.25
	surface.friction = 0.3
	physics_material_override = surface
	add_to_group(&"debris")
	add_to_group(&"grabbable")


func _process(delta: float) -> void:
	_age += delta
	if _age >= MELT_AFTER + MELT_TIME:
		queue_free()
	elif _age >= MELT_AFTER:
		modulate.a = 1.0 - (_age - MELT_AFTER) / MELT_TIME
		scale = Vector2.ONE * (1.0 - (_age - MELT_AFTER) / MELT_TIME * 0.4)


func _draw() -> void:
	Art.shape(self, Transform2D.IDENTITY, points, tint, 3.5)
	var box := Art.bounds(points)
	draw_line(box.position * 0.4, box.position * 0.4 + Vector2(box.size.x * 0.25, -2), Color(1, 1, 1, 0.8), 3.0, true)
