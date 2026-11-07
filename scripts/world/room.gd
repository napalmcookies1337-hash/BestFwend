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

## Background themes. More are bought in Milestone 6.
const BACKGROUNDS := {
	"bedroom": {
		"wall": Color("3d5a80"),
		"stripe": Color("43638c"),
		"floor": Color("8a5a3b"),
		"plank": Color("74492f"),
		"trim": Color("f1e3cf"),
		"sky": Color("9fd8ff"),
		"sky_low": Color("ffd6a0"),
	},
}

var background_id := "bedroom"
var decals: Node2D
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
	decals = Node2D.new()
	decals.name = "Decals"
	add_child(decals)
	set_background(Game.profile.background)


## Where a fresh Buddy's torso appears: a short drop above the floor.
func spawn_point() -> Vector2:
	return Vector2(SIZE.x / 2, FLOOR_Y - 340)


## The open space inside the walls.
func interior() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(SIZE.x, FLOOR_Y))


func set_background(id: String) -> void:
	background_id = id if BACKGROUNDS.has(id) else "bedroom"
	queue_redraw()


func clear_decals() -> void:
	for child in decals.get_children():
		child.queue_free()


func _add_wall(wall_name: String, rect: Rect2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collider := CollisionShape2D.new()
	collider.name = wall_name
	collider.shape = shape
	collider.position = rect.get_center()
	walls.add_child(collider)


func _draw() -> void:
	var colors: Dictionary = BACKGROUNDS[background_id]
	# Wall with wallpaper stripes.
	draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE.x, FLOOR_Y)), colors["wall"])
	var stripe_width := 60.0
	var x := 0.0
	while x < SIZE.x:
		draw_rect(Rect2(x, 0, stripe_width / 2, FLOOR_Y), colors["stripe"])
		x += stripe_width
	# Window.
	var window := Rect2(1300, 170, 380, 300)
	draw_rect(window.grow(18), colors["trim"])
	var sky_top: Color = colors["sky"]
	var sky_bottom: Color = colors["sky_low"]
	var steps := 12
	for index in steps:
		var band := Rect2(window.position.x, window.position.y + window.size.y * index / steps,
				window.size.x, window.size.y / steps + 1)
		draw_rect(band, sky_top.lerp(sky_bottom, float(index) / (steps - 1)))
	draw_circle(window.position + Vector2(280, 90), 34, Color("fff4c2"))
	draw_rect(Rect2(window.get_center().x - 7, window.position.y, 14, window.size.y), colors["trim"])
	draw_rect(Rect2(window.position.x, window.get_center().y - 7, window.size.x, 14), colors["trim"])
	draw_rect(Rect2(window.position.x - 30, window.end.y + 18, window.size.x + 60, 22), colors["trim"].darkened(0.08))
	# Floor planks.
	draw_rect(Rect2(0, FLOOR_Y, SIZE.x, SIZE.y - FLOOR_Y), colors["floor"])
	var plank_height := 38.0
	var row := 0
	var y := FLOOR_Y + plank_height
	while y < SIZE.y:
		draw_line(Vector2(0, y), Vector2(SIZE.x, y), colors["plank"], 4)
		var offset := 0.0 if row % 2 == 0 else 160.0
		var seam := offset
		while seam < SIZE.x:
			draw_line(Vector2(seam, y - plank_height), Vector2(seam, y), colors["plank"], 4)
			seam += 320.0
		y += plank_height
		row += 1
	# Baseboard and a soft shadow where wall meets floor.
	draw_rect(Rect2(0, FLOOR_Y - 26, SIZE.x, 26), colors["trim"])
	draw_rect(Rect2(0, FLOOR_Y, SIZE.x, 10), Color(0, 0, 0, 0.18))
