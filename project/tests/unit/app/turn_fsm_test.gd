## TurnFSM 单元测试。
extends GutTest


func test_get_state_setup_1():
	var state := TestHelper.make_standard_state()
	state.phase = GameState.Phase.SETUP
	state.setup_round = 1
	assert_eq(TurnFSM.get_state(state), TurnFSM.STATE_SETUP_1)


func test_get_state_setup_2():
	var state := TestHelper.make_standard_state()
	state.phase = GameState.Phase.SETUP
	state.setup_round = 2
	assert_eq(TurnFSM.get_state(state), TurnFSM.STATE_SETUP_2)


func test_get_state_roll():
	var state := TestHelper.make_standard_state()
	state.phase = GameState.Phase.ROLL
	assert_eq(TurnFSM.get_state(state), TurnFSM.STATE_ROLL)


func test_get_state_action():
	var state := TestHelper.make_standard_state()
	state.phase = GameState.Phase.ACTION
	assert_eq(TurnFSM.get_state(state), TurnFSM.STATE_ACTION)


func test_get_state_move_robber():
	var state := TestHelper.make_standard_state()
	state.phase = GameState.Phase.ACTION
	state.robber_required = true
	assert_eq(TurnFSM.get_state(state), TurnFSM.STATE_MOVE_ROBBER)


func test_get_state_game_over():
	var state := TestHelper.make_standard_state()
	state.is_game_over = true
	assert_eq(TurnFSM.get_state(state), TurnFSM.STATE_GAME_OVER)


func test_state_name():
	assert_eq(TurnFSM.state_name(TurnFSM.STATE_SETUP_1), "SETUP_1")
	assert_eq(TurnFSM.state_name(TurnFSM.STATE_SETUP_2), "SETUP_2")
	assert_eq(TurnFSM.state_name(TurnFSM.STATE_ROLL), "ROLL")
	assert_eq(TurnFSM.state_name(TurnFSM.STATE_ACTION), "ACTION")
	assert_eq(TurnFSM.state_name(TurnFSM.STATE_MOVE_ROBBER), "MOVE_ROBBER")
	assert_eq(TurnFSM.state_name(TurnFSM.STATE_GAME_OVER), "GAME_OVER")
	assert_eq(TurnFSM.state_name(999), "UNKNOWN")


func test_allowed_actions_setup():
	var actions := TurnFSM.allowed_actions(TurnFSM.STATE_SETUP_1)
	assert_eq(actions.size(), 1)
	assert_true(actions.has(Action.TYPE_BUILD))


func test_allowed_actions_roll():
	var actions := TurnFSM.allowed_actions(TurnFSM.STATE_ROLL)
	assert_eq(actions.size(), 1)
	assert_true(actions.has(Action.TYPE_ROLL_DICE))


func test_allowed_actions_action():
	var actions := TurnFSM.allowed_actions(TurnFSM.STATE_ACTION)
	assert_true(actions.has(Action.TYPE_BUILD))
	assert_true(actions.has(Action.TYPE_TRADE))
	assert_true(actions.has(Action.TYPE_USE_DEV_CARD))
	assert_true(actions.has(Action.TYPE_END_TURN))


func test_allowed_actions_move_robber():
	var actions := TurnFSM.allowed_actions(TurnFSM.STATE_MOVE_ROBBER)
	assert_eq(actions.size(), 1)
	assert_true(actions.has(Action.TYPE_MOVE_ROBBER))


func test_allowed_actions_game_over():
	var actions := TurnFSM.allowed_actions(TurnFSM.STATE_GAME_OVER)
	assert_eq(actions.size(), 0)


func test_is_action_allowed():
	assert_true(TurnFSM.is_action_allowed(TurnFSM.STATE_ROLL, Action.TYPE_ROLL_DICE))
	assert_false(TurnFSM.is_action_allowed(TurnFSM.STATE_ROLL, Action.TYPE_BUILD))
	assert_true(TurnFSM.is_action_allowed(TurnFSM.STATE_ACTION, Action.TYPE_BUILD))
	assert_false(TurnFSM.is_action_allowed(TurnFSM.STATE_GAME_OVER, Action.TYPE_BUILD))


func test_get_players_needing_discard():
	var state := TestHelper.make_standard_state()
	# 无玩家需要弃牌（都 0 张）
	assert_eq(TurnFSM.get_players_needing_discard(state).size(), 0)
	# 给玩家 0 很多资源
	state.get_player(0).add_resource(ResType.WOOD, 8)
	assert_eq(TurnFSM.get_players_needing_discard(state).size(), 1)
	# 给玩家 1 也很多
	state.get_player(1).add_resource(ResType.BRICK, 9)
	assert_eq(TurnFSM.get_players_needing_discard(state).size(), 2)
