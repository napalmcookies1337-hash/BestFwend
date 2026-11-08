extends ToolBehavior
## Spin Cycle: grab your fwend and whirl it around the cursor, faster and faster.
## Let go to fling it off at whatever speed it's reached. params: "radius",
## "spin_up", "max_spin".

var victim: Buddy
var angle := 0.0
var spin := 0.0


func press(at: Vector2) -> void:
	var part := part_near(at, 60.0)
	if part == null:
		return
	victim = owner_of(part)
	angle = (victim.torso.global_position - at).angle()
	spin = 2.0
	victim.levitate(true)
	victim.show_face(&"dizzy", 0.5)


func hold(at: Vector2, delta: float) -> void:
	if victim == null or not is_instance_valid(victim):
		victim = null
		return
	spin = minf(spin + float(param("spin_up", 14.0)) * power() * delta, float(param("max_spin", 26.0)))
	angle += spin * delta
	var radius := float(param("radius", 190.0))
	var target := at + Vector2.from_angle(angle) * radius
	var tangent := Vector2.from_angle(angle + PI / 2) * spin * radius
	var torso := victim.torso
	torso.linear_velocity = tangent + (target - torso.global_position) * 18.0
	for part in victim.part_list:
		if part != torso:
			# Limbs fly outward, like on a merry-go-round.
			part.apply_central_force((part.global_position - at).normalized() * spin * spin * 40.0 * part.mass)
	victim.show_face(&"dizzy", 0.3)
	if randf() < delta * 2.0:
		Sfx.play(&"whoosh", -10.0, 0.8 + spin / 30.0)


func release(_at: Vector2) -> void:
	if victim == null or not is_instance_valid(victim):
		victim = null
		return
	var fling := victim.torso.linear_velocity.limit_length(float(param("max_speed", 8000.0)))
	victim.levitate(false, fling)
	Events.buddy_released.emit(&"torso", fling)
	if fling.length() > 2000.0:
		Sfx.play(&"scream", -3.0, victim.voice_pitch)
	victim = null
