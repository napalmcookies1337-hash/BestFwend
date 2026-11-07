extends ToolBehavior
## Pin: nail whatever's under the cursor to the wall. Click a nail to pull it out.


func press(at: Vector2) -> void:
	if sandbox.remove_pin_near(at):
		return
	var body := sandbox.grabber.body_at(at)
	if body != null:
		sandbox.add_pin(at, body)
