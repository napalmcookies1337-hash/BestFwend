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
	var ink := 4.0
	var origin := Transform2D.IDENTITY
	match kind:
		&"ball":
			ToolArt.ball(self, Art.place(origin, Vector2.ZERO, 0.0, 36.0 / 42.0), ink)
		&"brick":
			ToolArt.brick(self, origin, ink)
		&"anvil":
			ToolArt.anvil(self, Art.place(origin, Vector2(5, -5), 0.0, 1.25), ink)
		&"grenade":
			ToolArt.grenade(self, Art.place(origin, Vector2(0, -5), 0.0, 0.62), ink * 0.8)
			var blink := fuse > 0.0 and fmod(fuse, maxf(fuse * 0.25, 0.08)) < 0.06
			if blink:
				draw_circle(Vector2(0, -22), 6.0, Color(1.0, 0.25, 0.2, 0.9))
		&"rocket":
			ToolArt.rocket(self, Art.place(origin, Vector2(-4, 0), PI / 2, 0.72), ink * 0.8, randf())
		&"nuke":
			ToolArt.nuke(self, Art.place(origin, Vector2(-4, 0), -PI / 2, 1.1), ink)