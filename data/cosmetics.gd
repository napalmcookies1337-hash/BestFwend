class_name Cosmetics
extends RefCounted
## Every look you can buy: Buddy colours, skins and rooms. Purely cosmetic.
## The first entry of each list is free and owned from the start.
## Skins: "back" is drawn behind the head (ears, horns, antennae), "hat" and
## "face" in front, "pattern" on the skin.

const COLORS := {
	"orange": {"name": "Tangerine", "price": 0, "hex": "ffa646"},
	"sky": {"name": "Sky", "price": 150, "hex": "6ec6ff"},
	"mint": {"name": "Mint", "price": 150, "hex": "7fe0a8"},
	"pink": {"name": "Bubblegum", "price": 200, "hex": "ff8fc8"},
	"grape": {"name": "Grape", "price": 250, "hex": "b48cff"},
	"lemon": {"name": "Lemon", "price": 250, "hex": "ffe066"},
	"cherry": {"name": "Cherry", "price": 300, "hex": "ff6464"},
	"slate": {"name": "Slate", "price": 400, "hex": "9aa3b5"},
	"snow": {"name": "Snow", "price": 600, "hex": "f4f1ea"},
	"midnight": {"name": "Midnight", "price": 800, "hex": "4a4366"},
	"gold": {"name": "Solid Gold", "price": 1500, "hex": "e9b93a"},
}

const SKINS := {
	"classic": {"name": "Classic", "price": 0},
	"spots": {"name": "Spotted", "price": 300, "pattern": "spots"},
	"stripes": {"name": "Tiger Stripes", "price": 400, "pattern": "stripes"},
	"party": {"name": "Party Hat", "price": 600, "hat": "party"},
	"cat": {"name": "Cat Ears", "price": 900, "back": "cat"},
	"shades": {"name": "Cool Shades", "price": 1200, "face": "shades"},
	"tophat": {"name": "Top Hat & Monocle", "price": 2000, "hat": "tophat", "face": "monocle"},
	"devil": {"name": "Little Devil", "price": 2500, "back": "horns"},
	"alien": {"name": "Alien", "price": 3000, "back": "antennae", "pattern": "spots"},
	"crown": {"name": "Royal Crown", "price": 5000, "hat": "crown"},
}

const ROOMS := {
	"bedroom": {"name": "Bedroom", "price": 0},
	"kitchen": {"name": "Kitchen", "price": 800},
	"backyard": {"name": "Backyard", "price": 1500},
	"lab": {"name": "Mad Lab", "price": 2500},
	"dungeon": {"name": "Dungeon", "price": 4000},
	"space": {"name": "Space Station", "price": 7000},
}

const KINDS := [&"color", &"skin", &"room"]


static func table(kind: StringName) -> Dictionary:
	match kind:
		&"color":
			return COLORS
		&"skin":
			return SKINS
		_:
			return ROOMS


static func free_item(kind: StringName) -> String:
	return table(kind).keys()[0]


static func color_of(color_id: String) -> Color:
	return Color(COLORS.get(color_id, COLORS["orange"])["hex"])


## The colour id whose hex matches, for saves that store the hex.
static func color_id_for(hex: String) -> String:
	for color_id: String in COLORS:
		if Color(COLORS[color_id]["hex"]).is_equal_approx(Color(hex)):
			return color_id
	return "orange"
