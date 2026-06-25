## Event 事件单元测试。
extends GutTest


func test_event_creation():
	var e := Event.new(Event.TYPE_TURN_STARTED, 0)
	assert_eq(e.event_type, Event.TYPE_TURN_STARTED)
	assert_eq(e.player_id, 0)


func test_event_payload():
	var e := Event.new(Event.TYPE_DICE_ROLLED, 0)
	e.set_payload("die1", 3)
	e.set_payload("die2", 4)
	assert_eq(e.get_payload("die1"), 3)
	assert_eq(e.get_payload("die2"), 4)
	assert_eq(e.get_payload("total"), null)


func test_event_type_name():
	assert_eq(Event.type_name(Event.TYPE_TURN_STARTED), "TURN_STARTED")
	assert_eq(Event.type_name(Event.TYPE_DICE_ROLLED), "DICE_ROLLED")
	assert_eq(Event.type_name(Event.TYPE_GAME_OVER), "GAME_OVER")
	assert_eq(Event.type_name(999), "UNKNOWN")


func test_event_create_turn_started():
	var e := Event.create_turn_started(0, 1)
	assert_eq(e.event_type, Event.TYPE_TURN_STARTED)
	assert_eq(e.player_id, 0)
	assert_eq(e.get_payload("round_number"), 1)


func test_event_create_dice_rolled():
	var e := Event.create_dice_rolled(0, 3, 4)
	assert_eq(e.get_payload("die1"), 3)
	assert_eq(e.get_payload("die2"), 4)
	assert_eq(e.get_payload("total"), 7)


func test_event_create_resource_produced():
	var e := Event.create_resource_produced(0, ResType.WOOD, 2)
	assert_eq(e.get_payload("resource"), ResType.WOOD)
	assert_eq(e.get_payload("amount"), 2)


func test_event_create_building_built():
	var e := Event.create_building_built(0, "settlement", 5)
	assert_eq(e.get_payload("building_id"), "settlement")
	assert_eq(e.get_payload("position_id"), 5)


func test_event_create_road_built():
	var e := Event.create_road_built(0, 3)
	assert_eq(e.get_payload("position_id"), 3)


func test_event_create_trade_completed():
	var give := ResourceSet.new()
	give.set_amount(ResType.WOOD, 4)
	var e := Event.create_trade_completed(0, "bank", give)
	assert_eq(e.get_payload("trade_type"), "bank")
	var give_dict: Dictionary = e.get_payload("give")
	assert_eq(give_dict["wood"], 4)


func test_event_create_robber_moved():
	var e := Event.create_robber_moved(0, 1, 5)
	assert_eq(e.get_payload("old_hex_id"), 1)
	assert_eq(e.get_payload("new_hex_id"), 5)


func test_event_create_dev_card_used():
	var e := Event.create_dev_card_used(0, "knight")
	assert_eq(e.get_payload("card_id"), "knight")


func test_event_create_resource_stolen():
	var e := Event.create_resource_stolen(0, 1, ResType.WOOD)
	assert_eq(e.player_id, 0)
	assert_eq(e.get_payload("victim_id"), 1)
	assert_eq(e.get_payload("resource"), ResType.WOOD)


func test_event_create_cards_discarded():
	var ds := ResourceSet.new()
	ds.set_amount(ResType.WOOD, 2)
	var e := Event.create_cards_discarded(0, ds)
	var d: Dictionary = e.get_payload("discarded")
	assert_eq(d["wood"], 2)


func test_event_create_game_over():
	var e := Event.create_game_over(2)
	assert_eq(e.event_type, Event.TYPE_GAME_OVER)
	assert_eq(e.get_payload("winner_id"), 2)
