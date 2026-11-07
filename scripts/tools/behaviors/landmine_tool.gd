extends ToolBehavior
## Landmine: drops a mine onto the surface below the click. It arms after a moment
## and goes off when anything steps on it.


func press(at: Vector2) -> void:
	sandbox.place_landmine(at)
	Sfx.play(&"clink", -4.0, 0.7)
