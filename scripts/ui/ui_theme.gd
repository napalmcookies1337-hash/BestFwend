class_name UiTheme
extends RefCounted
## Colors and the shared Theme for every menu. Change the look here, not in panels.

const INK := Color("1b1726")
const PANEL := Color("231d31e8")
const PANEL_EDGE := Color("4a3f63")
const BUTTON := Color("3a3150")
const BUTTON_HOVER := Color("4b4068")
const BUTTON_PRESSED := Color("ffa646")
const TEXT := Color("f6f0e6")
const TEXT_DARK := Color("2a1c10")
const MUTED := Color("a59cb9")
const ACCENT := Color("ffa646")
const MONEY := Color("8ef08c")
const DANGER := Color("ff5d6c")

const FONT_SIZE := 26
const RADIUS := 14


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_SIZE

	theme.set_stylebox("panel", "PanelContainer", box(PANEL, PANEL_EDGE, 3, 18))
	theme.set_stylebox("panel", "TooltipPanel", box(INK, PANEL_EDGE, 2, 10))
	theme.set_color("font_color", "TooltipLabel", TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 22)

	theme.set_stylebox("normal", "Button", box(BUTTON, PANEL_EDGE, 2, 12))
	theme.set_stylebox("hover", "Button", box(BUTTON_HOVER, ACCENT, 2, 12))
	theme.set_stylebox("pressed", "Button", box(BUTTON_PRESSED, ACCENT.lightened(0.3), 2, 12))
	theme.set_stylebox("hover_pressed", "Button", box(BUTTON_PRESSED.lightened(0.1), ACCENT.lightened(0.4), 2, 12))
	theme.set_stylebox("disabled", "Button", box(BUTTON.darkened(0.35), PANEL_EDGE.darkened(0.3), 2, 12))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", TEXT_DARK)
	theme.set_color("font_hover_pressed_color", "Button", TEXT_DARK)
	theme.set_color("font_disabled_color", "Button", MUTED.darkened(0.3))

	theme.set_color("font_color", "Label", TEXT)

	var track := box(INK, PANEL_EDGE, 2, 8)
	track.content_margin_top = 6
	track.content_margin_bottom = 6
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", box(ACCENT.darkened(0.2), Color.TRANSPARENT, 0, 8))
	theme.set_stylebox("grabber_area_highlight", "HSlider", box(ACCENT, Color.TRANSPARENT, 0, 8))
	return theme


static func box(fill: Color, edge: Color, edge_width: int, padding: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(edge_width)
	style.set_corner_radius_all(RADIUS)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding * 0.6
	style.content_margin_bottom = padding * 0.6
	style.anti_aliasing = true
	return style
