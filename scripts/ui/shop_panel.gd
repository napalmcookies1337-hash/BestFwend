class_name ShopPanel
extends PanelContainer
## The shop: buy tools and upgrade the ones you own. One tab per toolbar category.
## Everything goes through Game.buy_tool / Game.upgrade_tool.

const COLUMNS := 3
const CARD_WIDTH := 410.0

var tabs: Array[Button] = []
var grid: GridContainer
var money_label: Label
var category := 0
## tool id -> {"card", "icon", "status", "button"} for the tab on show.
var cards: Dictionary = {}


func _ready() -> void:
	name = "ShopPanel"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	box.add_child(header)
	var title := Label.new()
	title.text = "Shop"
	title.add_theme_font_size_override("font_size", 40)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 34)
	money_label.add_theme_color_override("font_color", UiTheme.MONEY)
	header.add_child(money_label)
	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.pressed.connect(hide)
	header.add_child(close)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	box.add_child(tab_row)
	var group := ButtonGroup.new()
	for index: int in ToolDef.CATEGORY_NAMES:
		var tab := Button.new()
		tab.text = ToolDef.CATEGORY_NAMES[index]
		tab.toggle_mode = true
		tab.button_group = group
		tab.focus_mode = Control.FOCUS_NONE
		tab.button_pressed = index == category
		tab.pressed.connect(func() -> void: show_category(index))
		tab_row.add_child(tab)
		tabs.append(tab)

	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)

	Events.money_changed.connect(func(_total: int) -> void: _refresh())
	Events.tool_purchased.connect(func(_id: StringName) -> void: _refresh())
	visibility_changed.connect(func() -> void:
		if visible:
			_refresh())
	# Anchored at the centre and growing both ways, so it stays centred at any size.
	set_anchors_preset(Control.PRESET_CENTER)
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	_rebuild()


func show_category(index: int) -> void:
	category = index
	for tab_index in tabs.size():
		tabs[tab_index].set_pressed_no_signal(tab_index == index)
	_rebuild()


## Opens the shop on the tab that holds `tool_id`.
func open_at(tool_id: String) -> void:
	var tool := ToolCatalog.get_tool(tool_id)
	if tool != null:
		show_category(tool.category)
	show()


func _rebuild() -> void:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	cards.clear()
	for tool in ToolCatalog.in_category(category as ToolDef.Category):
		grid.add_child(_make_card(tool))
	_refresh()


func _make_card(tool: ToolDef) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0)
	card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BUTTON.darkened(0.15), UiTheme.PANEL_EDGE, 2, 14))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var icon := ToolIcon.new(tool.id, 92.0)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	var name_label := Label.new()
	name_label.text = tool.display_name
	name_label.add_theme_font_size_override("font_size", 26)
	column.add_child(name_label)
	var description := Label.new()
	description.text = tool.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(270, 0)
	description.add_theme_font_size_override("font_size", 17)
	description.add_theme_color_override("font_color", UiTheme.MUTED)
	column.add_child(description)
	var status := Label.new()
	status.add_theme_font_size_override("font_size", 19)
	column.add_child(status)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(func() -> void: _on_card_pressed(tool.id))
	column.add_child(button)
	cards[tool.id] = {"card": card, "icon": icon, "status": status, "button": button}
	return card


func _refresh() -> void:
	if money_label == null:
		return
	money_label.text = Fmt.money(Game.profile.money)
	for tool_id: String in cards:
		_refresh_card(tool_id)


func _refresh_card(tool_id: String) -> void:
	var tool := ToolCatalog.get_tool(tool_id)
	var parts: Dictionary = cards[tool_id]
	var status: Label = parts["status"]
	var button: Button = parts["button"]
	var icon: ToolIcon = parts["icon"]
	var state := Game.tool_status(tool_id)
	icon.set_tool(tool_id, state == &"locked")
	match state:
		&"owned":
			var level := Game.tool_level(tool_id)
			var cost := Game.upgrade_cost(tool_id)
			var upgrade_name := "Strong Arm" if tool_id == "hand" else "Power"
			status.text = "Owned  ·  %s %d/%d" % [upgrade_name, level, Game.MAX_UPGRADE]
			status.add_theme_color_override("font_color", UiTheme.ACCENT)
			if cost < 0:
				button.text = "Fully upgraded"
				button.disabled = true
			else:
				button.text = "Upgrade +%d%%  ·  %s" % [roundi(Game.UPGRADE_STEP * 100.0), Fmt.money(cost)]
				button.disabled = Game.profile.money < cost
		&"locked":
			var needed := ToolCatalog.get_tool(tool.requires)
			status.text = "Needs %s first" % (needed.display_name if needed != null else tool.requires)
			status.add_theme_color_override("font_color", UiTheme.MUTED)
			button.text = "Locked  ·  %s" % Fmt.money(tool.price)
			button.disabled = true
		&"too_expensive":
			status.text = "Need %s more" % Fmt.money(tool.price - Game.profile.money)
			status.add_theme_color_override("font_color", UiTheme.DANGER)
			button.text = "Buy  ·  %s" % Fmt.money(tool.price)
			button.disabled = true
		_:
			status.text = "Ready to buy!"
			status.add_theme_color_override("font_color", UiTheme.MONEY)
			button.text = "Buy  ·  %s" % Fmt.money(tool.price)
			button.disabled = false


func _on_card_pressed(tool_id: String) -> void:
	if Game.owns_tool(tool_id):
		Game.upgrade_tool(tool_id)
	else:
		Game.buy_tool(tool_id)
