## RulesEngine 规则引擎单元测试。
extends GutTest


var _state: GameState
var _board: Board


func before_each():
	_state = TestHelper.make_standard_state()
	_board = _state.board


# ---- validate 基础校验 ----

func test_validate_null_action():
	var r := RulesEngine.validate(null, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_ARG)


func test_validate_null_state():
	var a := EndTurnAction.new(0)
	var r := RulesEngine.validate(a, null)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_ARG)


func test_validate_game_over():
	_state.is_game_over = true
	var a := EndTurnAction.new(0)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_GAME_OVER)


func test_validate_not_your_turn():
	_state.current_player_id = 1
	var a := EndTurnAction.new(0)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_NOT_YOUR_TURN)


# ---- apply 基础流程 ----

func test_apply_returns_state_and_events():
	# SETUP 阶段先放置定居点
	var verts := _board.all_vertices()
	var vid: int = verts[0].id
	var a := BuildAction.new(0, "settlement", vid)
	var result := RulesEngine.apply(a, _state)
	assert_true(result.result.ok)
	assert_eq(typeof(result.state), typeof(_state))
	assert_false(result.events.is_empty())


func test_apply_failed_validation_returns_original_state():
	var a := EndTurnAction.new(1)  # 错误玩家
	var result := RulesEngine.apply(a, _state)
	assert_false(result.result.ok)
	assert_eq(result.state, _state)


# ---- SETUP 阶段 ----

func test_setup_place_settlement():
	var verts := _board.all_vertices()
	var vid: int = verts[0].id
	var a := BuildAction.new(0, "settlement", vid)
	var r := RulesEngine.validate(a, _state)
	assert_true(r.ok, r.error_message)


func test_setup_place_settlement_then_road():
	var verts := _board.all_vertices()
	var vid: int = verts[0].id
	# 先放定居点
	var sa := BuildAction.new(0, "settlement", vid)
	var result := RulesEngine.apply(sa, _state)
	assert_true(result.result.ok)
	_state = result.state
	# 找一条连接的道路
	var edges := _board.vertex_edges(vid)
	assert_false(edges.is_empty())
	var eid: int = edges[0]
	var ra := BuildAction.new(0, "road", eid)
	var r := RulesEngine.validate(ra, _state)
	assert_true(r.ok, r.error_message)


func test_setup_road_before_settlement_fails():
	var edges := _board.all_edges()
	var eid: int = edges[0].id
	var a := BuildAction.new(0, "road", eid)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_STATE)


func test_setup_settlement_distance_rule():
	var verts := _board.all_vertices()
	var vid: int = verts[0].id
	# 放定居点
	var sa := BuildAction.new(0, "settlement", vid)
	_state = RulesEngine.apply(sa, _state).state
	# 放道路
	var edges := _board.vertex_edges(vid)
	var eid: int = edges[0]
	var ra := BuildAction.new(0, "road", eid)
	_state = RulesEngine.apply(ra, _state).state
	# 推进到玩家 1
	# 尝试在相邻顶点放定居点（违反距离规则）
	var adj := _board.adjacent_vertices(vid)
	if not adj.is_empty():
		var adj_vid: int = adj[0]
		var a := BuildAction.new(1, "settlement", adj_vid)
		var r := RulesEngine.validate(a, _state)
		# 应该失败（距离规则）
		assert_false(r.ok)
		assert_eq(r.error_code, Result.ERR_DISTANCE_RULE_VIOLATED)


func test_setup_full_round_progression():
	# 完整执行第一轮 SETUP（4 人各放定居点+道路）
	var state := _state
	for pid in range(4):
		assert_eq(state.current_player_id, pid)
		# 找一个可用顶点
		var vid := _find_free_vertex(state)
		var sa := BuildAction.new(pid, "settlement", vid)
		var r1 := RulesEngine.apply(sa, state)
		assert_true(r1.result.ok, "player %d settlement failed: %s" % [pid, r1.result.error_message])
		state = r1.state
		# 放道路
		var edges := _board.vertex_edges(vid)
		var eid: int = edges[0]
		var ra := BuildAction.new(pid, "road", eid)
		var r2 := RulesEngine.apply(ra, state)
		assert_true(r2.result.ok, "player %d road failed: %s" % [pid, r2.result.error_message])
		state = r2.state
	# 第一轮完成后应进入第二轮
	assert_eq(state.setup_round, 2)
	_state = state


func _find_free_vertex(state: GameState) -> int:
	for v in _board.all_vertices():
		var vd: Board.VertexData = v
		if not state.placements.has("v:%d" % vd.id):
			# 检查距离规则
			var adj := _board.adjacent_vertices(vd.id)
			var ok := true
			for adj_vid in adj:
				if state.placements.has("v:%d" % adj_vid):
					ok = false
					break
			if ok:
				return vd.id
	return -1


# ---- 掷骰 ----

func test_roll_dice_validation():
	_state.phase = GameState.Phase.ROLL
	var a := RollDiceAction.new(0)
	var r := RulesEngine.validate(a, _state)
	assert_true(r.ok, r.error_message)


func test_roll_dice_already_rolled():
	_state.phase = GameState.Phase.ROLL
	_state.has_rolled_this_turn = true
	var a := RollDiceAction.new(0)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_STATE)


func test_roll_dice_wrong_phase():
	_state.phase = GameState.Phase.ACTION
	var a := RollDiceAction.new(0)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_STATE)


func test_roll_dice_produces_events():
	_state.phase = GameState.Phase.ROLL
	var a := RollDiceAction.new(0)
	var result := RulesEngine.apply(a, _state)
	assert_true(result.result.ok)
	assert_false(result.events.is_empty())
	# 应有 DICE_ROLLED 事件
	var has_dice := false
	for e in result.events:
		if e.event_type == Event.TYPE_DICE_ROLLED:
			has_dice = true
			break
	assert_true(has_dice)
	assert_true(result.state.has_rolled_this_turn)


# ---- 建造 ----

func test_build_road_insufficient_resources():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var edges := _board.all_edges()
	var a := BuildAction.new(0, "road", edges[0].id)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INSUFFICIENT_RESOURCES)


func test_build_settlement_normal():
	# 先 SETUP 放置定居点和道路
	var state := _setup_one_player()
	var edges := _board.all_edges()
	# 找一条连接的道路
	var eid := _find_connected_edge(state, 0)
	var a := BuildAction.new(0, "road", eid)
	# 给资源
	var player := state.get_player(0)
	TestHelper.give_resources(player, 1, 1)
	var r := RulesEngine.validate(a, state)
	assert_true(r.ok, r.error_message)


func test_build_city_not_settlement():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var verts := _board.all_vertices()
	var a := BuildAction.new(0, "city", verts[0].id)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)


func test_build_dev_card():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	TestHelper.give_resources(player, 0, 0, 1, 1, 1)
	var a := BuildAction.new(0, "dev_card", -1)
	var r := RulesEngine.validate(a, _state)
	assert_true(r.ok, r.error_message)


func test_build_dev_card_deck_empty():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	_state.dev_card_deck.clear()
	var player := _state.get_player(0)
	TestHelper.give_resources(player, 0, 0, 1, 1, 1)
	var a := BuildAction.new(0, "dev_card", -1)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_STATE)


func _setup_one_player() -> GameState:
	var state := _state
	var vid := _find_free_vertex(state)
	var sa := BuildAction.new(0, "settlement", vid)
	state = RulesEngine.apply(sa, state).state
	var edges := _board.vertex_edges(vid)
	var eid: int = edges[0]
	var ra := BuildAction.new(0, "road", eid)
	state = RulesEngine.apply(ra, state).state
	# 跳过其余 SETUP，直接进入正常回合
	state.phase = GameState.Phase.ACTION
	state.has_rolled_this_turn = true
	state.setup_round = 0
	state.current_player_id = 0
	return state


func _find_connected_edge(state: GameState, pid: int) -> int:
	for v in _board.all_vertices():
		var vd: Board.VertexData = v
		var p: Placement = state.placements.get("v:%d" % vd.id)
		if p != null and p.player_id == pid:
			var edges := _board.vertex_edges(vd.id)
			for eid in edges:
				if not state.placements.has("e:%d" % eid):
					return eid
	return -1


# ---- 交易 ----

func test_bank_trade_validation():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	TestHelper.give_resources(player, 4)
	var give := ResourceSet.new()
	give.set_amount(ResType.WOOD, 4)
	var a := TradeAction.new_bank_trade(0, give, ResType.BRICK)
	var r := RulesEngine.validate(a, _state)
	assert_true(r.ok, r.error_message)


func test_bank_trade_wrong_ratio():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	TestHelper.give_resources(player, 3)
	var give := ResourceSet.new()
	give.set_amount(ResType.WOOD, 3)
	var a := TradeAction.new_bank_trade(0, give, ResType.BRICK)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_TRADE_REJECTED)


func test_bank_trade_mixed_resources():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	TestHelper.give_resources(player, 2, 2)
	var give := ResourceSet.new()
	give.set_amount(ResType.WOOD, 2)
	give.set_amount(ResType.BRICK, 2)
	var a := TradeAction.new_bank_trade(0, give, ResType.SHEEP)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)


func test_bank_trade_apply():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	TestHelper.give_resources(player, 4)
	var give := ResourceSet.new()
	give.set_amount(ResType.WOOD, 4)
	var a := TradeAction.new_bank_trade(0, give, ResType.BRICK)
	var result := RulesEngine.apply(a, _state)
	assert_true(result.result.ok)
	var new_player: PlayerState = result.state.get_player(0)
	assert_eq(new_player.resources.get_amount(ResType.WOOD), 0)
	assert_eq(new_player.resources.get_amount(ResType.BRICK), 1)


# ---- 发展卡 ----

func test_use_dev_card_not_held():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var a := UseDevCardAction.new(0, "knight")
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)


func test_use_dev_card_bought_this_turn():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	player.add_dev_card("knight", true)
	var a := UseDevCardAction.new(0, "knight")
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_CARD_NOT_USABLE)


func test_use_dev_card_from_previous_turn():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	player.add_dev_card("knight", false)
	var a := UseDevCardAction.new(0, "knight")
	var r := RulesEngine.validate(a, _state)
	assert_true(r.ok, r.error_message)


func test_use_dev_card_already_used():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	player.add_dev_card("knight", false)
	player.dev_card_used_this_turn = true
	var a := UseDevCardAction.new(0, "knight")
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_DEV_CARD_ALREADY_USED)


func test_use_victory_point_card():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	player.add_dev_card("victory_point", false)
	var a := UseDevCardAction.new(0, "victory_point")
	var r := RulesEngine.validate(a, _state)
	assert_true(r.ok, r.error_message)


func test_use_knight_card_triggers_robber():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	player.add_dev_card("knight", false)
	var a := UseDevCardAction.new(0, "knight")
	var result := RulesEngine.apply(a, _state)
	assert_true(result.result.ok)
	assert_true(result.state.robber_required)
	var new_player: PlayerState = result.state.get_player(0)
	assert_eq(new_player.played_knights, 1)


func test_use_year_of_plenty_card():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	player.add_dev_card("year_of_plenty", false)
	var a := UseDevCardAction.new(0, "year_of_plenty")
	a.year_of_plenty_res1 = ResType.WOOD
	a.year_of_plenty_res2 = ResType.BRICK
	var result := RulesEngine.apply(a, _state)
	assert_true(result.result.ok)
	var new_player: PlayerState = result.state.get_player(0)
	assert_eq(new_player.resources.get_amount(ResType.WOOD), 1)
	assert_eq(new_player.resources.get_amount(ResType.BRICK), 1)


func test_use_monopoly_card():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	player.add_dev_card("monopoly", false)
	# 给其他玩家一些木材
	_state.get_player(1).add_resource(ResType.WOOD, 3)
	_state.get_player(2).add_resource(ResType.WOOD, 2)
	var a := UseDevCardAction.new(0, "monopoly")
	a.monopoly_resource = ResType.WOOD
	var result := RulesEngine.apply(a, _state)
	assert_true(result.result.ok)
	var new_p0: PlayerState = result.state.get_player(0)
	assert_eq(new_p0.resources.get_amount(ResType.WOOD), 5)
	var new_p1: PlayerState = result.state.get_player(1)
	assert_eq(new_p1.resources.get_amount(ResType.WOOD), 0)


# ---- 强盗 ----

func test_move_robber_validation():
	_state.robber_required = true
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	# 找一个非沙漠六边形
	var target_hex := -1
	for h in _board.all_hexes():
		if h.id != _state.robber_hex_id and h.terrain_id != "desert":
			target_hex = h.id
			break
	var a := MoveRobberAction.new(0, target_hex, -1)
	var r := RulesEngine.validate(a, _state)
	assert_true(r.ok, r.error_message)


func test_move_robber_same_hex():
	_state.robber_required = true
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var a := MoveRobberAction.new(0, _state.robber_hex_id, -1)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_ROBBER_SAME_HEX)


func test_move_robber_not_required():
	_state.robber_required = false
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var a := MoveRobberAction.new(0, 0, -1)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_STATE)


func test_move_robber_steal():
	# 给玩家 1 一些资源
	_state.get_player(1).add_resource(ResType.WOOD, 3)
	# 先在 SETUP 放置定居点（玩家 1 回合）
	var state := _state
	state.current_player_id = 1
	var vid := _find_free_vertex(state)
	var sa := BuildAction.new(1, "settlement", vid)
	var setup_result := RulesEngine.apply(sa, state)
	assert_true(setup_result.result.ok, "setup settlement failed: " + setup_result.result.error_message)
	state = setup_result.state
	# 验证定居点已放置
	var placed: Placement = state.placements.get("v:%d" % vid)
	assert_not_null(placed, "settlement should be placed")
	assert_eq(placed.player_id, 1, "settlement should belong to player 1")
	# 设置为玩家 0 回合，需要移动强盗
	state.current_player_id = 0
	state.robber_required = true
	state.phase = GameState.Phase.ACTION
	state.has_rolled_this_turn = true
	state.setup_round = 0
	# 找该顶点相邻的六边形（vertex_hexes 返回 HexCoord）
	var hex_coords: Array = _board.vertex_hexes(vid)
	var target_hex := -1
	for coord in hex_coords:
		var hc: HexCoord = coord
		var hex_data: Board.HexData = _board.get_hex(hc)
		if hex_data.id != state.robber_hex_id and hex_data.terrain_id != "desert":
			target_hex = hex_data.id
			break
	assert_true(target_hex >= 0, "should find a valid target hex")
	if target_hex >= 0:
		var a := MoveRobberAction.new(0, target_hex, 1)
		var result := RulesEngine.apply(a, state)
		assert_true(result.result.ok, result.result.error_message)
		assert_false(result.state.robber_required)


# ---- 弃牌 ----

func test_discard_validation():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	# 8 张资源，需弃 4 张
	TestHelper.give_resources(player, 8)
	var ds := ResourceSet.new()
	ds.set_amount(ResType.WOOD, 4)
	var a := DiscardAction.new(0, ds)
	var r := RulesEngine.validate(a, _state)
	assert_true(r.ok, r.error_message)


func test_discard_wrong_amount():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	TestHelper.give_resources(player, 8)
	var ds := ResourceSet.new()
	ds.set_amount(ResType.WOOD, 3)  # 应弃 4
	var a := DiscardAction.new(0, ds)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)


func test_discard_not_needed():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	TestHelper.give_resources(player, 5)  # ≤7 不需弃
	var ds := ResourceSet.new()
	ds.set_amount(ResType.WOOD, 1)
	var a := DiscardAction.new(0, ds)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_STATE)


func test_discard_apply():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var player := _state.get_player(0)
	TestHelper.give_resources(player, 8)
	var ds := ResourceSet.new()
	ds.set_amount(ResType.WOOD, 4)
	var a := DiscardAction.new(0, ds)
	var result := RulesEngine.apply(a, _state)
	assert_true(result.result.ok)
	var new_player: PlayerState = result.state.get_player(0)
	assert_eq(new_player.resources.get_amount(ResType.WOOD), 4)


# ---- 结束回合 ----

func test_end_turn_validation():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var a := EndTurnAction.new(0)
	var r := RulesEngine.validate(a, _state)
	assert_true(r.ok, r.error_message)


func test_end_turn_without_roll():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = false
	var a := EndTurnAction.new(0)
	var r := RulesEngine.validate(a, _state)
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_INVALID_STATE)


func test_end_turn_advances_player():
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var a := EndTurnAction.new(0)
	var result := RulesEngine.apply(a, _state)
	assert_true(result.result.ok)
	assert_eq(result.state.current_player_id, 1)
	assert_false(result.state.has_rolled_this_turn)


# ---- 最长道路 ----

func test_calculate_longest_road_empty():
	var length := RulesEngine.calculate_longest_road(_state, 0)
	assert_eq(length, 0)


func test_calculate_longest_road_single():
	var state := _setup_one_player()
	# 建一条道路（SETUP 已建 1 条，共 2 条）
	var eid := _find_connected_edge(state, 0)
	var player := state.get_player(0)
	TestHelper.give_resources(player, 1, 1)
	var a := BuildAction.new(0, "road", eid)
	var result := RulesEngine.apply(a, state)
	var length := RulesEngine.calculate_longest_road(result.state, 0)
	assert_eq(length, 2)


# ---- 胜利条件 ----

func test_victory_check():
	var player := _state.get_player(0)
	# 直接给足够胜利点
	player.add_building("settlement")
	player.add_building("settlement")
	player.add_building("settlement")
	player.add_building("settlement")
	player.add_building("settlement")
	player.add_building("settlement")
	player.add_building("settlement")
	player.add_building("settlement")
	player.add_building("settlement")
	player.add_building("settlement")
	_state.phase = GameState.Phase.ACTION
	_state.has_rolled_this_turn = true
	var a := EndTurnAction.new(0)
	var result := RulesEngine.apply(a, _state)
	assert_true(result.state.is_game_over)
	assert_eq(result.state.winner.player_id, 0)
