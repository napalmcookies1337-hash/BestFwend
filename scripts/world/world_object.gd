class_name WorldObject
extends RigidBody2D
## A physical thing a tool puts in the room: balls, bricks, anvils, grenades,
## rockets, nukes, pianos, saw blades, meteors... Kinds are data in KINDS.
## Explosive kinds blow up on a fuse or on impact through the sandbox's explode().
##
## Spec keys: shape/size/mass/bounce/friction, "impact_scale" (how hard its hits
## count against the Buddy), "gravity", "fuse", "impact" (explode on contact),
## "blast" [radius, push, damage, sever chance], "lifetime" (fades away after),
## "saw" (cuts limbs off on contact), "chord" (crashes musically), "split" (bursts
## into bomblets), "ignite" (sets nearby Buddies on fire when it blows), "spin".

const KINDS := {
	&"ball": {"shape": "circle", "size": Vector2(36, 0), "mass": 1.0, "bounce": 0.65, "friction": 0.5,
		"impact_scale": 0.7},
	&"brick": {"shape": "rect", "size": Vector2(78, 38), "mass": 4.0, "bounce": 0.05, "friction": 0.9,
		"impact_scale": 1.3},
	&"anvil": {"shape": "anvil", "size": Vector2(120, 66), "mass": 30.0, "bounce": 0.0, "friction": 0.9,
		"impact_scale": 2.2, "gravity": 1.8},
	&"grenade": {"shape": "circle", "size": Vector2(20, 0), "mass": 0.7, "bounce": 0.3, "friction": 0.7,
		"fuse": 3.0, "blast": [280.0, 2600.0, 55.0, 0.5]},
	&"rocket": {"shape": "capsule", "size": Vector2(13, 64), "mass": 2.0, "bounce": 0.0, "friction": 0.2,
		"fuse": 4.0, "impact": true, "gravity": 0.0, "blast": [270.0, 2800.0, 50.0, 0.55], "faces_motion": true},
	&"nuke": {"shape": "capsule", "size": Vector2(30, 116), "mass": 25.0, "bounce": 0.0, "friction": 0.5,
		"impact": true, "blast": [1100.0, 5200.0, 170.0, 0.85]},
	# Prestige weapons.
	&"fist": {"shape": "rect", "size": Vector2(170, 150), "mass": 70.0, "bounce": 0.1, "friction": 0.8,
		"impact_scale": 3.0, "gravity": 2.5, "lifetime": 1.6},
	&"piano": {"shape": "rect", "size": Vector2(230, 150), "mass": 55.0, "bounce": 0.05, "friction": 0.9,
		"impact_scale": 2.8, "gravity": 1.7, "chord": true, "lifetime": 9.0},
	&"sawblade": {"shape": "circle", "size": Vector2(28, 0), "mass": 1.5, "bounce": 1.0, "friction": 0.0,
		"gravity": 0.0, "saw": true, "lifetime": 6.0, "spin": 40.0},
	&"wrecking_ball": {"shape": "circle", "size": Vector2(72, 0), "mass": 80.0, "bounce": 0.2, "friction": 0.6,
		"impact_scale": 2.6, "lifetime": 12.0},
	&"cluster": {"shape": "circle", "size": Vector2(26, 0), "mass": 1.2, "bounce": 0.3, "friction": 0.7,
		"fuse": 2.0, "blast": [200.0, 2000.0, 30.0, 0.3], "split": 8},
	&"bomblet": {"shape": "circle", "size": Vector2(12, 0), "mass": 0.3, "bounce": 0.4, "friction": 0.7,
		"fuse": 1.0, "blast": [170.0, 1900.0, 26.0, 0.35]},
	&"missile": {"shape": "capsule", "size": Vector2(14, 70), "mass": 3.0, "bounce": 0.0, "friction": 0.2,
		"fuse": 4.0, "impact": true, "gravity": 0.0, "blast": [240.0, 2600.0, 45.0, 0.5], "faces_motion": true},
	&"meteor": {"shape": "circle", "size": Vector2(30, 0), "mass": 6.0, "bounce": 0.0, "friction": 0.5,
		"fuse": 5.0, "impact": true, "gravity": 0.6, "blast": [170.0, 1800.0, 24.0, 0.25], "ignite": 170.0},
}
const FADE_TIME := 0.5

var kind: StringName = &"ball"
var spec: Dictionary = {}
var sandbox: Node
## Upgrades make blasts bigger: push and damage scale with this, radius with its root.
var power_scale := 1.0
var fuse := -1.0
var armed_time := 0.0
## Where a wrecking ball's chain is fixed to the ceiling.
var anchor := Vector2.ZERO
var _exploded := false
var _played_chord := false


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
	if not spec.get("faces_motion", false) and kind != &"sawblade":
		add_to_group(&"grabbable")
	if is_explosive():
		add_to_group(&"explosive")
	if spec.get("impact", false) or spec.get("saw", false) or spec.get("chord", false):
		contact_monitor = true
		max_contacts_reported = 3
		body_entered.connect(_on_body_entered)
	if spec.has("spin"):
		angular_velocity = spec["spin"]


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
	sandbox.explode(global_position, blast[0] * sqrt(power_scale), blast[1] * power_scale, blast[2] * power_scale, blast[3], kind)
	if spec.has("split"):
		for index in int(spec["split"]):
			var direction := Vector2.from_angle(TAU * index / spec["split"] + randf_range(-0.2, 0.2))
			var bomblet: WorldObject = sandbox.spawn_object(&"bomblet", global_position + direction * 30.0,
					direction * randf_range(700.0, 1200.0) + Vector2(0, -400), power_scale)
			bomblet.fuse = randf_range(0.5, 1.2)
	if spec.has("ignite"):
		for someone: Buddy in sandbox.buddies():
			if someone.torso.global_position.distance_to(global_position) < spec["ignite"]:
				someone.ignite(3.0)
	queue_free()


func _physics_process(delta: float) -> void:
	armed_time += delta
	if spec.get("faces_motion", false) and linear_velocity.length() > 50.0:
		rotation = linear_velocity.angle()
	if fuse >= 0.0:
		fuse -= delta
		if fuse <= 0.0:
			detonate()
	if spec.has("lifetime"):
		var left: float = spec["lifetime"] - armed_time
		if left <= 0.0:
			queue_free()
		elif left < FADE_TIME:
			modulate.a = left / FADE_TIME
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if armed_time <= 0.05:
		return
	if spec.get("impact", false):
		detonate.call_deferred()
	if spec.get("chord", false) and not _played_chord and linear_velocity.length() > 300.0:
		_played_chord = true
		Sfx.play(&"piano_crash", 0.0)
		sandbox.add_shake(18.0)
	if spec.get("saw", false) and body is BuddyPart and not (body as BuddyPart).detached:
		_saw(body as BuddyPart)


func _saw(part: BuddyPart) -> void:
	var victim := part.get_parent() as Buddy
	if victim == null:
		return
	Sfx.play(&"slice", -2.0, 1.3)
	if Buddy.LIMBS.has(part.part_name):
		victim.sever(part.part_name, linear_velocity * 0.4, &"saw_launcher")
	else:
		victim.take_hit({"part": part.part_name, "force": 2600.0 * power_scale, "damage": 22.0 * power_scale,
				"source": &"saw_launcher", "position": part.global_position})


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
			_blink(Vector2(0, -22))
		&"rocket":
			ToolArt.rocket(self, Art.place(origin, Vector2(-4, 0), PI / 2, 0.72), ink * 0.8, randf())
		&"nuke":
			ToolArt.nuke(self, Art.place(origin, Vector2(-4, 0), -PI / 2, 1.1), ink)
		&"fist":
			ToolArt.giant_fist(self, Art.place(origin, Vector2(0, 0), 0.0, 1.7), ink)
		&"piano":
			ToolArt.piano(self, Art.place(origin, Vector2.ZERO, 0.0, 2.3), ink)
		&"sawblade":
			ToolArt.sawblade(self, Art.place(origin, Vector2.ZERO, 0.0, 28.0 / 40.0), ink * 0.8)
		&"wrecking_ball":
			draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
			_draw_chain(to_local(anchor).rotated(rotation))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			ToolArt.wrecking_ball(self, Art.place(origin, Vector2.ZERO, 0.0, 72.0 / 44.0), ink)
		&"cluster":
			ToolArt.cluster_bomb(self, Art.place(origin, Vector2(0, -2), 0.0, 0.62), ink * 0.8)
			_blink(Vector2(0, -26))
		&"bomblet":
			ToolArt.bomblet(self, Art.place(origin, Vector2.ZERO, 0.0, 0.5), 3.0)
		&"missile":
			ToolArt.rocket(self, Art.place(origin, Vector2(-4, 0), PI / 2, 0.78), ink * 0.8, randf())
		&"meteor":
			ToolArt.meteor(self, Art.place(origin, Vector2.ZERO, linear_velocity.angle() - rotation - PI / 2, 0.9), ink, armed_time)


func _blink(at: Vector2) -> void:
	var blink := fuse > 0.0 and fmod(fuse, maxf(fuse * 0.25, 0.08)) < 0.06
	if blink:
		draw_circle(at, 6.0, Color(1.0, 0.25, 0.2, 0.9))


func _draw_chain(to: Vector2) -> void:
	var links := int(to.length() / 22.0)
	for index in links:
		var at := to * (index + 0.5) / links
		var radii := Vector2(7, 12) if index % 2 == 0 else Vector2(3, 12)
		var link := Art.moved(Art.ellipse(radii.x, radii.y, Vector2.ZERO, 14), Transform2D(to.angle() + PI / 2, at))
		Art.shape(self, Transform2D.IDENTITY, link, Color("8a8f9c"), 2.5, false)
