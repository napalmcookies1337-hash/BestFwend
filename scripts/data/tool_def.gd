class_name ToolDef
extends Resource
## One tool's data. Behavior scripts (Milestone 4) read these values, so prices and
## strengths are tuned here rather than in code. Tools are always unlimited.

enum Category { HAND, THROWABLE, EXPLOSIVE, POWER }
## How a click turns into a use: on the Buddy, at a point, by dragging, or while held.
enum Targeting { BUDDY, POINT, DRAG, HOLD }

const CATEGORY_NAMES := {
	Category.HAND: "Hand",
	Category.THROWABLE: "Throw & Melee",
	Category.EXPLOSIVE: "Boom",
	Category.POWER: "Powers",
}

@export var id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var category := Category.HAND
## Order within its category on the toolbar.
@export var order := 0
@export var price := 0
## Another tool's id that must be owned before this one can be bought.
@export var requires := ""
## Minimum seconds between uses while held, for rapid-fire tools. Not a cooldown.
@export var use_interval := 0.0
@export var duration := 0.0
@export var strength := 1.0
@export var targeting := Targeting.POINT
## Script that runs the tool: a ToolBehavior. Several tools can share one.
@export var behavior: Script
## Settings the behavior reads, such as "kind" for objects or "damage".
@export var params: Dictionary = {}
@export var effect := ""
@export var sound := ""
## Multiplies the money this tool's hits earn.
@export var reward_scale := 1.0
