class_name Goals
extends RefCounted
## Rules for achievements and daily challenges, as plain functions over a Profile
## so they can be tested without the game running. Game applies the results.


## The value an achievement or challenge measures.
static func stat_value(profile: Profile, stat: String) -> float:
	match stat:
		"tools_owned":
			return profile.owned_tools.size()
		"prestige_owned":
			var count := 0
			for tool_id in profile.owned_tools:
				var tool := ToolCatalog.get_tool(tool_id)
				if tool != null and tool.prestige:
					count += 1
			return count
		"looks_owned":
			# Bought looks only: each kind starts with one free item.
			return profile.owned_colors.size() + profile.owned_skins.size() + profile.owned_backgrounds.size() - 3
	return float(profile.stats.get(stat, 0.0))


## Achievements whose goal is met but aren't unlocked yet.
static func pending_unlocks(profile: Profile) -> Array[String]:
	var ready: Array[String] = []
	for achievement_id: String in GoalData.ACHIEVEMENTS:
		if profile.achievements.has(achievement_id):
			continue
		var spec: Array = GoalData.ACHIEVEMENTS[achievement_id]
		if stat_value(profile, spec[2]) >= float(spec[3]):
			ready.append(achievement_id)
	return ready


## 0..1 progress toward an achievement.
static func achievement_progress(profile: Profile, achievement_id: String) -> float:
	if profile.achievements.has(achievement_id):
		return 1.0
	var spec: Array = GoalData.ACHIEVEMENTS[achievement_id]
	return clampf(stat_value(profile, spec[2]) / float(spec[3]), 0.0, 1.0)


## A fresh set of challenges for `date`: one easy, one medium, one hard, picked
## from the templates whose tool the player owns. The same date always gives
## the same set.
static func make_daily(date: String, owned_tools: Array[String]) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(date)
	var choices: Array[String] = []
	for template_id: String in GoalData.DAILIES:
		var needs: String = GoalData.DAILIES[template_id][4]
		if needs.is_empty() or owned_tools.has(needs):
			choices.append(template_id)
	var challenges: Array = []
	for tier in GoalData.DAILY_COUNT:
		if choices.is_empty():
			break
		var template_id: String = choices.pop_at(rng.randi() % choices.size())
		var spec: Array = GoalData.DAILIES[template_id]
		challenges.append({"id": template_id, "goal": spec[2][tier], "reward": spec[3][tier], "progress": 0.0, "done": false})
	return {"date": date, "challenges": challenges, "tools_today": []}


static func daily_text(challenge: Dictionary) -> String:
	var spec: Array = GoalData.DAILIES.get(challenge["id"], ["%s", "", [], [], ""])
	var goal: float = challenge["goal"]
	var shown := ("%.1f" % goal) if goal != floorf(goal) else Fmt.grouped(int(goal))
	return spec[0] % shown


## Adds to (or raises) the matching challenges. Returns the indexes just finished.
static func record_daily(daily: Dictionary, stat: String, amount: float, keep_max: bool) -> Array[int]:
	var finished: Array[int] = []
	var challenges: Array = daily.get("challenges", [])
	for index in challenges.size():
		var challenge: Dictionary = challenges[index]
		if challenge["done"] or GoalData.DAILIES.get(challenge["id"], ["", ""])[1] != stat:
			continue
		challenge["progress"] = maxf(challenge["progress"], amount) if keep_max else challenge["progress"] + amount
		if challenge["progress"] >= float(challenge["goal"]):
			challenge["done"] = true
			finished.append(index)
	return finished
