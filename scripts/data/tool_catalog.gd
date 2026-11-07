class_name ToolCatalog
extends RefCounted
## Every ToolDef in data/tools/. Adding a .tres there adds the tool to the game.

const FOLDER := "res://data/tools/"

static var _tools: Dictionary = {}


static func all() -> Array[ToolDef]:
	_ensure_loaded()
	var result: Array[ToolDef] = []
	for tool: ToolDef in _tools.values():
		result.append(tool)
	result.sort_custom(func(a: ToolDef, b: ToolDef) -> bool:
		return a.category < b.category or (a.category == b.category and a.order < b.order))
	return result


static func in_category(category: ToolDef.Category) -> Array[ToolDef]:
	return all().filter(func(tool: ToolDef) -> bool: return tool.category == category)


static func get_tool(tool_id: String) -> ToolDef:
	_ensure_loaded()
	return _tools.get(tool_id)


static func _ensure_loaded() -> void:
	if not _tools.is_empty():
		return
	for file_name in ResourceLoader.list_directory(FOLDER):
		if not file_name.ends_with(".tres"):
			continue
		var tool := load(FOLDER + file_name) as ToolDef
		if tool == null or tool.id.is_empty():
			push_warning("Skipping tool file %s" % file_name)
			continue
		_tools[tool.id] = tool
