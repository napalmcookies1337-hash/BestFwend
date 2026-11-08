extends ToolBehavior
## Black Hole: opens one where you click for def.duration seconds.


func press(at: Vector2) -> void:
	var area := sandbox.room.interior().grow(-40.0)
	sandbox.spawn_black_hole(at.clamp(area.position, area.end), def.duration * power())
