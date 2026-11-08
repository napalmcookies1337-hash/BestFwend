class_name GoalData
extends RefCounted
## Achievements and daily challenge templates. Each counts one stat from
## Profile.stats ("max" stats keep the best value instead of adding up).
## Edit freely: ids must stay stable once shipped, since saves refer to them.

## Stats that keep the highest value instead of a running total.
const MAX_STATS := ["biggest_hit", "max_combo", "longest_flight", "best_ricochet", "best_toss", "best_frenzy"]

## id: [name, description, stat, goal, reward $$$]
const ACHIEVEMENTS := {
	"first_throw": ["Yeet", "Throw your fwend.", "throws", 1, 50],
	"throws_100": ["Frequent Flinger", "Throw your fwend 100 times.", "throws", 100, 600],
	"hits_250": ["Punching Bag", "Land 250 hits that hurt.", "hits", 250, 500],
	"big_hit": ["Home Run", "Land a hit with 4,000 force.", "biggest_hit", 4000, 400],
	"first_ko": ["Lights Out", "Knock your fwend out.", "knockouts", 1, 150],
	"ko_25": ["Nap Time", "Knock your fwend out 25 times.", "knockouts", 25, 1200],
	"first_limb": ["Disarming", "Make your fwend lose a limb.", "limbs", 1, 200],
	"limbs_50": ["Spare Parts", "Remove 50 limbs.", "limbs", 50, 1800],
	"shatter": ["Brain Freeze", "Shatter a frozen fwend.", "shatters", 1, 600],
	"explosions_50": ["Demolition Expert", "Set off 50 explosions.", "explosions", 50, 1500],
	"nuke": ["Overkill", "Drop the Mini-Nuke.", "used_mini_nuke", 1, 1000],
	"combo_2": ["Variety Show", "Reach a x2.00 combo.", "max_combo", 2.0, 500],
	"combo_max": ["Full Toolbox", "Max out the combo at x2.50.", "max_combo", 2.5, 1500],
	"flight": ["Frequent Flyer", "Keep your fwend airborne for 3 seconds.", "longest_flight", 3.0, 400],
	"tickles": ["Tickle Monster", "Tickle your fwend 50 times.", "tickles", 50, 300],
	"tools_5": ["Collector", "Own 5 tools.", "tools_owned", 5, 300],
	"tools_all": ["Arsenal", "Own all 21 tools.", "tools_owned", 21, 5000],
	"looks_5": ["Fashionista", "Own 5 looks you bought.", "looks_owned", 5, 600],
	"earned_10k": ["Ten Grand", "Earn 10,000 $$$ in total.", "earned", 10000, 500],
	"earned_250k": ["Fat Stacks", "Earn 250,000 $$$ in total.", "earned", 250000, 5000],
	"played_30": ["Dedicated", "Play for 30 minutes.", "seconds_played", 1800, 500],
	"ricochet": ["Pinball Wizard", "Score 100 m in Ricochet.", "best_ricochet", 100, 800],
	"toss": ["Sharpshooter", "Hit 10 targets in Target Toss.", "best_toss", 10, 800],
	"frenzy": ["Unhinged", "Deal 1,000 damage in Impact Frenzy.", "best_frenzy", 1000, 800],
}

## Daily challenge templates. id: [text with %s for the goal, stat, goals by tier,
## $$$ per tier, tool that must be owned or ""]
const DAILIES := {
	"earn": ["Earn %s $$$", "earned", [1500, 4000, 9000], [300, 700, 1500], ""],
	"knockouts": ["Knock your fwend out %s times", "knockouts", [2, 4, 8], [300, 600, 1200], ""],
	"throws": ["Throw your fwend %s times", "throws", [10, 25, 50], [200, 450, 900], ""],
	"hits": ["Land %s hits that hurt", "hits", [30, 80, 160], [250, 550, 1100], ""],
	"big_hit": ["Land a hit with %s force", "biggest_hit", [3000, 3800, 4500], [300, 600, 1000], ""],
	"combo": ["Reach a x%s combo", "max_combo", [1.5, 2.0, 2.5], [300, 700, 1300], ""],
	"tools": ["Use %s different tools", "tools_used", [3, 5, 8], [300, 600, 1200], ""],
	"limbs": ["Remove %s limbs", "limbs", [2, 6, 12], [400, 800, 1600], "katana"],
	"explosions": ["Set off %s explosions", "explosions", [3, 8, 15], [400, 800, 1500], "grenade"],
	"tickles": ["Tickle your fwend %s times", "tickles", [10, 25, 50], [200, 400, 800], "tickle"],
	"shatter": ["Shatter your fwend %s times", "shatters", [1, 2, 3], [600, 1100, 1800], "freeze"],
}
const DAILY_COUNT := 3
