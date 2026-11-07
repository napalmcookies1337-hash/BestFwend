class_name TestSuite
extends Node
## Base for test suites. Methods named test_* run automatically and must end with
## `return true`: a GDScript runtime error silently aborts a function, and this is
## how the runner notices.

var failures: Array[String] = []
var checks := 0


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])


## Points Game at a fresh throwaway folder under user://tests, never the real save.
func reset_game(folder: String) -> String:
	var path := "user://tests/%s" % folder
	wipe(path)
	Game.use_folder(path)
	return path


func wipe(path: String) -> void:
	if DirAccess.dir_exists_absolute(path):
		_wipe_tree(path)


func write_text(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func frames(count := 2) -> void:
	for _i in count:
		await get_tree().process_frame


func physics_frames(count: int) -> void:
	for _i in count:
		await get_tree().physics_frame


func _wipe_tree(path: String) -> void:
	for file_name in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	for sub_dir in DirAccess.get_directories_at(path):
		_wipe_tree(path.path_join(sub_dir))
	DirAccess.remove_absolute(path)
