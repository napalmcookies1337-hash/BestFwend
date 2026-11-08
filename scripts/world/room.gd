class_name Room
extends Node2D
## The box the Buddy lives in: a drawn background, solid walls, and the decal layer
## where blood and scorch marks will stay (Milestone 2-3).

const SIZE := Vector2(1920, 1080)
## High enough that the toolbar sits on the floorboards, never over the Buddy's feet.
const FLOOR_Y := 880.0
const WALL_THICKNESS := 400.0
const BOUNCE := 0.3
const FRICTION := 0.9

var background_id := "bedroom"
var decals: DecalLayer
var walls: StaticBody2D


func _ready() -> void:
	name = "Room"
	walls = StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = Layers.WALLS
	walls.collision_mask = 0
	var wall_material := PhysicsMaterial.new()
	wall_material.bounce = BOUNCE
	wall_material.friction = FRICTION
	walls.physics_material_override = wall_material
	add_child(walls)
	var half := WALL_THICKNESS / 2
	_add_wall("Floor", Rect2(-WALL_THICKNESS, FLOOR_Y, SIZE.x + WALL_THICKNESS * 2, WALL_THICKNESS))
	_add_wall("Ceiling", Rect2(-WALL_THICKNESS, -WALL_THICKNESS, SIZE.x + WALL_THICKNESS * 2, WALL_THICKNESS))
	_add_wall("LeftWall", Rect2(-WALL_THICKNESS, -half, WALL_THICKNESS, SIZE.y + WALL_THICKNESS))
	_add_wall("RightWall", Rect2(SIZE.x, -half, WALL_THICKNESS, SIZE.y + WALL_THICKNESS))
	decals = DecalLayer.new()
	add_child(decals)
	set_background(Game.profile.background)


## Where a fresh Buddy's torso appears: a short drop above the floor.
func spawn_point() -> Vector2:
	return Vector2(SIZE.x / 2, FLOOR_Y - 340)


## The open space inside the walls.
func interior() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(SIZE.x, FLOOR_Y))


func set_background(id: String) -> void:
	background_id = id if Cosmetics.ROOMS.has(id) else "bedroom"
	queue_redraw()


func clear_decals() -> void:
	decals.clear()


func _add_wall(wall_name: String, rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collider := CollisionShape2D.new()
	collider.name = wall_name
	collider.shape = shape
	collider.position = rect.get_center()
	walls.add_child(collider)


func _draw() -> void:
	BackgroundArt.draw(self, background_id)
