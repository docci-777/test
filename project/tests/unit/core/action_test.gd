## Action 动作系统单元测试。
extends GutTest


func test_action_base_type():
	var a := Action.new(Action.TYPE_END_TURN, 0)
	assert_eq(a.action_type, Action.TYPE_END_TURN)
	assert_eq(a.player_id, 0)


func test_action_type_name():
	assert_eq(Action.type_name(Action.TYPE_ROLL_DICE), "ROLL_DICE")
	assert_eq(Action.type_name(Action.TYPE_BUILD), "BUILD")
	assert_eq(Action.type_name(Action.TYPE_TRADE), "TRADE")
	assert_eq(Action.type_name(Action.TYPE_USE_DEV_CARD), "USE_DEV_CARD")
	assert_eq(Action.type_name(Action.TYPE_MOVE_ROBBER), "MOVE_ROBBER")
	assert_eq(Action.type_name(Action.TYPE_END_TURN), "END_TURN")
	assert_eq(Action.type_name(Action.TYPE_DISCARD), "DISCARD")
	assert_eq(Action.type_name(999), "UNKNOWN")


func test_roll_dice_action():
	var a := RollDiceAction.new(0)
	assert_eq(a.action_type, Action.TYPE_ROLL_DICE)
	assert_eq(a.player_id, 0)


func test_build_action():
	var a := BuildAction.new(1, "settlement", 5)
	assert_eq(a.action_type, Action.TYPE_BUILD)
	assert_eq(a.player_id, 1)
	assert_eq(a.building_id, "settlement")
	assert_eq(a.position_id, 5)


func test_trade_action_bank():
	var give := ResourceSet.new()
	give.set_amount(ResType.WOOD, 4)
	var a := TradeAction.new_bank_trade(0, give, ResType.BRICK)
	assert_eq(a.action_type, Action.TYPE_TRADE)
	assert_eq(a.trade_type, TradeAction.TRADE_BANK)
	assert_eq(a.give.get_amount(ResType.WOOD), 4)
	assert_eq(a.receive_type, ResType.BRICK)


func test_trade_action_port():
	var give := ResourceSet.new()
	give.set_amount(ResType.WOOD, 2)
	var a := TradeAction.new_port_trade(0, give, ResType.BRICK, 7)
	assert_eq(a.trade_type, TradeAction.TRADE_PORT)
	assert_eq(a.port_vertex_id, 7)


func test_trade_action_player():
	var give := ResourceSet.new()
	give.set_amount(ResType.WOOD, 1)
	var recv := ResourceSet.new()
	recv.set_amount(ResType.BRICK, 1)
	var a := TradeAction.new_player_trade(0, 1, give, recv)
	assert_eq(a.trade_type, TradeAction.TRADE_PLAYER)
	assert_eq(a.target_player_id, 1)
	assert_eq(a.receive_set.get_amount(ResType.BRICK), 1)


func test_use_dev_card_action():
	var a := UseDevCardAction.new(0, "knight")
	assert_eq(a.action_type, Action.TYPE_USE_DEV_CARD)
	assert_eq(a.card_id, "knight")


func test_move_robber_action():
	var a := MoveRobberAction.new(0, 5, 1)
	assert_eq(a.action_type, Action.TYPE_MOVE_ROBBER)
	assert_eq(a.target_hex_id, 5)
	assert_eq(a.target_player_id, 1)


func test_end_turn_action():
	var a := EndTurnAction.new(0)
	assert_eq(a.action_type, Action.TYPE_END_TURN)
	assert_eq(a.player_id, 0)


func test_discard_action():
	var ds := ResourceSet.new()
	ds.set_amount(ResType.WOOD, 2)
	var a := DiscardAction.new(0, ds)
	assert_eq(a.action_type, Action.TYPE_DISCARD)
	assert_eq(a.discard_set.get_amount(ResType.WOOD), 2)
