class_name Economy
extends RefCounted
## How much $$$ things pay. Plain rules with no physics or UI, so they can be
## tested and balanced on their own. Time only moves through advance().
##
## - Hits pay for damage, plus a little for raw force.
## - Using different tools within COMBO_WINDOW builds a combo multiplier.
## - Using the same tool over and over pays less and less (fatigue), and recovers
##   while you do something else.
## - Losing a limb, getting knocked out and shattering pay bonuses.

const DAMAGE_RATE := 1.6
const FORCE_FLOOR := 500.0
const FORCE_RATE := 1.0 / 500.0
## Hits gentler than this that do no damage pay nothing.
const MIN_PAYING_FORCE := 700.0
const BONUS := {&"limb": 30.0, &"knockout": 80.0, &"shatter": 200.0}
## Gentle actions that never hurt still pay a little.
const KIND_PAY := {&"poke": 3.0, &"tickle": 2.0}

const COMBO_WINDOW := 10.0
const COMBO_STEP := 0.25
const MAX_COMBO := 2.5
## Repeats closer together than this count as one use for fatigue.
const FATIGUE_GAP := 0.4
## Fatigue levels recovered per second.
const FATIGUE_RECOVERY := 1.0
const FATIGUE_FACTOR := 0.88
const MIN_FATIGUE := 0.25

## Hit sources that mean "you threw it with the Hand".
const HAND_SOURCES := [&"wall", &"limb", &"object", &"hand"]
## Object kinds and effect names that belong to a tool with a different id.
const SOURCE_TOOL := {&"nuke": &"mini_nuke", &"fire": &"ignite", &"cut": &"katana"}

var now := 0.0
var _last_used: Dictionary = {}
var _fatigue: Dictionary = {}
var _fatigue_time: Dictionary = {}
var _last_bump: Dictionary = {}


func advance(seconds: float) -> void:
	now += seconds


## Which tool gets the credit for a hit, for combos and fatigue.
static func tool_for(info: Dictionary) -> StringName:
	var source: StringName = info.get("tool", info.get("source", &"wall"))
	if HAND_SOURCES.has(source):
		return &"hand"
	return SOURCE_TOOL.get(source, source)


## What a hit is worth before multipliers.
static func hit_value(info: Dictionary) -> float:
	var damage: float = info.get("damage", 0.0)
	var force: float = info.get("force", 0.0)
	if damage <= 0.0 and force < MIN_PAYING_FORCE:
		return 0.0
	return damage * DAMAGE_RATE + maxf(force - FORCE_FLOOR, 0.0) * FORCE_RATE


## The current variety multiplier: 1.0 with one tool in use, more with several.
func combo() -> float:
	var used := 0
	for tool: StringName in _last_used:
		if now - _last_used[tool] <= COMBO_WINDOW:
			used += 1
	return minf(1.0 + COMBO_STEP * maxf(used - 1, 0), MAX_COMBO)


## How much a tool still pays after repeated use, 1.0 when fresh.
func freshness(tool: StringName) -> float:
	return maxf(pow(FATIGUE_FACTOR, maxf(_level(tool) - 1.0, 0.0)), MIN_FATIGUE)


## Records a use of `tool` worth `base` and returns the $$$ it pays.
func pay(tool: StringName, base: float, scale := 1.0) -> int:
	if base <= 0.0:
		return 0
	_use(tool)
	return maxi(roundi(base * scale * combo() * freshness(tool)), 1)


func _use(tool: StringName) -> void:
	var level := _level(tool)
	if now - float(_last_bump.get(tool, -INF)) >= FATIGUE_GAP:
		level += 1.0
		_last_bump[tool] = now
	_fatigue[tool] = level
	_fatigue_time[tool] = now
	_last_used[tool] = now


func _level(tool: StringName) -> float:
	var level: float = _fatigue.get(tool, 0.0)
	var since := now - float(_fatigue_time.get(tool, now))
	return maxf(level - since * FATIGUE_RECOVERY, 0.0)
