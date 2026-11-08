extends SceneTree
## Prints how fast $$$ comes in under a few play styles, for balancing.
## Run: godot --headless --path . -s res://tests/probe_economy.gd


func _init() -> void:
	_report("Hand only: hard slam every 2.5 s", [&"hand"], 2.5, 2600.0, 12.0)
	_report("Spamming one tool: every 0.5 s", [&"pistol"], 0.5, 900.0, 12.0)
	_report("Mixing 4 tools: one use every 1.5 s", [&"hand", &"bat", &"grenade", &"slap"], 1.5, 2800.0, 18.0)
	quit()


func _report(label: String, tools: Array, gap: float, force: float, damage: float) -> void:
	var economy := Economy.new()
	var money := 0
	var seconds := 0.0
	var marks := {}
	var index := 0
	while seconds < 3600.0:
		var tool: StringName = tools[index % tools.size()]
		index += 1
		money += economy.pay(tool, Economy.hit_value({"force": force, "damage": damage}))
		for target: int in [100, 1000, 5000, 25000]:
			if money >= target and not marks.has(target):
				marks[target] = seconds
		economy.advance(gap)
		seconds += gap
	var parts: Array[String] = []
	for target: int in [100, 1000, 5000, 25000]:
		parts.append("%s at %s" % [Fmt.money(target), ("%.1f min" % (marks[target] / 60.0)) if marks.has(target) else "never"])
	print("%s -> %s/min; %s" % [label, Fmt.grouped(roundi(money / 60.0)), ", ".join(parts)])
