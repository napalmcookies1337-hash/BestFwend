extends TestSuite
## SaveStore: round trips, recovery from damaged files, backups.

const FOLDER := "user://tests/save_store"

var store: SaveStore


func before_each() -> void:
	wipe(FOLDER)
	store = SaveStore.new(FOLDER)


func test_missing_save_reports_missing() -> bool:
	check_eq(store.read().get("error"), "missing", "empty folder")
	return true


func test_round_trip() -> bool:
	var data := {"money": 42, "owned_tools": ["hand", "brick"], "nested": {"a": 1.5}}
	check_eq(store.write(data, 1, 1000), OK, "write")
	var result := store.read()
	check_eq(result.get("source"), SaveStore.MAIN, "read from main")
	check_eq(result.get("version"), 1, "version")
	check_eq(result.get("saved_at"), 1000, "time")
	check_eq(int(result["data"]["money"]), 42, "money")
	check_eq(result["data"]["owned_tools"], ["hand", "brick"], "tools")
	check(not FileAccess.file_exists(store.path(SaveStore.TEMP)), "temp file is renamed away")
	return true


func test_second_write_keeps_previous() -> bool:
	store.write({"money": 1}, 1, 1000)
	store.write({"money": 2}, 1, 1001)
	check(FileAccess.file_exists(store.path(SaveStore.PREVIOUS)), "previous copy exists")
	var previous := SaveStore.decode(FileAccess.get_file_as_string(store.path(SaveStore.PREVIOUS)))
	check_eq(int(previous["data"]["money"]), 1, "previous holds the older save")
	return true


func test_tampered_main_falls_back_to_previous() -> bool:
	store.write({"money": 1}, 1, 1000)
	store.write({"money": 2}, 1, 1001)
	var text := FileAccess.get_file_as_string(store.path(SaveStore.MAIN))
	write_text(store.path(SaveStore.MAIN), text.replace("2", "9999"))
	var result := store.read()
	check_eq(result.get("source"), SaveStore.PREVIOUS, "checksum mismatch skips main")
	check_eq(int(result["data"]["money"]), 1, "older money")
	return true


func test_garbage_everywhere_reports_corrupt_and_leaves_files() -> bool:
	write_text(store.path(SaveStore.MAIN), "not a save at all")
	check_eq(store.read().get("error"), "corrupt", "unreadable")
	check(FileAccess.file_exists(store.path(SaveStore.MAIN)), "reading never deletes")
	return true


func test_damaged_main_is_set_aside_on_next_write() -> bool:
	store.write({"money": 1}, 1, 1000)
	write_text(store.path(SaveStore.MAIN), "garbage")
	store.write({"money": 3}, 1, 2000)
	check(FileAccess.file_exists(store.path("corrupt_2000.json")), "damaged file kept aside")
	var previous := SaveStore.decode(FileAccess.get_file_as_string(store.path(SaveStore.PREVIOUS)))
	check(previous.is_empty() or int(previous["data"]["money"]) == 1, "garbage never becomes the previous copy")
	check_eq(int(store.read()["data"]["money"]), 3, "new save readable")
	return true


func test_backups_are_spaced_and_capped() -> bool:
	for index in 8:
		store.write({"money": index}, 1, 10000 + index * SaveStore.BACKUP_INTERVAL)
	store.write({"money": 99}, 1, 10000 + 7 * SaveStore.BACKUP_INTERVAL + 5)
	var files := DirAccess.get_files_at(store.path(SaveStore.BACKUP_DIR))
	check_eq(files.size(), SaveStore.BACKUPS_KEPT, "only the newest backups kept")
	return true


func test_backup_used_when_main_files_gone() -> bool:
	store.write({"money": 5}, 1, 5000)
	DirAccess.remove_absolute(store.path(SaveStore.MAIN))
	var result := store.read()
	check(str(result.get("source", "")).begins_with("backup_"), "read from a backup")
	check_eq(int(result["data"]["money"]), 5, "backup money")
	return true


func test_migrations_run_in_order() -> bool:
	var table := {
		1: func(data: Dictionary) -> Dictionary:
			data["coins"] = data.get("money", 0)
			return data,
		2: func(data: Dictionary) -> Dictionary:
			data["coins"] = int(data["coins"]) * 10
			return data,
	}
	var result := SaveMigrations.migrate({"money": 4}, 1, 3, table)
	check_eq(result.get("coins"), 40, "both steps applied in order")
	check(SaveMigrations.migrate({}, 0, 3, table).is_empty(), "a missing step fails the migration")
	check_eq(SaveMigrations.migrate({"x": 1}, SaveMigrations.CURRENT_VERSION), {"x": 1}, "current version is unchanged")
	return true
