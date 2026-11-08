extends TestSuite
## Milestone 5: what things pay, combos and fatigue, buying, unlock chains,
## upgrades, the shop window and the toolbar locks. Run with --fixed-fps 120.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Sandbox


func before_each() -> void:
	reset_game("shop")


func after_each() -> void:
	if main != null and is_instance_valid(main):
		main.queue_free()
		main = null
	await frames(1)
	Engine.time_scale = 1.0


func test_hit_value() -> bool:
	check_eq(Economy.hit_value({"force": 400.0, "damage": 0.0}), 0.0, "a nudge pays nothing")
	check(Economy.hit_value({"force": 900.0, "damage": 0.0}) > 0.0, "a solid bump pays a little")
	var slam := Economy.hit_value({"force": 3000.0, "damage": 20.0})
	check(slam > 15.0 and slam < 23.0, "a hard slam pays about 18 (%.1f)" % slam)
	return true


func test_tool_credit() -> bool:
	check_eq(Economy.tool_for({"source": &"wall"}), &"hand", "wall slams belong to the Hand")
	check_eq(Economy.tool_for({"source": &"explosion", "tool": &"grenade"}), &"grenade", "explosions credit their tool")
	check_eq(Economy.tool_for({"source": &"nuke"}), &"mini_nuke", "object kinds map to tools")
	check_eq(Economy.tool_for({"source": &"fire"}), &"ignite", "fire is the Ignite tool")
	return true


func test_variety_builds_a_combo() -> bool:
	var economy := Economy.new()
	check_eq(economy.combo(), 1.0, "no combo at first")
	economy.pay(&"hand", 10.0)
	economy.advance(1.0)
	economy.pay(&"slap", 10.0)
	economy.advance(1.0)
	economy.pay(&"bat", 10.0)
	check_eq(economy.combo(), 1.5, "three tools: x1.5")
	economy.advance(Economy.COMBO_WINDOW + 0.5)
	check_eq(economy.combo(), 1.0, "it fades when you stop")
	for index in 12:
		economy.pay(StringName("tool_%d" % index), 1.0)
	check_eq(economy.combo(), Economy.MAX_COMBO, "capped")
	return true


func test_spamming_one_tool_pays_less() -> bool:
	var economy := Economy.new()
	var first := economy.pay(&"pistol", 100.0)
	var last := 0
	for _index in 20:
		economy.advance(0.5)
		last = economy.pay(&"pistol", 100.0)
	check_eq(first, 100, "full pay when fresh")
	check(last < 50 and last >= roundi(100.0 * Economy.MIN_FATIGUE), "spam pays far less (%d)" % last)
	economy.advance(30.0)
	check_eq(economy.pay(&"pistol", 100.0), 100, "rested, it pays fully again")
	return true


func test_one_slam_is_one_use() -> bool:
	var economy := Economy.new()
	# A slam hits several parts within a moment; that's one use, not five.
	var paid := 0
	for _part in 5:
		paid += economy.pay(&"hand", 10.0)
		economy.advance(0.02)
	check_eq(paid, 50, "every part paid in full")
	return true


func test_buying_follows_the_chain() -> bool:
	check_eq(Game.tool_status("hand"), &"owned", "start with the Hand")
	check_eq(Game.tool_status("poke"), &"too_expensive", "poke costs money")
	check_eq(Game.tool_status("slap"), &"locked", "slap needs poke first")
	Game.earn(1000, &"test")
	check(Game.buy_tool("poke"), "bought poke")
	check_eq(Game.profile.money, 900, "paid 100")
	check_eq(Game.tool_status("slap"), &"buyable", "slap unlocked")
	check(not Game.buy_tool("poke"), "can't buy twice")
	check(not Game.buy_tool("katana"), "can't skip the chain")
	check(not Game.buy_tool("mini_nuke"), "can't buy what you can't afford")
	check_eq(Game.profile.money, 900, "failed buys cost nothing")
	return true


func test_every_requirement_exists_and_chains_end() -> bool:
	for tool in ToolCatalog.all():
		if tool.requires.is_empty():
			continue
		var needed := ToolCatalog.get_tool(tool.requires)
		check(needed != null, "%s needs a real tool (%s)" % [tool.id, tool.requires])
		if needed != null:
			check(needed.price <= tool.price, "%s costs at least what %s does" % [tool.id, needed.id])
	return true


func test_upgrades() -> bool:
	Game.earn(100000, &"test")
	Game.buy_tool("ball")
	Game.buy_tool("bat")
	check_eq(Game.tool_power("bat"), 1.0, "no upgrades yet")
	var first := Game.upgrade_cost("bat")
	check(Game.upgrade_tool("bat"), "upgraded")
	check_eq(Game.tool_level("bat"), 1, "level 1")
	check_eq(Game.tool_power("bat"), 1.25, "25% stronger")
	check(Game.upgrade_cost("bat") > first, "the next one costs more")
	Game.upgrade_tool("bat")
	Game.upgrade_tool("bat")
	check_eq(Game.upgrade_cost("bat"), -1, "maxed at 3")
	check(not Game.upgrade_tool("bat"), "can't go past max")
	check_eq(Game.upgrade_cost("katana"), -1, "can't upgrade what you don't own")
	check(Game.upgrade_cost("hand") > 0, "the Hand can be upgraded too")
	return true


func test_ownership_is_saved() -> bool:
	Game.earn(5000, &"test")
	Game.buy_tool("ball")
	Game.upgrade_tool("ball")
	Game.load_profile()
	check(Game.owns_tool("ball"), "ownership survives a reload")
	check_eq(Game.tool_level("ball"), 1, "upgrade level survives a reload")
	return true


func test_upgraded_grenade_blasts_harder() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(1)
	var plain := main.spawn_object(&"grenade", Vector2(300, 300))
	var strong := main.spawn_object(&"grenade", Vector2(600, 300), Vector2.ZERO, 1.75)
	check_eq(plain.power_scale, 1.0, "plain")
	check_eq(strong.power_scale, 1.75, "upgraded power carried by the object")
	return true


func test_hits_pay_money() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await physics_frames(480)
	var before := Game.profile.money
	main.buddy.take_hit({"part": &"torso", "force": 3000.0, "source": &"wall", "position": main.buddy.torso.global_position})
	check(Game.profile.money > before + 10, "a slam pays (%d)" % (Game.profile.money - before))
	before = Game.profile.money
	main.buddy.take_hit({"part": &"torso", "force": 1000.0, "damage": 300.0, "position": main.buddy.torso.global_position})
	check(Game.profile.money >= before + Economy.BONUS[&"knockout"], "a knockout pays a bonus")
	await frames(40)
	check(main.fx.count() > 0, "a +$$$ popup appears")
	return true


func test_kind_actions_pay_a_little() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await physics_frames(480)
	var before := Game.profile.money
	main.buddy.notice(&"poke", &"torso")
	var paid := Game.profile.money - before
	check(paid >= 3 and paid <= roundi(3 * Economy.MAX_COMBO), "a poke pays 3, plus any combo (%d)" % paid)
	return true


func test_shop_window_buys() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)
	var shop: ShopPanel = main.hud.shop_panel
	main.hud.shop_button.pressed.emit()
	check(shop.visible, "Shop button opens it")
	await frames(2)
	var screen := Rect2(Vector2.ZERO, main.hud.root.size)
	check(screen.encloses(shop.get_rect()), "fully on screen (%s in %s)" % [shop.get_rect(), screen])
	check(absf(shop.get_rect().get_center().x - screen.get_center().x) < 4.0, "centred")
	var poke_button: Button = shop.cards["poke"]["button"]
	check(poke_button.disabled, "can't afford poke yet")
	Game.earn(110, &"test")
	check(not poke_button.disabled, "now it can")
	poke_button.pressed.emit()
	check(Game.owns_tool("poke"), "bought from the shop")
	check_eq(Game.profile.selected_tool, "poke", "and it's selected")
	check(main.hud.slots[1].usable, "the toolbar slot unlocks")
	check(String(shop.cards["poke"]["button"].text).begins_with("Upgrade"), "the card offers an upgrade now")
	shop.show_category(3)
	check(shop.cards.has("mini_nuke") == false and shop.cards.has("black_hole"), "tabs switch")
	check(main.hud.close_menus(), "Esc closes it")
	return true


func test_locked_slot_opens_the_shop() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)
	main.hud.category_buttons[2].pressed.emit()
	main.hud.slots[5].pressed.emit()
	check(main.hud.shop_panel.visible, "clicking a locked tool opens the shop")
	check_eq(main.hud.shop_panel.category, 2, "on its tab")
	return true


func test_new_tool_is_announced_once() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)
	var toasts: Array = []
	var on_toast := func(text: String) -> void: toasts.append(text)
	var toast_box: VBoxContainer = main.hud._toasts
	var before := toast_box.get_child_count()
	Game.earn(110, &"test")
	check_eq(toast_box.get_child_count(), before + 1, "told about Poke")
	check(main.hud.shop_button.text.contains("!"), "Shop button marked")
	Game.earn(1, &"test")
	check_eq(toast_box.get_child_count(), before + 1, "only once")
	for index in 6:
		main.hud.show_toast("news %d" % index)
	check(toast_box.get_child_count() <= Hud.MAX_TOASTS, "toasts never pile up")
	return true


func test_economy_pacing() -> bool:
	# Rough early game: only the Hand, a hard slam every 2.5 seconds.
	var economy := Economy.new()
	var money := 0
	var seconds := 0.0
	var first_buy := -1.0
	while seconds < 600.0:
		for part in 3:
			money += economy.pay(&"hand", Economy.hit_value({"force": 2600.0, "damage": 12.0 - part * 4.0}))
		if first_buy < 0.0 and money >= 100:
			first_buy = seconds
		economy.advance(2.5)
		seconds += 2.5
	check(first_buy >= 0.0 and first_buy <= 60.0, "first tool affordable within a minute (%.0f s)" % first_buy)
	check(money < 25000, "the nuke takes more than 10 minutes of throwing alone (%d)" % money)
	check(money > 3000, "but throwing still adds up (%d in 10 min)" % money)
	return true
