extends ToolBehavior
## Slingshot: grab your fwend, pull it back like a rubber band, and let go. It
## flies the opposite way, far harder than any throw. params: "power", "max_speed".

var anchor := Vector2.ZERO
var victim: Buddy
var held_part: BuddyPart


func press(at: Vector2) -> void:
	held_part = part_at(at)
	if held_part == null:
		return
	victim = owner_of(held_part)
	anchor = at
	sandbox.grabber.hold(held_part, at, MOUSE_BUTTON_LEFT)
	Sfx.play(&"squeak", -6.0, 0.7)


func release(at: Vector2) -> void:
	if victim == null or not is_instance_valid(victim):
		victim = null
		return
	var pull := anchor - at
	sandbox.grabber.forget()
	var speed := minf(pull.length() * float(param("power", 14.0)) * power(), float(param("max_speed", 7500.0)))
	var launch := pull.normalized() * speed if pull.length() > 10.0 else Vector2.ZERO
	for part in victim.part_list:
		part.linear_velocity = launch
	victim.on_released(launch)
	Events.buddy_released.emit(held_part.part_name, launch)
	if speed > 1000.0:
		Sfx.play(&"whoosh", 0.0)
		Sfx.play(&"scream", -4.0, victim.voice_pitch)
		sandbox.add_shake(8.0)
	victim = null


func draw_cursor(canvas: CanvasItem, at: Vector2) -> void:
	if victim != null and is_instance_valid(victim):
		var band := Color("d8352e")
		var post := Vector2(26, 0)
		canvas.draw_line(anchor - post, held_part.global_position, Art.INK, 9.0, true)
		canvas.draw_line(anchor + post, held_part.global_position, Art.INK, 9.0, true)
		canvas.draw_line(anchor - post, held_part.global_position, band, 5.0, true)
		canvas.draw_line(anchor + post, held_part.global_position, band, 5.0, true)
		ToolArt.slingshot(canvas, Transform2D(0.0, Vector2.ONE * 1.1, 0.0, anchor + Vector2(0, 24)), 3.0)
	else:
		super.draw_cursor(canvas, at)
