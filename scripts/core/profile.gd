class_name Profile
extends RefCounted
## Everything the save remembers about the player. Plain data with validation;
## the rules that change it live in Game and, later, the economy.

const DEFAULT_SETTINGS := {
	"master_volume": 0.8,
	"music_volume": 0.6,
	"sfx_volume": 0.8,
	"fullscreen": false,
}
const KNOWN_KEYS := [
	"money", "lifetime_money", "owned_tools", "selected_tool", "tool_upgrades",
	"owned_skins", "skin", "owned_colors", "buddy_color", "owned_backgrounds", "background",
	"achievements", "stats", "best_scores", "prestige_count", "daily", "settings",
]

var money := 0
var lifetime_money := 0
var owned_tools: Array[String] = ["hand"]
var selected_tool := "hand"
## tool id -> upgrade level (Milestone 5).
var tool_upgrades: Dictionary = {}
var owned_skins: Array[String] = ["classic"]
var skin := "classic"
var owned_colors: Array[String] = ["orange"]
## The equipped colour as HTML without "#" (one of Cosmetics.COLORS).
var buddy_color := "ffa646"
var owned_backgrounds: Array[String] = ["bedroom"]
var background := "bedroom"
## achievement id -> {"progress": float, "unlocked_at": int} (Milestone 7).
var achievements: Dictionary = {}
## stat name -> number, such as "limbs_lost" or "biggest_hit".
var stats: Dictionary = {}
## minigame id -> best score.
var best_scores: Dictionary = {}
var prestige_count := 0
## Daily challenge state: date, challenge id, progress (Milestone 7).
var daily: Dictionary = {}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
## Keys this version doesn't know, kept so a newer save's data isn't lost.
var extra: Dictionary = {}


func to_dict() -> Dictionary:
	var result := extra.duplicate(true)
	result.merge({
		"money": money,
		"lifetime_money": lifetime_money,
		"owned_tools": owned_tools.duplicate(),
		"selected_tool": selected_tool,
		"tool_upgrades": tool_upgrades.duplicate(true),
		"owned_skins": owned_skins.duplicate(),
		"skin": skin,
		"owned_colors": owned_colors.duplicate(),
		"buddy_color": buddy_color,
		"owned_backgrounds": owned_backgrounds.duplicate(),
		"background": background,
		"achievements": achievements.duplicate(true),
		"stats": stats.duplicate(true),
		"best_scores": best_scores.duplicate(true),
		"prestige_count": prestige_count,
		"daily": daily.duplicate(true),
		"settings": settings.duplicate(),
	}, true)
	return result


## Builds a profile from loaded data, treating every value as possibly missing or wrong.
static func from_dict(data: Dictionary) -> Profile:
	var profile := Profile.new()
	profile.money = _count(data, "money")
	profile.lifetime_money = maxi(_count(data, "lifetime_money"), profile.money)
	profile.owned_tools = _names(data, "owned_tools", ["hand"])
	if not profile.owned_tools.has("hand"):
		profile.owned_tools.push_front("hand")
	profile.selected_tool = _text(data, "selected_tool", "hand")
	if not profile.owned_tools.has(profile.selected_tool):
		profile.selected_tool = "hand"
	profile.tool_upgrades = _table(data, "tool_upgrades")
	profile.owned_skins = _names(data, "owned_skins", ["classic"])
	profile.skin = _owned_choice(data, "skin", profile.owned_skins)
	profile.owned_colors = _names(data, "owned_colors", ["orange"])
	profile.buddy_color = _text(data, "buddy_color", profile.buddy_color)
	# Only a colour you own can be worn.
	if not Color.html_is_valid(profile.buddy_color) \
			or not profile.owned_colors.has(Cosmetics.color_id_for(profile.buddy_color)):
		profile.buddy_color = Profile.new().buddy_color
	profile.owned_backgrounds = _names(data, "owned_backgrounds", ["bedroom"])
	profile.background = _owned_choice(data, "background", profile.owned_backgrounds)
	profile.achievements = _table(data, "achievements")
	profile.stats = _table(data, "stats")
	profile.best_scores = _table(data, "best_scores")
	profile.prestige_count = _count(data, "prestige_count")
	profile.daily = _table(data, "daily")
	profile.settings = _settings(data.get("settings"))
	for key: Variant in data:
		if not KNOWN_KEYS.has(key):
			profile.extra[key] = data[key]
	return profile


static func _count(data: Dictionary, key: String) -> int:
	var value: Variant = data.get(key, 0)
	if value is int or value is float:
		return maxi(int(value), 0)
	return 0


static func _text(data: Dictionary, key: String, fallback: String) -> String:
	var value: Variant = data.get(key)
	return value if value is String and not value.is_empty() else fallback


static func _table(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key)
	return value.duplicate(true) if value is Dictionary else {}


static func _names(data: Dictionary, key: String, fallback: Array[String]) -> Array[String]:
	var result: Array[String] = []
	var value: Variant = data.get(key)
	if value is Array:
		for item: Variant in value:
			if item is String and not item.is_empty() and not result.has(item):
				result.append(item)
	if result.is_empty():
		result = fallback.duplicate()
	for item in fallback:
		if not result.has(item):
			result.push_front(item)
	return result


static func _owned_choice(data: Dictionary, key: String, owned: Array[String]) -> String:
	var choice := _text(data, key, owned[0])
	return choice if owned.has(choice) else owned[0]


static func _settings(value: Variant) -> Dictionary:
	var result := DEFAULT_SETTINGS.duplicate()
	if not value is Dictionary:
		return result
	for key: String in DEFAULT_SETTINGS:
		var stored: Variant = value.get(key)
		if DEFAULT_SETTINGS[key] is bool:
			if stored is bool:
				result[key] = stored
		elif stored is float or stored is int:
			result[key] = clampf(float(stored), 0.0, 1.0)
	return result
