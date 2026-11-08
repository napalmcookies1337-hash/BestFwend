class_name ToolBehavior
extends RefCounted
## Base for what a tool does. ToolUser makes one per tool and calls press() on
## left-click, hold() every physics step while the button is down, and release().
## Numbers come from the ToolDef (strength, duration, use_interval) and its params,
## so tuning never means editing code.

var def: ToolDef
var sandbox: Sandbox


func press(_at: Vector2) -> void:
	pass


func hold(_at: Vector2, _delta: float) -> void:
	pass


func release(_at: Vector2) -> void:
	pass


## Draws the tool beside the cursor. Override for tools that show something else.
func draw_cursor(canvas: CanvasItem, at: Vector2) -> void:
	ToolArt.draw_icon(canvas, def.id, at + Vector2(34, 34), 46.0, Color.WHITE)


## The tool's strength including its upgrades.
func power() -> float:
	return def.strength * Game.tool_power(def.id)


func param(key: String, fallback: Variant) -> Variant:
	return def.params.get(key, fallback)


func buddy() -> Buddy:
	return sandbox.buddy


## The Buddy a part belongs to. There can be several (Zombie Mode).
func owner_of(part: BuddyPart) -> Buddy:
	return part.get_parent() as Buddy


## The attached Buddy part under `at`, or null.
func part_at(at: Vector2) -> BuddyPart:
	var body := sandbox.grabber.body_at(at)
	if body is BuddyPart and not (body as BuddyPart).detached:
		return body
	return null


## The attached Buddy part nearest `at`, if any is within `reach`.
func part_near(at: Vector2, reach: float) -> BuddyPart:
	var found := part_at(at)
	if found != null:
		return found
	var best_distance := reach
	for someone in sandbox.buddies():
		for part in someone.part_list:
			var distance := part.global_position.distance_to(at) - part.radius
			if distance < best_distance:
				best_distance = distance
				found = part
	return found
