## GameSession 单元测试。
extends GutTest


func test_setup_new_game():
	var session := GameSession.new()
	var r := session.setup_new_game(4, 42)
	assert_true(r.ok, r.error_message)
	assert_eq(session.state.player_count(), 4)
	assert_eq(session.state.phase, GameState.Phase.SETUP)
	assert_eq(session.state.setup_round, 1)


func test_setup_invalid_player_count():
	var session := GameSession.new()
	var r := session.setup_new_game(1)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_ARG)


func test_submit_action_not_initialized():
	var session := GameSession.new()
	var a := EndTurnAction.new(0)
	var r := session.submit_action(a)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_STATE)


func test_submit_action_setup_settlement():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	# 找一个可用顶点
	var board: Board = session.state.board
	var vid: int = -1
	for v in board.all_vertices():
		var vd: Board.VertexData = v
		if not session.state.placements.has("v:%d" % vd.id):
			vid = vd.id
			break
	assert_true(vid >= 0)
	var a := BuildAction.new(0, "settlement", vid)
	var r := session.submit_action(a)
	assert_true(r.ok, r.error_message)


func test_submit_action_invalid_returns_error():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	# 错误玩家
	var a := EndTurnAction.new(1)
	var r := session.submit_action(a)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_NOT_YOUR_TURN)


func test_action_history():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	var board: Board = session.state.board
	var vid: int = -1
	for v in board.all_vertices():
		var vd: Board.VertexData = v
		if not session.state.placements.has("v:%d" % vd.id):
			vid = vd.id
			break
	var a := BuildAction.new(0, "settlement", vid)
	session.submit_action(a)
	assert_eq(session.action_history().size(), 1)


func test_event_history():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	var board: Board = session.state.board
	var vid: int = -1
	for v in board.all_vertices():
		var vd: Board.VertexData = v
		if not session.state.placements.has("v:%d" % vd.id):
			vid = vd.id
			break
	var a := BuildAction.new(0, "settlement", vid)
	session.submit_action(a)
	# 应有事件（至少 BUILDING_BUILT）
	assert_true(session.event_history().size() > 0)


func test_current_fsm_state():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	assert_eq(session.current_fsm_state(), TurnFSM.STATE_SETUP_1)


func test_allowed_actions():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	var actions := session.allowed_actions()
	assert_true(actions.has(Action.TYPE_BUILD))


func test_is_action_allowed():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	assert_true(session.is_action_allowed(BuildAction.new(0, "settlement", 0)))
	assert_false(session.is_action_allowed(RollDiceAction.new(0)))


func test_event_bus_dispatch():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	var received: Array = []
	session.event_bus.subscribe(Event.TYPE_BUILDING_BUILT, func(e: Event): received.append(e))
	var board: Board = session.state.board
	var vid: int = -1
	for v in board.all_vertices():
		var vd: Board.VertexData = v
		if not session.state.placements.has("v:%d" % vd.id):
			vid = vd.id
			break
	var a := BuildAction.new(0, "settlement", vid)
	session.submit_action(a)
	assert_true(received.size() > 0)


func test_full_setup_round():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	var board: Board = session.state.board
	# 第一轮：4 人各放定居点+道路
	for pid in range(4):
		assert_eq(session.state.current_player_id, pid)
		var vid := _find_free_vertex(session.state, board)
		var sa := BuildAction.new(pid, "settlement", vid)
		var r1 := session.submit_action(sa)
		assert_true(r1.ok, "p%d settlement: %s" % [pid, r1.error_message])
		var edges := board.vertex_edges(vid)
		var ra := BuildAction.new(pid, "road", edges[0])
		var r2 := session.submit_action(ra)
		assert_true(r2.ok, "p%d road: %s" % [pid, r2.error_message])
	# 应进入第二轮
	assert_eq(session.state.setup_round, 2)
	# 第二轮：反向 4→1
	for pid in range(3, -1, -1):
		assert_eq(session.state.current_player_id, pid)
		var vid := _find_free_vertex(session.state, board)
		var sa := BuildAction.new(pid, "settlement", vid)
		var r1 := session.submit_action(sa)
		assert_true(r1.ok, "p%d settlement r2: %s" % [pid, r1.error_message])
		var edges := board.vertex_edges(vid)
		var ra := BuildAction.new(pid, "road", edges[0])
		var r2 := session.submit_action(ra)
		assert_true(r2.ok, "p%d road r2: %s" % [pid, r2.error_message])
	# SETUP 完成后应进入 ROLL 阶段
	assert_eq(session.state.phase, GameState.Phase.ROLL)
	assert_eq(session.state.setup_round, 0)


func _find_free_vertex(state: GameState, board: Board) -> int:
	for v in board.all_vertices():
		var vd: Board.VertexData = v
		if state.placements.has("v:%d" % vd.id):
			continue
		var adj := board.adjacent_vertices(vd.id)
		var ok := true
		for adj_vid in adj:
			if state.placements.has("v:%d" % adj_vid):
				ok = false
				break
		if ok:
			return vd.id
	return -1


func test_roll_dice_transitions_to_action():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	var board: Board = session.state.board
	# 快速完成 SETUP
	_complete_setup(session, board)
	# 掷骰
	assert_eq(session.current_fsm_state(), TurnFSM.STATE_ROLL)
	var a := RollDiceAction.new(0)
	var r := session.submit_action(a)
	assert_true(r.ok, r.error_message)
	# 应进入 ACTION 或 MOVE_ROBBER（7点）
	var fsm := session.current_fsm_state()
	assert_true(fsm == TurnFSM.STATE_ACTION or fsm == TurnFSM.STATE_MOVE_ROBBER)


func _complete_setup(session: GameSession, board: Board) -> void:
	# 第一轮
	for pid in range(4):
		var vid := _find_free_vertex(session.state, board)
		session.submit_action(BuildAction.new(pid, "settlement", vid))
		var edges := board.vertex_edges(vid)
		session.submit_action(BuildAction.new(pid, "road", edges[0]))
	# 第二轮
	for pid in range(3, -1, -1):
		var vid := _find_free_vertex(session.state, board)
		session.submit_action(BuildAction.new(pid, "settlement", vid))
		var edges := board.vertex_edges(vid)
		session.submit_action(BuildAction.new(pid, "road", edges[0]))


func test_end_turn_advances_player():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	_complete_setup(session, session.state.board)
	# 掷骰
	session.submit_action(RollDiceAction.new(0))
	# 如果需要移动强盗，先处理
	if session.state.robber_required:
		var board: Board = session.state.board
		for h in board.all_hexes():
			if h.id != session.state.robber_hex_id and h.terrain_id != "desert":
				session.submit_action(MoveRobberAction.new(0, h.id, -1))
				break
	# 结束回合
	var old_pid := session.state.current_player_id
	var a := EndTurnAction.new(0)
	var r := session.submit_action(a)
	assert_true(r.ok, r.error_message)
	assert_eq(session.state.current_player_id, (old_pid + 1) % 4)
