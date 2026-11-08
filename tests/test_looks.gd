extends TestSuite
## Milestone 6: colours, skins and rooms. Buying, wearing, saving, and the shop tabs.

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Sandbox


func before_each() -> void:
	reset_game("looks")


func after_each() -> void:
	if main != null and is_instance_valid(main):
		main.queue_free()
		main = null
	await frames(1)


func test_start_with_the_free_looks() -> bool:
	for kind: StringName in Cosmetics.KINDS:
		var free := Cosmetics.free_item(kind)
		check_eq(Cosmetics.table(kind)[free]["price"], 0, "%s: the first is free" % kind)
		check_eq(Game.look_status(kind, free), &"equipped", "%s: and worn" % kind)
	check_eq(Game.profile.buddy_color, Cosmetics.COLORS["orange"]["hex"], "tangerine")
	return true


func test_every_look_has_a_name_and_a_price() -> bool:
	check_eq(Cosmetics.COLORS.size(), 11, "11 colours")
	check_eq(Cosmetics.SKINS.size(), 10, "10 skins")
	check_eq(Cosmetics.ROOMS.size(), 6, "6 rooms")
	for kind: StringName in Cosmetics.KINDS:
		var table := Cosmetics.table(kind)
		for item_id: String in table:
			check(not String(table[item_id]["name"]).is_empty(), "%s %s named" % [kind, item_id])
			check(item_id == Cosmetics.free_item(kind) or int(table[item_id]["price"]) > 0, "%s %s priced" % [kind, item_id])
	for color_id: String in Cosmetics.COLORS:
		check_eq(Cosmetics.color_id_for(Cosmetics.COLORS[color_id]["hex"]), color_id, "%s round-trips" % color_id)
	return true


func test_buy_and_wear() -> bool:
	check_eq(Game.look_status(&"skin", "crown"), &"too_expensive", "can't afford the crown")
	check(not Game.buy_look(&"skin", "crown"), "so can't buy it")
	Game.earn(10000, &"test")
	check_eq(Game.look_status(&"skin", "crown"), &"buyable", "now it can")
	check(Game.buy_look(&"skin", "crown"), "bought")
	check_eq(Game.profile.skin, "crown", "and put it on")
	check_eq(Game.profile.money, 5000, "paid 5,000")
	check(Game.equip_look(&"skin", "classic"), "swap back for free")
	check_eq(Game.look_status(&"skin", "crown"), &"owned", "still owned")
	check(not Game.equip_look(&"skin", "devil"), "can't wear what you don't own")
	check(Game.buy_look(&"color", "gold"), "gold")
	check_eq(Game.profile.buddy_color, Cosmetics.COLORS["gold"]["hex"], "colour applied")
	check(Game.buy_look(&"room", "kitchen"), "kitchen")
	check_eq(Game.profile.background, "kitchen", "room applied")
	return true


func test_looks_are_saved() -> bool:
	Game.earn(20000, &"test")
	Game.buy_look(&"color", "mint")
	Game.buy_look(&"skin", "cat")
	Game.buy_look(&"room", "space")
	Game.load_profile()
	check_eq(Game.equipped_look(&"color"), "mint", "colour remembered")
	check_eq(Game.equipped_look(&"skin"), "cat", "skin remembered")
	check_eq(Game.equipped_look(&"room"), "space", "room remembered")
	check(Game.owned_looks(&"color").has("mint"), "ownership remembered")
	return true


func test_unowned_look_in_a_save_is_ignored() -> bool:
	var loaded := Profile.from_dict({"buddy_color": Cosmetics.COLORS["gold"]["hex"], "skin": "crown", "background": "space"})
	check_eq(loaded.buddy_color, Cosmetics.COLORS["orange"]["hex"], "can't wear an unbought colour")
	check_eq(loaded.skin, "classic", "or skin")
	check_eq(loaded.background, "bedroom", "or room")
	return true


func test_wearing_changes_the_game_live() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)
	Game.earn(20000, &"test")
	Game.buy_look(&"color", "grape")
	Game.buy_look(&"skin", "tophat")
	Game.buy_look(&"room", "dungeon")
	check(main.buddy.color.is_equal_approx(Cosmetics.color_of("grape")), "the Buddy turns grape")
	check_eq(main.buddy.skin_id, "tophat", "and wears the hat")
	check_eq(main.room.background_id, "dungeon", "the room changes")
	main.respawn()
	await frames(1)
	check_eq(main.buddy.skin_id, "tophat", "a new Buddy keeps the look")
	return true


func test_shop_look_tabs() -> bool:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await frames(2)
	var shop: ShopPanel = main.hud.shop_panel
	shop.show()
	shop.show_category(ShopPanel.TOOL_TABS + 1)
	check_eq(shop.look_kind(), &"skin", "skins tab")
	check_eq(shop.cards.size(), Cosmetics.SKINS.size(), "a card per skin")
	var classic: Button = shop.cards["skin:classic"]["button"]
	check(classic.disabled and classic.text == "Equipped", "the one you wear says so")
	var party: Button = shop.cards["skin:party"]["button"]
	check(party.disabled, "too expensive at first")
	Game.earn(600, &"test")
	check(not party.disabled, "affordable now")
	party.pressed.emit()
	await frames(1)
	check_eq(Game.profile.skin, "party", "bought and worn from the shop")
	shop.show_category(ShopPanel.TOOL_TABS + 2)
	check_eq(shop.cards.size(), Cosmetics.ROOMS.size(), "a card per room")
	await frames(2)
	var screen := Rect2(Vector2.ZERO, main.hud.root.size)
	for tab in range(ShopPanel.TOOL_TABS, ShopPanel.TOOL_TABS + 3):
		shop.show_category(tab)
		await frames(2)
		check(screen.encloses(shop.get_rect()), "tab %d fits on screen (%s)" % [tab, shop.get_rect()])
	return true
