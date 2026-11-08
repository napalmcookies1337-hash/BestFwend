class_name RocketPack
extends Node2D
## A rocket strapped to a Buddy's back. Fires after a short fuse, drives the
## Buddy around wildly, then goes off in a firework burst.

const FUSE := 0.6
const BURN := 3.2
const THRUST := 5200.0
const BLAST := [300.0, 3000.0, 70.0, 0.6]
const FIREWORK_COLORS := [Color("ff5d6c"), Color("ffd23f"), Color("6ec6ff"), Color("7be08f"), Color("c08bff")]

var sandbox: Sandbox
var victim: Buddy
var power := 1.0
var age := 0.0
var _wobble := 0.0
var _done := false


func setup(owner_sandbox: Sandbox, target: Buddy, power_scale: float) -> void:
	sandbox = owner_sandbox
	victim = target
	power = power_scale
	name = "RocketPack"
	z_index = 7
	add_to_group(&"debris")
	victim.notice(&"bomb_near")


func _physics_process(delta: float) -> void:
	if not is_instance_valid(victim) or victim.is_queued_for_deletion():
		queue_free()
		return
	age += delta
	var torso := victim.torso
	# Strapped to the back: below and behind the torso, pointing the way it thrusts.
	global_position = torso.global_position + Vector2(0, 30).rotated(torso.rotation)
	rotation = torso.rotation
	if age >= FUSE and age < FUSE + BURN:
		if victim.state != Buddy.State.RAGDOLL and victim.state != Buddy.State.GRABBED:
			victim.launch(torso.linear_velocity)
		_wobble += randf_range(-6.0, 6.0) * delta
		var push := Vector2.UP.rotated(torso.rotation + _wobble) * THRUST * power
		torso.apply_central_force(push * victim.total_mass)
		torso.angular_velocity += randf_range(-14.0, 14.0) * delta
		victim.show_face(&"scream", 0.2)
		if randf() < delta * 30.0:
			sandbox.fx.add(0.4, Fx.smoke(global_position + Vector2(0, 40).rotated(rotation), 30.0, randi()))
		if randf() < delta * 3.0:
			Sfx.play(&"whoosh", -6.0, randf_range(0.8, 1.2))
	elif age >= FUSE + BURN and not _done:
		_done = true
		sandbox.explode(global_position, BLAST[0] * sqrt(power), BLAST[1] * power, BLAST[2] * power, BLAST[3], &"rocket_pack")
		for index in 5:
			var color: Color = FIREWORK_COLORS[index]
			sandbox.fx.add(1.0, Fx.sparks(global_position + Vector2(randf_range(-120, 120), randf_range(-160, 40)), 22, 320.0, color, randi()))
		Sfx.play(&"pop", 0.0, 0.6)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if age >= FUSE:
		ToolArt.flame(self, Transform2D(PI, Vector2.ONE * (0.8 + randf() * 0.25), 0.0, Vector2(0, 80)), 3.0, age)
	ToolArt.rocket(self, Transform2D(0.0, Vector2.ONE * 0.95, 0.0, Vector2.ZERO), 4.0, randf() if age >= FUSE else 0.0)
