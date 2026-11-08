extends ToolBehavior
## Tornado: a twister touches down where you click and roams the room, sucking
## everything up and whirling it round. One at a time. Uses the tool's duration.


func press(at: Vector2) -> void:
	for old in sandbox.get_tree().get_nodes_in_group(&"tornadoes"):
		old.queue_free()
	var twister := Tornado.new()
	twister.add_to_group(&"tornadoes")
	twister.setup(sandbox, at, def.duration if def.duration > 0.0 else 6.0, power())
	sandbox.world.add_child(twister)
	Sfx.play(&"fwoosh", -2.0, 0.5)
	for someone in sandbox.buddies():
		someone.notice(&"black_hole")
