extends Node
## Prints what a tool actually does, for tuning. Run headless with --fixed-fps 120.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Sandbox


func _ready() -> void:
	Game.use_folder("user://tests/probe")
	_run.call_deferred()


func _run() -> void:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	main.tools.manual_cursor = true
	Events.buddy_hit.connect(func(info: Dictionary) -> void:
		print("hit %s force=%.0f damage=%.1f part=%s" % [info.get("source"), info.get("force", 0.0), info.get("damage", 0.0), info.get("part")]))
	for _i in 480:
		await get_tree().physics_frame
	var buddy := main.buddy
	print("head at ", buddy.head.global_position)
	Game.select_tool("anvil")
	main.tools.press(buddy.head.global_position)
	for step in 240:
		await get_tree().physics_frame
		if step % 20 == 0:
			var anvil: WorldObject = null
			for node in main.objects:
				if node is WorldObject:
					anvil = node
			if anvil != null:
				print("t=%d anvil y=%.0f v=%.0f" % [step, anvil.global_position.y, anvil.linear_velocity.length()])
	print("health ", buddy.health)
	get_tree().quit()
