## 端到端模拟对局测试。
##
## 在无 UI 下跑完一局模拟对局并判定胜利。
extends GutTest


func test_simulated_game_completes():
	var session := GameSession.new()
	session.setup_new_game(4, 42)
	var board: Board = session.state.board
	
	# 完成 SETUP 阶段
	_complete_setup(session, board)
	
	# 模拟多回合
	var max_rounds := 500
	var rounds := 0
	while not session.is_game_over() and rounds < max_rounds:
		rounds += 1
		_play_one_turn(session, board)
	
	# 游戏应结束
	assert_true(session.is_game_over(), "game should end within %d rounds" % max_rounds)
	assert_not_null(session.winner())


func _complete_setup(session: GameSession, board: Board) -> void:
	# 第一轮：正向
	for pid in range(4):
		var vid := _find_free_vertex(session.state, board)
		session.submit_action(BuildAction.new(pid, "settlement", vid))
		var edges := board.vertex_edges(vid)
		session.submit_action(BuildAction.new(pid, "road", edges[0]))
	# 第二轮：反向
	for pid in range(3, -1, -1):
		var vid := _find_free_vertex(session.state, board)
		session.submit_action(BuildAction.new(pid, "settlement", vid))
		var edges := board.vertex_edges(vid)
		session.submit_action(BuildAction.new(pid, "road", edges[0]))


func _play_one_turn(session: GameSession, board: Board) -> void:
	var pid: int = session.state.current_player_id
	
	# 掷骰
	if session.current_fsm_state() == TurnFSM.STATE_ROLL:
		var r := session.submit_action(RollDiceAction.new(pid))
		if not r.ok:
			session.submit_action(EndTurnAction.new(pid))
			return
	
	# 处理强盗
	if session.state.robber_required:
		# 找一个非沙漠、非当前强盗位置的六边形
		var target_hex := -1
		for h in board.all_hexes():
			if h.id != session.state.robber_hex_id and h.terrain_id != "desert":
				target_hex = h.id
				break
		if target_hex >= 0:
			# 尝试偷取（找有建筑的玩家）
			var steal_target := -1
			var players_near := RulesEngine.get_players_near_hex(session.state, target_hex)
			for p_id in players_near:
				if p_id != pid and session.state.get_player(p_id).hand_size() > 0:
					steal_target = p_id
					break
			session.submit_action(MoveRobberAction.new(pid, target_hex, steal_target))
	
	# 尝试建造
	_try_build(session, board, pid)
	
	# 结束回合
	if session.current_fsm_state() == TurnFSM.STATE_ACTION:
		session.submit_action(EndTurnAction.new(pid))


func _try_build(session: GameSession, board: Board, pid: int) -> void:
	var player: PlayerState = session.state.get_player(pid)
	if player == null:
		return
	# 尝试升级城市（优先）
	if player.resources.get_amount(ResType.WHEAT) >= 2 and player.resources.get_amount(ResType.ORE) >= 3:
		var vid := _find_upgradeable_vertex(session.state, board, pid)
		if vid >= 0:
			session.submit_action(BuildAction.new(pid, "city", vid))
			return
	# 尝试建定居点
	if player.resources.get_amount(ResType.WOOD) >= 1 and player.resources.get_amount(ResType.BRICK) >= 1 \
			and player.resources.get_amount(ResType.SHEEP) >= 1 and player.resources.get_amount(ResType.WHEAT) >= 1:
		var vid := _find_buildable_vertex(session.state, board, pid)
		if vid >= 0:
			session.submit_action(BuildAction.new(pid, "settlement", vid))
			return
	# 尝试建道路
	if player.resources.get_amount(ResType.WOOD) >= 1 and player.resources.get_amount(ResType.BRICK) >= 1:
		var eid := _find_buildable_edge(session.state, board, pid)
		if eid >= 0:
			session.submit_action(BuildAction.new(pid, "road", eid))
			return
	# 尝试买发展卡
	if player.resources.get_amount(ResType.SHEEP) >= 1 and player.resources.get_amount(ResType.WHEAT) >= 1 \
			and player.resources.get_amount(ResType.ORE) >= 1:
		session.submit_action(BuildAction.new(pid, "dev_card", -1))
		return
	# 尝试银行交易（4:1）
	_try_bank_trade(session, pid)


func _try_bank_trade(session: GameSession, pid: int) -> void:
	var player: PlayerState = session.state.get_player(pid)
	if player == null:
		return
	# 找一种有 4 张以上的资源
	for t in ResType.all():
		if player.resources.get_amount(t) >= 4:
			# 换取最缺的资源
			var need := _find_needed_resource(player)
			if need != ResType.INVALID:
				var give := ResourceSet.new()
				give.set_amount(t, 4)
				session.submit_action(TradeAction.new_bank_trade(pid, give, need))
				return


func _find_needed_resource(player: PlayerState) -> int:
	# 优先找定居点缺的资源
	if player.resources.get_amount(ResType.WOOD) < 1:
		return ResType.WOOD
	if player.resources.get_amount(ResType.BRICK) < 1:
		return ResType.BRICK
	if player.resources.get_amount(ResType.SHEEP) < 1:
		return ResType.SHEEP
	if player.resources.get_amount(ResType.WHEAT) < 1:
		return ResType.WHEAT
	if player.resources.get_amount(ResType.ORE) < 1:
		return ResType.ORE
	return ResType.INVALID


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


func _find_buildable_edge(state: GameState, board: Board, pid: int) -> int:
	for e in board.all_edges():
		var ed: Board.EdgeData = e
		if state.placements.has("e:%d" % ed.id):
			continue
		var edge_verts := board.edge_vertices(ed.id)
		for vid in edge_verts:
			var p: Placement = state.placements.get("v:%d" % vid)
			if p != null and p.player_id == pid:
				if p.building_id == "settlement" or p.building_id == "city":
					return ed.id
			var adj_edges := board.vertex_edges(vid)
			for adj_eid in adj_edges:
				if adj_eid == ed.id:
					continue
				var adj_p: Placement = state.placements.get("e:%d" % adj_eid)
				if adj_p != null and adj_p.player_id == pid and adj_p.building_id == "road":
					return ed.id
	return -1


func _find_buildable_vertex(state: GameState, board: Board, pid: int) -> int:
	for v in board.all_vertices():
		var vd: Board.VertexData = v
		if state.placements.has("v:%d" % vd.id):
			continue
		# 距离规则
		var adj := board.adjacent_vertices(vd.id)
		var ok := true
		for adj_vid in adj:
			if state.placements.has("v:%d" % adj_vid):
				ok = false
				break
		if not ok:
			continue
		# 连接性
		var edges := board.vertex_edges(vd.id)
		var connected := false
		for eid in edges:
			var p: Placement = state.placements.get("e:%d" % eid)
			if p != null and p.player_id == pid and p.building_id == "road":
				connected = true
				break
		if connected:
			return vd.id
	return -1


func _find_upgradeable_vertex(state: GameState, board: Board, pid: int) -> int:
	for v in board.all_vertices():
		var vd: Board.VertexData = v
		var p: Placement = state.placements.get("v:%d" % vd.id)
		if p != null and p.player_id == pid and p.building_id == "settlement":
			return vd.id
	return -1
