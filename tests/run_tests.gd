extends Node
## Runs every test suite and prints "N passed, M failed". See README for the command.

const SUITES: Array[Script] = [
	preload("res://tests/test_save_store.gd"),
	preload("res://tests/test_profile.gd"),
	preload("res://tests/test_game.gd"),
	preload("res://tests/test_main.gd"),
	preload("res://tests/test_buddy.gd"),
	preload("res://tests/test_reactions.gd"),
	preload("res://tests/test_tools.gd"),
	preload("res://tests/test_shop.gd"),
]

var _passed := 0
var _failed := 0
var _checks := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	for script in SUITES:
		if not script.can_instantiate():
			_failed += 1
			print("FAIL  %s did not compile" % script.resource_path)
			continue
		var suite: TestSuite = script.new()
		add_child(suite)
		for method in suite.get_method_list():
			var method_name: String = method["name"]
			if method_name.begins_with("test_"):
				await _run_test(suite, method_name)
		remove_child(suite)
		suite.queue_free()
	print("\n%d passed, %d failed (%d checks)" % [_passed, _failed, _checks])
	get_tree().quit(1 if _failed > 0 else 0)


func _run_test(suite: TestSuite, method_name: String) -> void:
	suite.failures.clear()
	suite.checks = 0
	await suite.before_each()
	var finished: Variant = await suite.call(method_name)
	await suite.after_each()
	if finished != true:
		suite.failures.append("did not reach its end (runtime error?)")
	_checks += suite.checks
	var label := "%s.%s" % [suite.get_script().resource_path.get_file().get_basename(), method_name]
	if suite.failures.is_empty():
		_passed += 1
		print("ok    %s" % label)
	else:
		_failed += 1
		print("FAIL  %s" % label)
		for failure in suite.failures:
			print("        %s" % failure)
