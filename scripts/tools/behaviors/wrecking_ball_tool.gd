extends ToolBehavior
## Wrecking Ball: a huge ball on a chain drops in from the ceiling above where you
## click, pulled back to one side, and swings through at the height you clicked
## (it reaches the floor at most). params: "min_chain".

const BALL_RADIUS := 72.0


func press(at: Vector2) -> void:
	var length := clampf(at.y - 30.0, float(param("min_chain", 350.0)), Room.FLOOR_Y - 30.0 - BALL_RADIUS - 10.0)
	var anchor_point := Vector2(clampf(at.x, 300.0, Room.SIZE.x - 300.0), 30.0)
	# Start swung out to whichever side has more room (never inside a wall), so it
	# sweeps across under the anchor.
	var room_left := anchor_point.x - BALL_RADIUS - 40.0
	var room_right := Room.SIZE.x - anchor_point.x - BALL_RADIUS - 40.0
	var side := 1.0 if room_left > room_right else -1.0
	var swing := minf(1.1, asin(clampf(maxf(room_left, room_right) / length, 0.0, 1.0)))
	var start := anchor_point + Vector2.from_angle(PI / 2 + side * swing) * length
	start.y = maxf(start.y, 120.0)
	var ball := sandbox.spawn_object(&"wrecking_ball", start, Vector2.ZERO, power())
	ball.anchor = anchor_point
	ball.global_position = anchor_point + (start - anchor_point).normalized() * length
	var nail := PinNail.new()
	sandbox.world.add_child(nail)
	nail.setup(anchor_point, ball, false)
	Sfx.play(&"clink", 0.0, 0.5)
	Sfx.play(&"whoosh", -2.0, 0.6)
