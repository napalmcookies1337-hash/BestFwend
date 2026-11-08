class_name Rewards
extends Node
## Turns what happens to the Buddy into $$$ using the Economy rules, and shows a
## floating "+$$$" where it happened. Hits close together are added up into one
## popup so a slam doesn't spray numbers everywhere.

const MERGE_TIME := 0.18
const POPUP_SECONDS := 1.1

var sandbox: Sandbox
var economy := Economy.new()
var _pending := 0
var _pending_at := Vector2.ZERO
var _pending_time := 0.0
var _last_combo := 1.0


func _ready() -> void:
	name = "Rewards"
	Events.buddy_hit.connect(_on_hit)
	Events.buddy_interacted.connect(_on_interacted)
	Events.listen(self, Events.buddy_limb_lost, func(_limb: StringName) -> void: _bonus(&"limb"))
	Events.listen(self, Events.buddy_knocked_out, func() -> void: _bonus(&"knockout"))
	Events.listen(self, Events.buddy_shattered, func() -> void: _bonus(&"shatter"))


func _process(delta: float) -> void:
	economy.advance(delta)
	if _pending > 0:
		_pending_time += delta
		if _pending_time >= MERGE_TIME:
			_flush()
	var combo := economy.combo()
	if not is_equal_approx(combo, _last_combo):
		_last_combo = combo
		Events.combo_changed.emit(combo)


## Pays `amount` for `reason`, shown at `at`.
func pay(amount: int, reason: StringName, at: Vector2) -> void:
	if amount <= 0:
		return
	Game.earn(amount, reason)
	_pending += amount
	_pending_at = at
	_pending_time = 0.0


func _on_hit(info: Dictionary) -> void:
	var tool := Economy.tool_for(info)
	var amount := economy.pay(tool, Economy.hit_value(info), _scale(tool))
	pay(amount, tool, info.get("position", _buddy_spot()))


func _on_interacted(kind: StringName, _part: StringName) -> void:
	var amount := economy.pay(kind, Economy.KIND_PAY.get(kind, 0.0), _scale(kind))
	pay(amount, kind, _buddy_spot())


func _bonus(kind: StringName) -> void:
	# Bonuses use the combo but don't tire out a tool.
	var amount := roundi(Economy.BONUS[kind] * economy.combo() * Game.reward_multiplier())
	pay(amount, kind, _buddy_spot())


func _scale(tool: StringName) -> float:
	var def := ToolCatalog.get_tool(String(tool))
	return (def.reward_scale if def != null else 1.0) * Game.reward_multiplier()


func _buddy_spot() -> Vector2:
	if sandbox != null and sandbox.buddy != null:
		return sandbox.buddy.head.global_position
	return Room.SIZE / 2


func _flush() -> void:
	var amount := _pending
	_pending = 0
	if sandbox != null:
		sandbox.fx.add(POPUP_SECONDS, _popup(_pending_at, amount))


static func _popup(at: Vector2, amount: int) -> Callable:
	var text := "+" + Fmt.money(amount)
	var size := int(clampf(26.0 + log(float(amount)) * 5.0, 26.0, 60.0))
	var drift := Vector2(randf_range(-30.0, 30.0), 0.0)
	return func(canvas: CanvasItem, t: float) -> void:
		var font := ThemeDB.fallback_font
		var rise := at + drift * t + Vector2(0, -40.0 - 90.0 * t)
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var spot := rise - Vector2(width / 2.0, 0)
		var alpha := 1.0 if t < 0.6 else 1.0 - (t - 0.6) / 0.4
		var pop := 1.0 + maxf(0.25 - t, 0.0) * 1.6
		canvas.draw_set_transform(rise, 0.0, Vector2.ONE * pop)
		canvas.draw_string_outline(font, spot - rise, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 10, Color(UiTheme.INK, alpha))
		canvas.draw_string(font, spot - rise, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(UiTheme.MONEY, alpha))
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
