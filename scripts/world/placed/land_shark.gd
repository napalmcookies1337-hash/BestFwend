class_name LandShark
extends Node2D
## A shark that swims through the floor. Its fin hunts the nearest Buddy, then it
## leaps out in an arc, bites off the nearest limb (or takes a huge chunk of
## health if there are none left), and dives back under.

enum Phase { HUNT, LEAP, DONE }

const SWIM_SPEED := 900.0
const HUNT_TIME := 3.0
const LEAP_TIME := 0.7
const LEAP_HEIGHT := 300.0
const BITE_REACH := 110.0
const BITE_DAMAGE := 40.0

var sandbox: Sandbox
var power := 1.0
var phase := Phase.HUNT
var age := 0.0
var _phase_time := 0.0
var _leap_from := 0.0
var _leap_to := 0.0
var _bit := false
var _bite := 0.0
var _facing := 1.0


func setup(owner_sandbox: Sandbox, x: float, power_scale: float) -> void:
	sandbox = owner_sandbox
	name = "LandShark"
	power = power_scale
	global_position = Vector2(clampf(x, 80.0, Room.SIZE.x - 80.0), Room.FLOOR_Y)
	z_index = 6
	add_to_group(&"debris")


func _physics_process(delta: float) -> void:
	age += delta
	_phase_time += delta
	match phase:
		Phase.HUNT:
			_hunt(delta)
		Phase.LEAP:
			_leap()
		Phase.DONE:
			if _phase_time > 0.5:
				queue_free()
	queue_redraw()


func _target() -> Buddy:
	var best: Buddy = null
	var best_distance := INF
	for someone in sandbox.buddies():
		if someone.torso == null:
			continue
		var distance := absf(someone.torso.global_position.x - global_position.x)
		if distance < best_distance:
			best_distance = distance
			best = someone
	return best


func _hunt(delta: float) -> void:
	var prey := _target()
	if prey == null:
		if _phase_time > HUNT_TIME:
			_set_phase(Phase.DONE)
		return
	var gap := prey.torso.global_position.x - global_position.x
	_facing = signf(gap) if absf(gap) > 1.0 else _facing
	global_position.x += clampf(gap, -SWIM_SPEED * delta, SWIM_SPEED * delta)
	if randf() < delta * 20.0:
		sandbox.fx.add(0.4, Fx.smoke(global_position + Vector2(-_facing * 30.0, 0), 14.0, randi()))
	# Burst out just short of it, so the jaws meet it on the way up.
	if absf(gap) < 90.0 or _phase_time > HUNT_TIME:
		_leap_from = global_position.x
		_leap_to = clampf(global_position.x + _facing * 320.0, 80.0, Room.SIZE.x - 80.0)
		_set_phase(Phase.LEAP)
		Sfx.play(&"splat", 0.0, 0.5)
		Sfx.play(&"fwoosh", -4.0, 1.3)
		sandbox.add_shake(10.0)
		for chip in 3:
			sandbox.fx.add(0.6, Fx.sparks(global_position, 12, 220.0, Color("a8693a"), randi()))


func _leap() -> void:
	var t := clampf(_phase_time / LEAP_TIME, 0.0, 1.0)
	global_position = Vector2(lerpf(_leap_from, _leap_to, t), Room.FLOOR_Y - sin(t * PI) * LEAP_HEIGHT)
	_bite = 1.0 if not _bit else clampf(1.0 - t * 1.5, 0.0, 1.0)
	if not _bit and t >= 0.05 and t <= 0.75:
		_try_bite()
	if t >= 1.0:
		_set_phase(Phase.DONE)
		Sfx.play(&"splat", -4.0, 0.6)


func _try_bite() -> void:
	var mouth := global_position + Vector2(_facing * 50.0, 0)
	for someone in sandbox.buddies():
		var closest: BuddyPart = null
		var closest_distance := BITE_REACH * sqrt(power)
		for part in someone.part_list:
			var distance := part.global_position.distance_to(mouth)
			if distance < closest_distance:
				closest_distance = distance
				closest = part
		if closest == null:
			continue
		_bit = true
		Sfx.play(&"chomp", 2.0)
		sandbox.add_shake(18.0)
		sandbox.blood.spray(mouth, 40.0)
		# Bite off the nearest limb that's still on.
		var limb: StringName = &""
		var limb_distance := INF
		for name_of: StringName in Buddy.LIMBS:
			var part: BuddyPart = someone.parts.get(name_of)
			if part != null and part.global_position.distance_to(mouth) < limb_distance:
				limb_distance = part.global_position.distance_to(mouth)
				limb = name_of
		if limb != &"":
			someone.sever(limb, Vector2(_facing * 900.0, -1200.0), &"land_shark")
		else:
			someone.take_hit({"part": closest.part_name, "force": 3000.0, "damage": BITE_DAMAGE * power,
					"source": &"land_shark", "position": mouth})
		for part in someone.part_list:
			part.linear_velocity += Vector2(_facing * 700.0, -900.0)
		return


func _set_phase(next: Phase) -> void:
	phase = next
	_phase_time = 0.0


func _draw() -> void:
	match phase:
		Phase.HUNT:
			# Just the fin, cutting through the floor.
			var wobble := sin(age * 12.0) * 3.0
			var fin := PackedVector2Array([Vector2(-26 * _facing, 4), Vector2(4 * _facing, -46 + wobble), Vector2(22 * _facing, 4)])
			draw_colored_polygon(fin, Color("7b8fa6"))
			draw_polyline(fin, Art.INK, 3.0, true)
			draw_line(Vector2(-60, 4), Vector2(60, 4), Color("8a5a3b"), 6.0)
		Phase.LEAP:
			var xf := Transform2D(-0.5 * _facing * cos(_phase_time / LEAP_TIME * PI), Vector2(1.6 * _facing, 1.6), 0.0, Vector2.ZERO)
			ToolArt.shark(self, xf, 3.5, _bite)
