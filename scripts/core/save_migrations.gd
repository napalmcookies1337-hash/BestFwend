class_name SaveMigrations
extends RefCounted
## Upgrades old save data to the current format, one version at a time.
##
## To change the format: raise CURRENT_VERSION, add a step to steps() keyed by the
## version it upgrades FROM, and add a test with an old save. Never edit a shipped step.

const CURRENT_VERSION := 1


## from_version -> Callable(data: Dictionary) -> Dictionary
static func steps() -> Dictionary:
	return {}


## Returns the upgraded data, or {} if a step is missing.
## `table` and `target` exist so tests can exercise the chain with made-up steps.
static func migrate(data: Dictionary, from_version: int, target: int = CURRENT_VERSION, table: Variant = null) -> Dictionary:
	var step_table: Dictionary = steps() if table == null else table
	var result := data.duplicate(true)
	var version := from_version
	while version < target:
		var step: Callable = step_table.get(version, Callable())
		if not step.is_valid():
			return {}
		result = step.call(result)
		version += 1
	return result
