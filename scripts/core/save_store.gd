class_name SaveStore
extends RefCounted
## Reads and writes one save file without ever losing the last good copy.
## Knows nothing about what the data means, so it can be tested against any folder.
##
## File layout: a one-line JSON header (format, version, time, checksum of the body),
## then the pretty-printed JSON body.

const FORMAT := "best_fwend_save"
const MAIN := "save.json"
const TEMP := "save.tmp"
const PREVIOUS := "save.prev.json"
const BACKUP_DIR := "backups"
const BACKUP_INTERVAL := 600
const BACKUPS_KEPT := 5

var folder: String


func _init(save_folder: String) -> void:
	folder = save_folder


## Writes data as the new main save. Returns OK only once a verified copy is in place.
func write(data: Dictionary, version: int, now: int = 0) -> Error:
	if now == 0:
		now = int(Time.get_unix_time_from_system())
	var err := DirAccess.make_dir_recursive_absolute(folder)
	if err != OK:
		return err
	var text := encode(data, version, now)
	var temp_path := path(TEMP)
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	file.close()
	if decode(FileAccess.get_file_as_string(temp_path)).is_empty():
		return ERR_FILE_CORRUPT

	var main_path := path(MAIN)
	if FileAccess.file_exists(main_path):
		if decode(FileAccess.get_file_as_string(main_path)).is_empty():
			# Keep a damaged file aside instead of letting it replace the last good copy.
			DirAccess.rename_absolute(main_path, path("corrupt_%d.json" % now))
		else:
			var previous_path := path(PREVIOUS)
			if FileAccess.file_exists(previous_path):
				DirAccess.remove_absolute(previous_path)
			DirAccess.rename_absolute(main_path, previous_path)
	err = DirAccess.rename_absolute(temp_path, main_path)
	if err != OK:
		return err
	_maybe_backup(text, now)
	return OK


## Returns {"data", "version", "saved_at", "source"} from the first readable copy,
## or {"error": "missing"} when there is no save, or {"error": "corrupt"} when none can be read.
func read() -> Dictionary:
	var candidates: Array[String] = [path(MAIN), path(TEMP), path(PREVIOUS)]
	candidates.append_array(_backup_paths())
	var found_any := false
	for candidate in candidates:
		if not FileAccess.file_exists(candidate):
			continue
		found_any = true
		var result := decode(FileAccess.get_file_as_string(candidate))
		if not result.is_empty():
			result["source"] = candidate.get_file()
			return result
	return {"error": "corrupt" if found_any else "missing"}


## Copies the main file aside once before an upgrade rewrites it.
func keep_original(version: int) -> void:
	var target := path("pre_v%d.json" % version)
	if FileAccess.file_exists(path(MAIN)) and not FileAccess.file_exists(target):
		DirAccess.copy_absolute(path(MAIN), target)


func path(file_name: String) -> String:
	return folder.path_join(file_name)


static func encode(data: Dictionary, version: int, now: int) -> String:
	var body := JSON.stringify(data, "\t")
	var header := {"format": FORMAT, "version": version, "saved_at": now, "checksum": body.sha256_text()}
	return JSON.stringify(header) + "\n" + body


## Returns {"data", "version", "saved_at"}, or {} if the text isn't an intact save.
static func decode(text: String) -> Dictionary:
	var split := text.find("\n")
	if split < 0:
		return {}
	var json := JSON.new()
	if json.parse(text.substr(0, split)) != OK or not json.data is Dictionary:
		return {}
	var header: Dictionary = json.data
	if header.get("format") != FORMAT:
		return {}
	var body := text.substr(split + 1)
	if body.sha256_text() != str(header.get("checksum", "")):
		return {}
	if json.parse(body) != OK or not json.data is Dictionary:
		return {}
	return {"data": json.data, "version": int(header.get("version", 0)), "saved_at": int(header.get("saved_at", 0))}


func _backup_paths() -> Array[String]:
	var result: Array[String] = []
	var backup_folder := path(BACKUP_DIR)
	if not DirAccess.dir_exists_absolute(backup_folder):
		return result
	var names := Array(DirAccess.get_files_at(backup_folder))
	names.sort()
	names.reverse()
	for file_name: String in names:
		if file_name.begins_with("backup_"):
			result.append(backup_folder.path_join(file_name))
	return result


func _maybe_backup(text: String, now: int) -> void:
	var existing := _backup_paths()
	if not existing.is_empty():
		var newest := int(existing[0].get_file().trim_prefix("backup_").trim_suffix(".json"))
		if now - newest < BACKUP_INTERVAL:
			return
	DirAccess.make_dir_recursive_absolute(path(BACKUP_DIR))
	var file := FileAccess.open(path(BACKUP_DIR).path_join("backup_%d.json" % now), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)
	file.close()
	existing = _backup_paths()
	for index in range(BACKUPS_KEPT, existing.size()):
		DirAccess.remove_absolute(existing[index])
