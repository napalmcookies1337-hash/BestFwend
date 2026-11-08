class_name ShopPanel
extends PanelContainer
## The shop: buy tools and upgrades, and buy and wear colours, skins and rooms.
## The first four tabs are the toolbar's tool categories; the rest are looks.
## Everything goes through Game (buy_tool, upgrade_tool, buy_look, equip_look).

const TOOL_TABS := 4
const LOOK_TABS := [&"color", &"skin", &"room"]
const LOOK_NAMES := {&"color": "Colors", &"skin": "Skins", &"room": "Rooms"}
const TOOL_CARD_WIDTH := 410.0

var tabs: Array[Button] = []
var grid: GridContainer
var money_label: Label
var category := 0
## Tool id, or "kind:id" for looks -> {"card", "status", "button", ...}.
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
	var names: Array[String] = []
	for index: int in ToolDef.CATEGORY_NAMES:
		names.append(ToolDef.CATEGORY_NAMES[index])
	for kind: StringName in LOOK_TABS:
		names.append(LOOK_NAMES[kind])
	for index in names.size():
		if index == TOOL_TABS:
			var gap := Control.new()
			gap.custom_minimum_size.x = 24
			tab_row.add_child(gap)
		var tab := Button.new()
		tab.text = names[index]
		tab.toggle_mode = true
		tab.button_group = group
		tab.focus_mode = Control.FOCUS_NONE
		tab.button_pressed = index == category
		tab.pressed.connect(func() -> void: show_category(index))
		tab_row.add_child(tab)
		tabs.append(tab)

	grid = GridContainer.new()
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)

	Events.listen(self, Events.money_changed, func(_total: int) -> void: _refresh())
	Events.listen(self, Events.tool_purchased, func(_id: StringName) -> void: _refresh())
	Events.listen(self, Events.looks_changed, func(_kind: StringName) -> void: _rebuild())
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


## The look kind on show, or &"" on a tool tab.
func look_kind() -> StringName:
	return LOOK_TABS[category - TOOL_TABS] if category >= TOOL_TABS else &""


func _rebuild() -> void:
	if grid == null:
		return
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	cards.clear()
	var kind := look_kind()
	if kind == &"":
		grid.columns = 3
		for tool in ToolCatalog.in_category(category as ToolDef.Category):
			grid.add_child(_make_tool_card(tool))
	else:
		grid.columns = {&"color": 6, &"skin": 5, &"room": 3}[kind]
		for item_id: String in Cosmetics.table(kind):
			grid.add_child(_make_look_card(kind, item_id))
	_refresh()
	# Shrink to the new tab's contents and stay centred.
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0
	reset_size()
	_recenter.call_deferred()


func _recenter() -> void:
	var area := get_parent_area_size()
	if area != Vector2.ZERO:
		position = ((area - size) / 2.0).round()


func _make_tool_card(tool: ToolDef) -> Control:
	var card := _card()
	card.custom_minimum_size = Vector2(TOOL_CARD_WIDTH, 0)
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
	column.add_child(_label(tool.display_name, 26, UiTheme.TEXT))
	var description := _label(tool.description, 17, UiTheme.MUTED)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(270, 0)
	column.add_child(description)
	var status := _label("", 19, UiTheme.TEXT)
	column.add_child(status)
	var button := _buy_button(func() -> void: _on_tool_pressed(tool.id))
	column.add_child(button)
	cards[tool.id] = {"card": card, "icon": icon, "status": status, "button": button}
	return card


func _make_look_card(kind: StringName, item_id: String) -> Control:
	var item: Dictionary = Cosmetics.table(kind)[item_id]
	var card := _card()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	card.add_child(column)
	var preview: PreviewBox
	if kind == &"room":
		preview = PreviewBox.new(func(canvas: CanvasItem) -> void: _paint_room(canvas, item_id), Vector2(384, 216))
	else:
		preview = PreviewBox.new(func(canvas: CanvasItem) -> void: _paint_buddy(canvas, kind, item_id), Vector2(212, 168))
	column.add_child(preview)
	column.add_child(_label(item["name"], 22, UiTheme.TEXT))
	var status := _label("", 17, UiTheme.TEXT)
	column.add_child(status)
	var button := _buy_button(func() -> void: _on_look_pressed(kind, item_id))
	column.add_child(button)
	cards["%s:%s" % [kind, item_id]] = {"card": card, "status": status, "button": button, "kind": kind, "id": item_id}
	return card


func _refresh() -> void:
	if money_label == null:
		return
	money_label.text = Fmt.money(Game.profile.money)
	for key: String in cards:
		if cards[key].has("kind"):
			_refresh_look_card(cards[key])
		else:
			_refresh_tool_card(key)


func _refresh_tool_card(tool_id: String) -> void:
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
			_status(status, "Owned  ·  %s %d/%d" % [upgrade_name, level, Game.MAX_UPGRADE], UiTheme.ACCENT)
			if cost < 0:
				button.text = "Fully upgraded"
				button.disabled = true
			else:
				button.text = "Upgrade +%d%%  ·  %s" % [roundi(Game.UPGRADE_STEP * 100.0), Fmt.money(cost)]
				button.disabled = Game.profile.money < cost
		&"locked":
			var needed := ToolCatalog.get_tool(tool.requires)
			_status(status, "Needs %s first" % (needed.display_name if needed != null else tool.requires), UiTheme.MUTED)
			button.text = "Locked  ·  %s" % Fmt.money(tool.price)
			button.disabled = true
		&"too_expensive":
			_status(status, "Need %s more" % Fmt.money(tool.price - Game.profile.money), UiTheme.DANGER)
			button.text = "Buy  ·  %s" % Fmt.money(tool.price)
			button.disabled = true
		_:
			_status(status, "Ready to buy!", UiTheme.MONEY)
			button.text = "Buy  ·  %s" % Fmt.money(tool.price)
			button.disabled = false


func _refresh_look_card(parts: Dictionary) -> void:
	var kind: StringName = parts["kind"]
	var item_id: String = parts["id"]
	var price := int(Cosmetics.table(kind)[item_id]["price"])
	var status: Label = parts["status"]
	var button: Button = parts["button"]
	match Game.look_status(kind, item_id):
		&"equipped":
			_status(status, "In use", UiTheme.ACCENT)
			button.text = "Equipped"
			button.disabled = true
		&"owned":
			_status(status, "Owned", UiTheme.MUTED)
			button.text = "Use it"
			button.disabled = false
		&"too_expensive":
			_status(status, "Need %s more" % Fmt.money(price - Game.profile.money), UiTheme.DANGER)
			button.text = "Buy  ·  %s" % Fmt.money(price)
			button.disabled = true
		_:
			_status(status, "Ready to buy!", UiTheme.MONEY)
			button.text = "Buy  ·  %s" % Fmt.money(price)
			button.disabled = false


func _on_tool_pressed(tool_id: String) -> void:
	if Game.owns_tool(tool_id):
		Game.upgrade_tool(tool_id)
	else:
		Game.buy_tool(tool_id)


func _on_look_pressed(kind: StringName, item_id: String) -> void:
	if Game.owned_looks(kind).has(item_id):
		Game.equip_look(kind, item_id)
	elif Game.buy_look(kind, item_id):
		Sfx.play(&"cha_ching", -2.0)


## A colour or skin card shows the Buddy wearing it, with the rest of the
## current look, so you see what you'd get.
func _paint_buddy(canvas: CanvasItem, kind: StringName, item_id: String) -> void:
	var color := Cosmetics.color_of(item_id) if kind == &"color" else Color(Game.profile.buddy_color)
	var skin := item_id if kind == &"skin" else Game.profile.skin
	var box := (canvas as Control).size
	var scale := 0.52
	SkinArt.preview(canvas, Transform2D(0.0, Vector2.ONE * scale, 0.0, Vector2(box.x / 2, box.y - 92.0 * scale - 4.0)), color, skin)


func _paint_room(canvas: CanvasItem, room_id: String) -> void:
	var box := (canvas as Control).size
	canvas.draw_set_transform(Vector2.ZERO, 0.0, box / Room.SIZE)
	BackgroundArt.draw(canvas, room_id)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BUTTON.darkened(0.15), UiTheme.PANEL_EDGE, 2, 14))
	return card


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _status(label: Label, text: String, color: Color) -> void:
	label.text = text
	label.add_theme_color_override("font_color", color)


func _buy_button(on_press: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(on_press)
	return button
