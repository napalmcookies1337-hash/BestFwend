extends Node
## Prints how the Buddy behaves over time, for tuning. Run headless with --fixed-fps 120.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node2D


func _ready() -> void:
	Game.use_folder("user://tests/probe")
	_run.call_deferred()


func _run() -> void:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await _steps(360)
	print("--- launch up-left")
	main.buddy.launch(Vector2(-3500, -1800))
	for index in 24:
		await _steps(60)
		_report("t=%.1f" % ((index + 1) * 0.5))
	main.respawn()
	await _steps(2)
	print("--- gravity left")
	main.set_gravity(Vector2(-1960, 0))
	var settled_speed := 0.0
	for index in 16:
		await _steps(60)
		if index >= 4 and main.buddy.state == Buddy.State.RAGDOLL:
			settled_speed = maxf(settled_speed, main.buddy.torso.linear_velocity.length())
		_report("t=%.1f" % ((index + 1) * 0.5))
	print("RESULT max ragdoll speed after landing: %.0f, final state %s" % [settled_speed, Buddy.State.keys()[main.buddy.state]])
	get_tree().quit()


func _report(label: String) -> void:
	var buddy: Buddy = main.buddy
	var g := buddy.gravity()
	var parts := ""
	for part in buddy.part_list:
		parts += " %s(%.0f,%.0f)" % [String(part.part_name).left(4), part.global_position.x, part.global_position.y]
	print("%s %s v=%.0f w=%.1f tilt=%.2f ground=%.0f hit=%s str=%.2f |%s" % [
		label, Buddy.State.keys()[buddy.state], buddy.torso.linear_velocity.length(), buddy.torso.angular_velocity,
		buddy._tilt(g), buddy.ground_distance, buddy.ground_hit, buddy.stand_strength, parts])


func _steps(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame
