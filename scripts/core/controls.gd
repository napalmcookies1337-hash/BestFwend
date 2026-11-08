class_name Controls
extends RefCounted
## Registers the keyboard actions. Mouse buttons are read directly by the play area,
## because grabbing needs exact positions rather than actions.

const KEYS := {
	"respawn": KEY_R,
	"clean_up": KEY_C,
	"slowmo": KEY_T,
	"toggle_fullscreen": KEY_F11,
	"close_menu": KEY_ESCAPE,
	"dev_cash": KEY_F9, # Debug builds only.
	"dev_ball": KEY_F8, # Debug builds only.
	"dev_unlock": KEY_F7, # Debug builds only.
}
const HOTBAR_SLOTS := 9


static func register() -> void:
	for action: String in KEYS:
		_add_key(action, KEYS[action])
	for index in HOTBAR_SLOTS:
		_add_key("tool_%d" % (index + 1), (KEY_1 + index) as Key)


static func _add_key(action: String, keycode: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)
