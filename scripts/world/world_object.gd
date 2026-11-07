class_name WorldObject
extends RigidBody2D
## A physical thing a tool puts in the room: balls, bricks, anvils, grenades,
## rockets, nukes. Kinds are data in KINDS. Explosive kinds blow up on a fuse or on
## impact through the sandbox's explode().

## Explosion for explosive kinds: radius, push (px/s at the centre), damage, sever chance.
## "impact" scales how hard a hit from this object counts against the Buddy: a
## ball bounces off, an anvil crushes.
const KINDS := {
	&"ball": {"shape": "circle", "size": Vector2(36, 0), "mass": 1.0, "bounce": 0.65, "friction": 0.5,
		"color": Color("e8534a"), "impact_scale": 0.7},
	&"brick": {"shape": "rect", "size": Vector2(78, 38), "mass": 4.0, "bounce": 0.05, "friction": 0.9,
		"color": Color("b5503c"), "impact_scale": 1.3},
	&"anvil": {"shape": "anvil", "size": Vector2(120, 66), "mass": 30.0, "bounce": 0.0, "friction": 0.9,
		"color": Color("4b4f5c"), "impact_scale": 2.2},
	&"grenade": {"shape": "circle", "size": Vector2(20, 0), "mass": 0.7, "bounce": 0.3, "friction": 0.7,
		"color": Color("4f6b2e"), "fuse": 3.0, "blast": [280.0, 2600.0, 55.0, 0.5]},
	&"rocket": {"shape": "capsule", "size": Vector2(13, 64), "mass": 2.0, "bounce": 0.0, "friction": 0.2,
		"color": Color("d9dde3"), "fuse": 4.0, "impact": true, "gravity": 0.0, "blast": [270.0, 2800.0, 50.0, 0.55]},
	&"nuke": {"shape": "capsule", "size": Vector2(30, 116), "mass": 25.0, "bounce": 0.0, "friction": 0.5,
		"color": Color("e9d24a"), "impact": true, "blast": [1100.0, 5200.0, 170.0, 0.85]},
}
const OUTLINE := Color("1e1426")

var kind: StringName = &"ball"
var spec: Dictionary = {}
var sandbox: Node
var fuse := -1.0
var armed_time := 0.0
var _exploded := false


func setup(object_kind: StringName, owner_sandbox: Node) -> void:
	kind = object_kind
	spec = KINDS[kind]
	sandbox = owner_sandbox
	name = String(kind).capitalize()
	mass = spec["mass"]
	gravity_scale = spec.get("gravity", 1.0)
	fuse = spec.get("fuse", -1.0)
	var collider := CollisionShape2D.new()
	var size: Vector2 = spec["size"]
	match spec["shape"]:
		"circle":
			var circle := CircleShape2D.new()
			circle.radius = size.x
			collider.shape = circle
		"capsule":
			var capsule := CapsuleShape2D.new()
			capsule.radius = size.x
			capsule.height = size.y
			collider.shape = capsule
			collider.rotation = PI / 2
		_:
			var rect := RectangleShape2D.new()
			rect.size = size
			collider.shape = rect
	add_child(collider)
	collision_layer = Layers.OBJECTS
	collision_mask = Layers.WALLS | Layers.BUDDY | Layers.OBJECTS
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	var surface := PhysicsMaterial.new()
	surface.bounce = spec["bounce"]
	surface.friction = spec["friction"]
	physics_material_override = surface
	add_to_group(&"debris")
	if kind != &"rocket":
		add_to_group(&"grabbable")
	if is_explosive():
		add_to_group(&"explosive")
	if spec.get("impact", false):
		contact_monitor = true
		max_contacts_reported = 2
		body_entered.connect(_on_body_entered)


func is_explosive() -> bool:
	return spec.has("blast")


## Lights a short fuse, for chain reactions.
func prime(seconds: float) -> void:
	if is_explosive() and not _exploded:
		fuse = seconds if fuse < 0.0 else minf(fuse, seconds)


func detonate() -> void:
	if _exploded or not is_explosive():
		return
	_exploded = true
	var blast: Array = spec["blast"]
	sandbox.explode(global_position, blast[0], blast[1], blast[2], blast[3], kind)
	queue_free()


func _physics_process(delta: float) -> void:
	armed_time += delta
	if kind == &"rocket" and linear_velocity.length() > 50.0:
		rotation = linear_velocity.angle()
	if fuse >= 0.0:
		fuse -= delta
		if fuse <= 0.0:
			detonate()
	queue_redraw()


func _on_body_entered(_body: Node) -> void:
	if armed_time > 0.05:
		detonate.call_deferred()


func _draw() -> void:
	var size: Vector2 = spec["size"]
	var color: Color = spec["color"]
	match kind:
		&"ball":
			draw_circle(Vector2.ZERO, size.x + 5, OUTLINE)
			draw_circle(Vector2.ZERO, size.x, color)
			draw_arc(Vector2.ZERO, size.x * 0.6, -PI * 0.9, -PI * 0.5, 8, Color(1, 1, 1, 0.5), 6.0, true)
		&"brick":
			draw_rect(Rect2(-size / 2 - Vector2.ONE * 4, size + Vector2.ONE * 8), OUTLINE)
			draw_rect(Rect2(-size / 2, size), color)
			draw_line(Vector2(-size.x / 2, 0), Vector2(size.x / 2, 0), color.darkened(0.3), 3.0)
			draw_line(Vector2(-6, -size.y / 2), Vector2(-6, 0), color.darkened(0.3), 3.0)
			draw_line(Vector2(14, 0), Vector2(14, size.y / 2), color.darkened(0.3), 3.0)
		&"anvil":
			var body := PackedVector2Array([Vector2(-60, -33), Vector2(60, -33), Vector2(44, -12),
					Vector2(22, -6), Vector2(26, 22), Vector2(48, 33), Vector2(-48, 33), Vector2(-26, 22),
					Vector2(-22, -6), Vector2(-70, -18)])
			var grown := PackedVector2Array()
			for point in body:
				grown.append(point * 1.08)
			draw_colored_polygon(grown, OUTLINE)
			draw_colored_polygon(body, color)
			draw_line(Vector2(-56, -28), Vector2(52, -28), color.lightened(0.35), 4.0)
		&"grenade":
			draw_circle(Vector2.ZERO, size.x + 4, OUTLINE)
			draw_circle(Vector2.ZERO, size.x, color)
			draw_rect(Rect2(-6, -size.x - 10, 12, 10), Color("8b8f99"))
			var blink := fuse > 0.0 and fmod(fuse, maxf(fuse * 0.25, 0.08)) < 0.06
			draw_circle(Vector2(0, -size.x - 12), 4.0, Color("ff3b3b") if blink else Color("5c1a1a"))
		&"rocket":
			draw_colored_polygon(PackedVector2Array([Vector2(-32, -14), Vector2(24, -14), Vector2(44, 0), Vector2(24, 14), Vector2(-32, 14)]), OUTLINE)
			draw_rect(Rect2(-28, -10, 50, 20), color)
			draw_colored_polygon(PackedVector2Array([Vector2(22, -10), Vector2(38, 0), Vector2(22, 10)]), Color("d63b3b"))
			draw_colored_polygon(PackedVector2Array([Vector2(-34, -6), Vector2(-48 - randf() * 16, 0), Vector2(-34, 6)]), Color("ffb02e"))
		&"nuke":
			draw_colored_polygon(PackedVector2Array([Vector2(-64, -34), Vector2(40, -34), Vector2(68, 0), Vector2(40, 34), Vector2(-64, 34)]), OUTLINE)
			draw_rect(Rect2(-60, -28, 100, 56), color)
			draw_circle(Vector2(-6, 0), 16, OUTLINE)
			for blade in 3:
				var angle := TAU * blade / 3.0
				draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(-6, 0) + Vector2.from_angle(angle - 0.5) * 14, Vector2(-6, 0) + Vector2.from_angle(angle + 0.5) * 14]), color)
			draw_rect(Rect2(-74, -24, 14, 48), Color("8b8f99"))
