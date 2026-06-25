## 规则引擎（Layer 1 核心）。
##
## 负责所有游戏规则的校验与执行。
## - [method validate]：纯校验，不修改状态，返回 [Result]。
## - [method apply]：执行动作，返回新状态 + 事件列表（不可变状态变更，见 ARCHITECTURE §3.3）。
##
## 规则严格对照 [GAME_RULES] 各章节实现。
class_name RulesEngine extends RefCounted

## 7 点强盗触发的骰子总和
const ROBBER_DICE_TOTAL: int = 7
## 最长道路成就的最低长度门槛
const LONGEST_ROAD_MIN: int = 5
## 最大军队成就的最低骑士数门槛
const LARGEST_ARMY_MIN: int = 3
## 银行交易比例（4:1）
const BANK_TRADE_RATIO: int = 4


# ---- 公共接口 ----

## 校验动作是否合法（不修改状态）。
## [param action] 待校验动作
## [param state] 当前游戏状态
## [return] [Result]，成功时 ok=true
static func validate(action: Action, state: GameState) -> Result:
	if action == null:
		return Result.failure(Result.ERR_INVALID_ARG, "action is null")
	if state == null:
		return Result.failure(Result.ERR_INVALID_ARG, "state is null")
	if state.is_game_over:
		return Result.failure(Result.ERR_GAME_OVER, "game is over")
	match action.action_type:
		Action.TYPE_ROLL_DICE:
			return _validate_roll_dice(action, state)
		Action.TYPE_BUILD:
			return _validate_build(action, state)
		Action.TYPE_TRADE:
			return _validate_trade(action, state)
		Action.TYPE_USE_DEV_CARD:
			return _validate_use_dev_card(action, state)
		Action.TYPE_MOVE_ROBBER:
			return _validate_move_robber(action, state)
		Action.TYPE_END_TURN:
			return _validate_end_turn(action, state)
		Action.TYPE_DISCARD:
			return _validate_discard(action, state)
		_:
			return Result.failure(Result.ERR_INVALID_ARG, "unknown action type: %d" % action.action_type)


## 执行动作，返回新状态与事件列表。
## [param action] 待执行动作
## [param state] 当前游戏状态
## [return] Dictionary，包含：
##   - "state": GameState（克隆后的新状态）
##   - "events": Array of Event
##   - "result": Result（失败时 ok=false）
static func apply(action: Action, state: GameState) -> Dictionary:
	var vr := validate(action, state)
	if not vr.ok:
		return {"state": state, "events": [], "result": vr}
	var new_state: GameState = state.clone()
	var events: Array = []
	match action.action_type:
		Action.TYPE_ROLL_DICE:
			events = _apply_roll_dice(action, new_state)
		Action.TYPE_BUILD:
			events = _apply_build(action, new_state)
		Action.TYPE_TRADE:
			events = _apply_trade(action, new_state)
		Action.TYPE_USE_DEV_CARD:
			events = _apply_use_dev_card(action, new_state)
		Action.TYPE_MOVE_ROBBER:
			events = _apply_move_robber(action, new_state)
		Action.TYPE_END_TURN:
			events = _apply_end_turn(action, new_state)
		Action.TYPE_DISCARD:
			events = _apply_discard(action, new_state)
	# 胜利检查
	var win_event := _check_victory_after_action(new_state, action)
	if win_event != null:
		events.append(win_event)
	return {"state": new_state, "events": events, "result": Result.success()}


# ---- 通用校验 ----

## 通用前置校验：游戏未结束 + 是当前玩家回合。
static func _validate_common(action: Action, state: GameState) -> Result:
	if state.is_game_over:
		return Result.failure(Result.ERR_GAME_OVER, "game is over")
	if action.player_id != state.current_player_id:
		return Result.failure(Result.ERR_NOT_YOUR_TURN, \
			"not your turn (action pid=%d, current=%d)" % [action.player_id, state.current_player_id])
	return Result.success()


# ---- 掷骰 ----

static func _validate_roll_dice(action: Action, state: GameState) -> Result:
	var r := _validate_common(action, state)
	if not r.ok:
		return r
	# SETUP 阶段不能掷骰
	if state.phase == GameState.Phase.SETUP:
		return Result.failure(Result.ERR_INVALID_PHASE, "cannot roll during SETUP")
	if state.phase == GameState.Phase.GAME_OVER:
		return Result.failure(Result.ERR_GAME_OVER, "game is over")
	if state.phase != GameState.Phase.ROLL:
		return Result.failure(Result.ERR_INVALID_STATE, "can only roll during ROLL phase")
	if state.has_rolled_this_turn:
		return Result.failure(Result.ERR_INVALID_STATE, "already rolled this turn")
	if state.robber_required:
		return Result.failure(Result.ERR_ROBBER_REQUIRED, "must move robber first")
	return Result.success()


static func _apply_roll_dice(action: Action, state: GameState) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var die1: int = rng.randi_range(1, 6)
	var die2: int = rng.randi_range(1, 6)
	var total: int = die1 + die2
	state.has_rolled_this_turn = true
	var events: Array = [Event.create_dice_rolled(action.player_id, die1, die2)]
	if total == ROBBER_DICE_TOTAL:
		# 7 点：触发强盗
		state.robber_required = true
		state.set_phase(GameState.Phase.ACTION)
		# 产出事件为空（7 点不产出）
	else:
		# 产出资源
		var produce_events := _produce_resources(state, total)
		events.append_array(produce_events)
		state.set_phase(GameState.Phase.ACTION)
	events.append(Event.create_phase_changed(action.player_id, GameState.Phase.ROLL, GameState.Phase.ACTION))
	return events


## 根据骰子点数产出资源。
static func _produce_resources(state: GameState, total: int) -> Array:
	var events: Array = []
	# 遍历所有六边形，数字牌匹配则产出
	for hex_data in state.board.all_hexes():
		if hex_data.number_token != total:
			continue
		if hex_data.id == state.robber_hex_id:
			continue  # 强盗压制
		if hex_data.terrain_id.is_empty():
			continue
		var terrain_def: TerrainDef = state.terrains.get(hex_data.terrain_id)
		if terrain_def == null:
			continue
		if terrain_def.resource == ResType.INVALID:
			continue  # 沙漠/海洋不产出
		# 遍历该六边形的所有顶点
		var vertex_ids: Array = _hex_vertex_ids(state.board, hex_data.id)
		for vid in vertex_ids:
			var placement: Placement = state.placements.get(_vertex_key(vid))
			if placement == null:
				continue
			if placement.building_id != "settlement" and placement.building_id != "city":
				continue
			var player: PlayerState = state.get_player(placement.player_id)
			if player == null:
				continue
			var amount: int = 1
			if placement.building_id == "city":
				amount = 2
			# 从银行取资源
			if state.bank_withdraw(terrain_def.resource, amount):
				player.add_resource(terrain_def.resource, amount)
				events.append(Event.create_resource_produced(placement.player_id, terrain_def.resource, amount))
	return events


## 获取六边形的所有顶点 ID。
static func _hex_vertex_ids(board: Board, hex_id: int) -> Array:
	var hex_data: Board.HexData = board.get_hex_by_id(hex_id)
	if hex_data == null:
		return []
	var result: Array = []
	var coord: HexCoord = hex_data.coord
	# 遍历所有顶点，找出属于该六边形的
	for v in board.all_vertices():
		var vdata: Board.VertexData = v
		var hexes: Array = board.vertex_hexes(vdata.id)
		for h in hexes:
			if h.equals(coord):
				result.append(vdata.id)
				break
	return result


# ---- 建造 ----

static func _validate_build(action: Action, state: GameState) -> Result:
	var r := _validate_common(action, state)
	if not r.ok:
		return r
	var ba: BuildAction = action
	if ba.building_id.is_empty():
		return Result.failure(Result.ERR_INVALID_ARG, "building_id is empty")
	var bdef: BuildingDef = state.buildings.get(ba.building_id)
	if bdef == null:
		return Result.failure(Result.ERR_NOT_FOUND, "building not found: %s" % ba.building_id)
	var player: PlayerState = state.get_player(ba.player_id)
	if player == null:
		return Result.failure(Result.ERR_NOT_FOUND, "player not found: %d" % ba.player_id)
	# SETUP 阶段特殊处理
	if state.phase == GameState.Phase.SETUP:
		return _validate_build_setup(ba, state, player, bdef)
	# 非 SETUP 阶段：必须在 ACTION 阶段且已掷骰
	if state.phase != GameState.Phase.ACTION:
		return Result.failure(Result.ERR_INVALID_PHASE, "can only build during ACTION phase")
	if not state.has_rolled_this_turn:
		return Result.failure(Result.ERR_INVALID_STATE, "must roll dice first")
	if state.robber_required:
		return Result.failure(Result.ERR_ROBBER_REQUIRED, "must move robber first")
	# 发展卡购买（无位置）
	if ba.building_id == "dev_card":
		return _validate_buy_dev_card(ba, state, player)
	# 建筑数量上限
	if bdef.max_per_player >= 0 and player.count_building(ba.building_id) >= bdef.max_per_player:
		return Result.failure(Result.ERR_INVALID_STATE, "max %s reached" % ba.building_id)
	# 资源校验
	if not player.can_afford(bdef.cost):
		return Result.failure(Result.ERR_INSUFFICIENT_RESOURCES, "cannot afford %s" % ba.building_id)
	# 位置校验
	match ba.building_id:
		"road":
			return _validate_build_road(ba, state, player)
		"settlement":
			return _validate_build_settlement(ba, state, player)
		"city":
			return _validate_build_city(ba, state, player)
		_:
			return Result.failure(Result.ERR_INVALID_ARG, "unknown building: %s" % ba.building_id)


## SETUP 阶段建造校验。
static func _validate_build_setup(ba: BuildAction, state: GameState, player: PlayerState, bdef: BuildingDef) -> Result:
	# SETUP 阶段只允许建定居点和道路，免费
	if ba.building_id == "settlement":
		if state.setup_settlement_placed:
			return Result.failure(Result.ERR_INVALID_STATE, "settlement already placed this setup step")
		return _validate_build_settlement_setup(ba, state, player)
	elif ba.building_id == "road":
		if not state.setup_settlement_placed:
			return Result.failure(Result.ERR_INVALID_STATE, "must place settlement before road in setup")
		return _validate_build_road_setup(ba, state, player)
	else:
		return Result.failure(Result.ERR_INVALID_PHASE, "can only build settlement/road during SETUP")


## SETUP 阶段定居点校验。
static func _validate_build_settlement_setup(ba: BuildAction, state: GameState, player: PlayerState) -> Result:
	if not _is_valid_vertex(state, ba.position_id):
		return Result.failure(Result.ERR_INVALID_POSITION, "invalid vertex: %d" % ba.position_id)
	if _is_vertex_occupied(state, ba.position_id):
		return Result.failure(Result.ERR_POSITION_OCCUPIED, "vertex occupied: %d" % ba.position_id)
	if not _satisfies_distance_rule(state, ba.position_id):
		return Result.failure(Result.ERR_DISTANCE_RULE_VIOLATED, "distance rule violated at vertex %d" % ba.position_id)
	return Result.success()


## SETUP 阶段道路校验。
static func _validate_build_road_setup(ba: BuildAction, state: GameState, player: PlayerState) -> Result:
	if not _is_valid_edge(state, ba.position_id):
		return Result.failure(Result.ERR_INVALID_POSITION, "invalid edge: %d" % ba.position_id)
	if _is_edge_occupied(state, ba.position_id):
		return Result.failure(Result.ERR_POSITION_OCCUPIED, "edge occupied: %d" % ba.position_id)
	# 必须连接到刚放置的定居点
	if state.setup_last_settlement_vertex < 0:
		return Result.failure(Result.ERR_NOT_CONNECTED, "no settlement placed yet")
	var edge_verts: Array = state.board.edge_vertices(ba.position_id)
	if not edge_verts.has(state.setup_last_settlement_vertex):
		return Result.failure(Result.ERR_NOT_CONNECTED, "road not connected to setup settlement")
	return Result.success()


## 普通道路建造校验。
static func _validate_build_road(ba: BuildAction, state: GameState, player: PlayerState) -> Result:
	if not _is_valid_edge(state, ba.position_id):
		return Result.failure(Result.ERR_INVALID_POSITION, "invalid edge: %d" % ba.position_id)
	if _is_edge_occupied(state, ba.position_id):
		return Result.failure(Result.ERR_POSITION_OCCUPIED, "edge occupied: %d" % ba.position_id)
	if not _is_road_connected(state, ba.position_id, ba.player_id):
		return Result.failure(Result.ERR_NOT_CONNECTED, "road not connected to player network")
	return Result.success()


## 普通定居点建造校验。
static func _validate_build_settlement(ba: BuildAction, state: GameState, player: PlayerState) -> Result:
	if not _is_valid_vertex(state, ba.position_id):
		return Result.failure(Result.ERR_INVALID_POSITION, "invalid vertex: %d" % ba.position_id)
	if _is_vertex_occupied(state, ba.position_id):
		return Result.failure(Result.ERR_POSITION_OCCUPIED, "vertex occupied: %d" % ba.position_id)
	if not _satisfies_distance_rule(state, ba.position_id):
		return Result.failure(Result.ERR_DISTANCE_RULE_VIOLATED, "distance rule violated at vertex %d" % ba.position_id)
	if not _is_settlement_connected(state, ba.position_id, ba.player_id):
		return Result.failure(Result.ERR_NOT_CONNECTED, "settlement not connected to road network")
	return Result.success()


## 城市升级校验。
static func _validate_build_city(ba: BuildAction, state: GameState, player: PlayerState) -> Result:
	if not _is_valid_vertex(state, ba.position_id):
		return Result.failure(Result.ERR_INVALID_POSITION, "invalid vertex: %d" % ba.position_id)
	var placement: Placement = state.placements.get(_vertex_key(ba.position_id))
	if placement == null:
		return Result.failure(Result.ERR_POSITION_OCCUPIED, "no building at vertex %d" % ba.position_id)
	if placement.building_id != "settlement":
		return Result.failure(Result.ERR_INVALID_STATE, "can only upgrade settlement to city")
	if placement.player_id != ba.player_id:
		return Result.failure(Result.ERR_NOT_OWNED, "vertex not owned by player")
	return Result.success()


## 发展卡购买校验。
static func _validate_buy_dev_card(ba: BuildAction, state: GameState, player: PlayerState) -> Result:
	var bdef: BuildingDef = state.buildings.get("dev_card")
	if not player.can_afford(bdef.cost):
		return Result.failure(Result.ERR_INSUFFICIENT_RESOURCES, "cannot afford dev_card")
	if state.dev_card_deck.is_empty():
		return Result.failure(Result.ERR_INVALID_STATE, "dev card deck is empty")
	return Result.success()


static func _apply_build(action: Action, state: GameState) -> Array:
	var ba: BuildAction = action
	var player: PlayerState = state.get_player(ba.player_id)
	var events: Array = []
	if state.phase == GameState.Phase.SETUP:
		return _apply_build_setup(ba, state, player)
	# 发展卡
	if ba.building_id == "dev_card":
		var bdef: BuildingDef = state.buildings.get("dev_card")
		player.pay(bdef.cost)
		state.bank_deposit(ResType.SHEEP, 1)
		state.bank_deposit(ResType.WHEAT, 1)
		state.bank_deposit(ResType.ORE, 1)
		var card_id: String = state.draw_dev_card()
		player.add_dev_card(card_id, true)
		events.append(Event.create_building_built(ba.player_id, "dev_card", -1))
		return events
	# 普通建筑
	var bdef: BuildingDef = state.buildings.get(ba.building_id)
	player.pay(bdef.cost)
	# 资源回到银行
	for t in ResType.all():
		var amt: int = bdef.cost.get_amount(t)
		if amt > 0:
			state.bank_deposit(t, amt)
	match ba.building_id:
		"road":
			player.add_building("road")
			state.placements[_edge_key(ba.position_id)] = Placement.new(ba.player_id, "road", ba.position_id)
			events.append(Event.create_road_built(ba.player_id, ba.position_id))
			# 更新最长道路
			_update_longest_road(state)
		"settlement":
			player.add_building("settlement")
			state.placements[_vertex_key(ba.position_id)] = Placement.new(ba.player_id, "settlement", ba.position_id)
			events.append(Event.create_building_built(ba.player_id, "settlement", ba.position_id))
			_update_longest_road(state)
		"city":
			player.upgrade_settlement_to_city()
			state.placements[_vertex_key(ba.position_id)] = Placement.new(ba.player_id, "city", ba.position_id)
			events.append(Event.create_building_built(ba.player_id, "city", ba.position_id))
	return events


## SETUP 阶段建造执行。
static func _apply_build_setup(ba: BuildAction, state: GameState, player: PlayerState) -> Array:
	var events: Array = []
	if ba.building_id == "settlement":
		player.add_building("settlement")
		state.placements[_vertex_key(ba.position_id)] = Placement.new(ba.player_id, "settlement", ba.position_id)
		state.setup_last_settlement_vertex = ba.position_id
		state.setup_settlement_placed = true
		events.append(Event.create_building_built(ba.player_id, "settlement", ba.position_id))
		# 第二轮放置后给初始资源
		if state.setup_round == 2:
			var vertex_hexes: Array = state.board.vertex_hexes(ba.position_id)
			for coord in vertex_hexes:
				var hex_data: Board.HexData = state.board.get_hex(coord)
				if hex_data == null or hex_data.terrain_id.is_empty():
					continue
				var tdef: TerrainDef = state.terrains.get(hex_data.terrain_id)
				if tdef == null or tdef.resource == ResType.INVALID:
					continue
				if state.bank_withdraw(tdef.resource, 1):
					player.add_resource(tdef.resource, 1)
					events.append(Event.create_resource_produced(ba.player_id, tdef.resource, 1))
	elif ba.building_id == "road":
		player.add_building("road")
		state.placements[_edge_key(ba.position_id)] = Placement.new(ba.player_id, "road", ba.position_id)
		events.append(Event.create_road_built(ba.player_id, ba.position_id))
		# 推进 SETUP 流程
		_advance_setup(state)
	return events


## 推进 SETUP 阶段流程。
static func _advance_setup(state: GameState) -> void:
	state.setup_settlement_placed = false
	state.setup_last_settlement_vertex = -1
	if state.setup_round == 1:
		# 第一轮：正向推进
		if state.current_player_id < state.player_count() - 1:
			state.current_player_id += 1
		else:
			# 进入第二轮
			state.setup_round = 2
			state.setup_direction = -1
			# 第二轮从最后一位开始反向，但当前已经是最后一位
	else:
		# 第二轮：反向推进
		if state.current_player_id > 0:
			state.current_player_id -= 1
		else:
			# SETUP 完成，进入正常回合
			state.setup_round = 0
			state.setup_direction = 0
			state.current_player_id = 0
			state.set_phase(GameState.Phase.ROLL)
			state.round_number = 1


# ---- 交易 ----

static func _validate_trade(action: Action, state: GameState) -> Result:
	var r := _validate_common(action, state)
	if not r.ok:
		return r
	if state.phase != GameState.Phase.ACTION:
		return Result.failure(Result.ERR_INVALID_PHASE, "can only trade during ACTION phase")
	if not state.has_rolled_this_turn:
		return Result.failure(Result.ERR_INVALID_STATE, "must roll dice first")
	if state.robber_required:
		return Result.failure(Result.ERR_ROBBER_REQUIRED, "must move robber first")
	var ta: TradeAction = action
	var player: PlayerState = state.get_player(ta.player_id)
	if player == null:
		return Result.failure(Result.ERR_NOT_FOUND, "player not found")
	if not player.resources.covers(ta.give):
		return Result.failure(Result.ERR_INSUFFICIENT_RESOURCES, "insufficient resources to trade")
	match ta.trade_type:
		TradeAction.TRADE_BANK:
			return _validate_bank_trade(ta, state, player)
		TradeAction.TRADE_PORT:
			return _validate_port_trade(ta, state, player)
		TradeAction.TRADE_PLAYER:
			return _validate_player_trade(ta, state, player)
		_:
			return Result.failure(Result.ERR_INVALID_ARG, "unknown trade type")


static func _validate_bank_trade(ta: TradeAction, state: GameState, player: PlayerState) -> Result:
	# 银行 4:1：必须给出 4 张相同资源
	if ta.give.total() != BANK_TRADE_RATIO:
		return Result.failure(Result.ERR_TRADE_REJECTED, "bank trade requires 4 of same resource")
	# 检查是否为单一资源
	var res_type: int = -1
	for t in ResType.all():
		if ta.give.get_amount(t) > 0:
			if res_type == -1:
				res_type = t
			elif res_type != t:
				return Result.failure(Result.ERR_TRADE_REJECTED, "bank trade requires single resource type")
	if res_type == -1:
		return Result.failure(Result.ERR_TRADE_REJECTED, "no resource given")
	if ta.receive_type == ResType.INVALID:
		return Result.failure(Result.ERR_INVALID_ARG, "receive_type not set")
	# 银行必须有该资源
	if state.bank.get_amount(ta.receive_type) <= 0:
		return Result.failure(Result.ERR_BANK_EMPTY, "bank has no such resource")
	return Result.success()


static func _validate_port_trade(ta: TradeAction, state: GameState, player: PlayerState) -> Result:
	if ta.port_vertex_id < 0:
		return Result.failure(Result.ERR_INVALID_ARG, "port_vertex_id not set")
	# 检查玩家是否在港口有定居点/城市
	var placement: Placement = state.placements.get(_vertex_key(ta.port_vertex_id))
	if placement == null:
		return Result.failure(Result.ERR_PORT_NOT_OWNED, "no building at port vertex")
	if placement.player_id != ta.player_id:
		return Result.failure(Result.ERR_PORT_NOT_OWNED, "port not owned by player")
	if placement.building_id != "settlement" and placement.building_id != "city":
		return Result.failure(Result.ERR_PORT_NOT_OWNED, "port vertex has no settlement/city")
	var port_id: String = state.board.get_port(ta.port_vertex_id)
	if port_id.is_empty():
		return Result.failure(Result.ERR_PORT_NOT_OWNED, "no port at vertex %d" % ta.port_vertex_id)
	var pdef: PortDef = state.ports.get(port_id)
	if pdef == null:
		return Result.failure(Result.ERR_NOT_FOUND, "port def not found: %s" % port_id)
	# 检查给出资源数量与类型
	if ta.give.total() != pdef.give_count:
		return Result.failure(Result.ERR_TRADE_REJECTED, "port requires %d resources" % pdef.give_count)
	# 专项港口必须给出对应资源
	if pdef.is_specialized:
		if ta.give.get_amount(pdef.resource) != pdef.give_count:
			return Result.failure(Result.ERR_TRADE_REJECTED, "specialized port requires %s" % ResType.name_of(pdef.resource))
	else:
		# 通用港口：单一资源
		var res_type: int = -1
		for t in ResType.all():
			if ta.give.get_amount(t) > 0:
				if res_type == -1:
					res_type = t
				elif res_type != t:
					return Result.failure(Result.ERR_TRADE_REJECTED, "port trade requires single resource type")
	if ta.receive_type == ResType.INVALID:
		return Result.failure(Result.ERR_INVALID_ARG, "receive_type not set")
	if state.bank.get_amount(ta.receive_type) <= 0:
		return Result.failure(Result.ERR_BANK_EMPTY, "bank has no such resource")
	return Result.success()


static func _validate_player_trade(ta: TradeAction, state: GameState, player: PlayerState) -> Result:
	if ta.target_player_id < 0 or ta.target_player_id == ta.player_id:
		return Result.failure(Result.ERR_INVALID_ARG, "invalid target player")
	var target: PlayerState = state.get_player(ta.target_player_id)
	if target == null:
		return Result.failure(Result.ERR_NOT_FOUND, "target player not found")
	if not target.resources.covers(ta.receive_set):
		return Result.failure(Result.ERR_INSUFFICIENT_RESOURCES, "target cannot fulfill trade")
	return Result.success()


static func _apply_trade(action: Action, state: GameState) -> Array:
	var ta: TradeAction = action
	var player: PlayerState = state.get_player(ta.player_id)
	var events: Array = []
	match ta.trade_type:
		TradeAction.TRADE_BANK:
			player.pay(ta.give)
			# 资源回到银行
			for t in ResType.all():
				state.bank_deposit(t, ta.give.get_amount(t))
			# 从银行取
			state.bank_withdraw(ta.receive_type, 1)
			player.add_resource(ta.receive_type, 1)
			events.append(Event.create_trade_completed(ta.player_id, "bank", ta.give))
		TradeAction.TRADE_PORT:
			player.pay(ta.give)
			for t in ResType.all():
				state.bank_deposit(t, ta.give.get_amount(t))
			state.bank_withdraw(ta.receive_type, 1)
			player.add_resource(ta.receive_type, 1)
			events.append(Event.create_trade_completed(ta.player_id, "port", ta.give))
		TradeAction.TRADE_PLAYER:
			var target: PlayerState = state.get_player(ta.target_player_id)
			player.pay(ta.give)
			target.resources.add_set(ta.give)
			target.pay(ta.receive_set)
			player.resources.add_set(ta.receive_set)
			events.append(Event.create_trade_completed(ta.player_id, "player", ta.give))
	return events


# ---- 发展卡 ----

static func _validate_use_dev_card(action: Action, state: GameState) -> Result:
	var r := _validate_common(action, state)
	if not r.ok:
		return r
	if state.phase != GameState.Phase.ACTION and state.phase != GameState.Phase.ROLL:
		return Result.failure(Result.ERR_INVALID_PHASE, "cannot use dev card in current phase")
	if state.robber_required and action.action_type != Action.TYPE_MOVE_ROBBER:
		# 使用骑士卡是允许的（会触发强盗移动）
		var uda: UseDevCardAction = action
		if uda.card_id != "knight":
			return Result.failure(Result.ERR_ROBBER_REQUIRED, "must move robber first")
	var player: PlayerState = state.get_player(action.player_id)
	if player == null:
		return Result.failure(Result.ERR_NOT_FOUND, "player not found")
	if player.dev_card_used_this_turn:
		return Result.failure(Result.ERR_DEV_CARD_ALREADY_USED, "already used dev card this turn")
	var uda: UseDevCardAction = action
	if not player.has_usable_dev_card(uda.card_id):
		return Result.failure(Result.ERR_CARD_NOT_USABLE, "card not usable (bought this turn or not held)")
	# 各卡种特殊校验
	match uda.card_id:
		"knight":
			# 骑士卡：允许在任何时候使用（需移动强盗）
			return Result.success()
		"victory_point":
			# 胜利点卡：可在达到胜利时翻开
			return Result.success()
		"road_building":
			# 道路建设：必须有可建道路位置
			return _validate_road_building_card(uda, state, player)
		"year_of_plenty":
			# 发明：银行必须有资源
			return _validate_year_of_plenty_card(uda, state)
		"monopoly":
			# 垄断：资源类型必须有效
			if uda.monopoly_resource == ResType.INVALID:
				return Result.failure(Result.ERR_INVALID_ARG, "monopoly resource not set")
			return Result.success()
		_:
			return Result.failure(Result.ERR_INVALID_ARG, "unknown card: %s" % uda.card_id)


static func _validate_road_building_card(uda: UseDevCardAction, state: GameState, player: PlayerState) -> Result:
	# 检查两条道路是否可建
	if uda.road_building_edge1 < 0:
		return Result.failure(Result.ERR_INVALID_ARG, "road_building_edge1 not set")
	# 简化校验：只检查边是否有效且未被占用
	if not _is_valid_edge(state, uda.road_building_edge1):
		return Result.failure(Result.ERR_INVALID_POSITION, "invalid edge1")
	if _is_edge_occupied(state, uda.road_building_edge1):
		return Result.failure(Result.ERR_POSITION_OCCUPIED, "edge1 occupied")
	if uda.road_building_edge2 >= 0:
		if not _is_valid_edge(state, uda.road_building_edge2):
			return Result.failure(Result.ERR_INVALID_POSITION, "invalid edge2")
		if _is_edge_occupied(state, uda.road_building_edge2):
			return Result.failure(Result.ERR_POSITION_OCCUPIED, "edge2 occupied")
	return Result.success()


static func _validate_year_of_plenty_card(uda: UseDevCardAction, state: GameState) -> Result:
	if uda.year_of_plenty_res1 == ResType.INVALID:
		return Result.failure(Result.ERR_INVALID_ARG, "year_of_plenty_res1 not set")
	# 检查银行是否有资源
	if state.bank.get_amount(uda.year_of_plenty_res1) <= 0:
		return Result.failure(Result.ERR_BANK_EMPTY, "bank has no resource 1")
	if uda.year_of_plenty_res2 != ResType.INVALID:
		if state.bank.get_amount(uda.year_of_plenty_res2) <= 0:
			return Result.failure(Result.ERR_BANK_EMPTY, "bank has no resource 2")
	return Result.success()


static func _apply_use_dev_card(action: Action, state: GameState) -> Array:
	var uda: UseDevCardAction = action
	var player: PlayerState = state.get_player(uda.player_id)
	var events: Array = []
	player.use_dev_card(uda.card_id)
	events.append(Event.create_dev_card_used(uda.player_id, uda.card_id))
	match uda.card_id:
		"knight":
			# 骑士卡：需要移动强盗（设置 robber_required）
			state.robber_required = true
			_update_largest_army(state)
		"victory_point":
			# 胜利点卡：已通过 use_dev_card 增加 hidden_victory_points
			pass
		"road_building":
			# 免费建 2 条道路
			if _is_valid_edge(state, uda.road_building_edge1) and not _is_edge_occupied(state, uda.road_building_edge1):
				player.add_building("road")
				state.placements[_edge_key(uda.road_building_edge1)] = Placement.new(uda.player_id, "road", uda.road_building_edge1)
				events.append(Event.create_road_built(uda.player_id, uda.road_building_edge1))
			if uda.road_building_edge2 >= 0 and _is_valid_edge(state, uda.road_building_edge2) and not _is_edge_occupied(state, uda.road_building_edge2):
				player.add_building("road")
				state.placements[_edge_key(uda.road_building_edge2)] = Placement.new(uda.player_id, "road", uda.road_building_edge2)
				events.append(Event.create_road_built(uda.player_id, uda.road_building_edge2))
			_update_longest_road(state)
		"year_of_plenty":
			# 从银行取 2 张资源
			if state.bank_withdraw(uda.year_of_plenty_res1, 1):
				player.add_resource(uda.year_of_plenty_res1, 1)
			if uda.year_of_plenty_res2 != ResType.INVALID:
				if state.bank_withdraw(uda.year_of_plenty_res2, 1):
					player.add_resource(uda.year_of_plenty_res2, 1)
		"monopoly":
			# 垄断：所有其他玩家交出该资源
			var total_stolen: int = 0
			for p in state.get_all_players():
				if p.player_id == uda.player_id:
					continue
				var amt: int = p.resources.get_amount(uda.monopoly_resource)
				if amt > 0:
					p.remove_resource(uda.monopoly_resource, amt)
					total_stolen += amt
			if total_stolen > 0:
				player.add_resource(uda.monopoly_resource, total_stolen)
	return events


# ---- 强盗 ----

static func _validate_move_robber(action: Action, state: GameState) -> Result:
	var r := _validate_common(action, state)
	if not r.ok:
		return r
	if not state.robber_required:
		return Result.failure(Result.ERR_INVALID_STATE, "robber move not required")
	var mra: MoveRobberAction = action
	if mra.target_hex_id < 0:
		return Result.failure(Result.ERR_INVALID_ARG, "target_hex_id not set")
	var hex_data: Board.HexData = state.board.get_hex_by_id(mra.target_hex_id)
	if hex_data == null:
		return Result.failure(Result.ERR_INVALID_POSITION, "hex not found: %d" % mra.target_hex_id)
	if mra.target_hex_id == state.robber_hex_id:
		return Result.failure(Result.ERR_ROBBER_SAME_HEX, "robber must move to different hex")
	# 沙漠不能放强盗（按规则：非沙漠）
	var tdef: TerrainDef = state.terrains.get(hex_data.terrain_id)
	if tdef != null and hex_data.terrain_id == "desert":
		return Result.failure(Result.ERR_INVALID_POSITION, "robber cannot stay on desert")
	# 如果指定了偷取目标，校验目标合法性
	if mra.target_player_id >= 0:
		var target: PlayerState = state.get_player(mra.target_player_id)
		if target == null:
			return Result.failure(Result.ERR_NOT_FOUND, "target player not found")
		# 目标必须在新强盗位置相邻的顶点有建筑
		if not _player_has_building_near_hex(state, mra.target_player_id, mra.target_hex_id):
			return Result.failure(Result.ERR_INVALID_STATE, "target has no building near robber")
	return Result.success()


static func _apply_move_robber(action: Action, state: GameState) -> Array:
	var mra: MoveRobberAction = action
	var events: Array = []
	var old_hex: int = state.robber_hex_id
	state.set_robber_position(mra.target_hex_id)
	state.robber_required = false
	events.append(Event.create_robber_moved(mra.player_id, old_hex, mra.target_hex_id))
	# 偷取资源
	if mra.target_player_id >= 0:
		var target: PlayerState = state.get_player(mra.target_player_id)
		var thief: PlayerState = state.get_player(mra.player_id)
		if target != null and thief != null and target.hand_size() > 0:
			# 随机偷一张
			var rng := RandomNumberGenerator.new()
			rng.randomize()
			# 收集所有有数量的资源类型
			var available: Array = []
			for t in ResType.all():
				if target.resources.get_amount(t) > 0:
					available.append(t)
			if not available.is_empty():
				var stolen_type: int = available[rng.randi_range(0, available.size() - 1)]
				target.remove_resource(stolen_type, 1)
				thief.add_resource(stolen_type, 1)
				events.append(Event.create_resource_stolen(mra.player_id, mra.target_player_id, stolen_type))
	return events


# ---- 弃牌 ----

static func _validate_discard(action: Action, state: GameState) -> Result:
	# 弃牌可以由任何手牌>7的玩家执行（不限于当前玩家）
	if state.is_game_over:
		return Result.failure(Result.ERR_GAME_OVER, "game is over")
	var da: DiscardAction = action
	var player: PlayerState = state.get_player(da.player_id)
	if player == null:
		return Result.failure(Result.ERR_NOT_FOUND, "player not found")
	var need: int = player.discard_half_count()
	if need == 0:
		return Result.failure(Result.ERR_INVALID_STATE, "player does not need to discard")
	if da.discard_set.total() != need:
		return Result.failure(Result.ERR_INVALID_ARG, "must discard exactly %d resources" % need)
	if not player.resources.covers(da.discard_set):
		return Result.failure(Result.ERR_INSUFFICIENT_RESOURCES, "not enough resources to discard")
	return Result.success()


static func _apply_discard(action: Action, state: GameState) -> Array:
	var da: DiscardAction = action
	var player: PlayerState = state.get_player(da.player_id)
	var events: Array = []
	player.discard(da.discard_set)
	# 弃掉的资源回到银行
	for t in ResType.all():
		state.bank_deposit(t, da.discard_set.get_amount(t))
	events.append(Event.create_cards_discarded(da.player_id, da.discard_set))
	return events


# ---- 结束回合 ----

static func _validate_end_turn(action: Action, state: GameState) -> Result:
	var r := _validate_common(action, state)
	if not r.ok:
		return r
	if state.phase == GameState.Phase.SETUP:
		return Result.failure(Result.ERR_INVALID_PHASE, "cannot end turn during SETUP")
	if state.robber_required:
		return Result.failure(Result.ERR_ROBBER_REQUIRED, "must move robber first")
	if not state.has_rolled_this_turn:
		return Result.failure(Result.ERR_INVALID_STATE, "must roll dice before ending turn")
	return Result.success()


static func _apply_end_turn(action: Action, state: GameState) -> Array:
	var events: Array = [Event.create_turn_ended(action.player_id)]
	state.advance_turn()
	state.has_rolled_this_turn = false
	state.robber_required = false
	state.set_phase(GameState.Phase.ROLL)
	events.append(Event.create_turn_started(state.current_player_id, state.round_number))
	return events


# ---- 成就与胜利 ----

## 更新最长道路成就。
static func _update_longest_road(state: GameState) -> void:
	var best_player: PlayerState = null
	var best_length: int = 0
	for p in state.get_all_players():
		var length: int = calculate_longest_road(state, p.player_id)
		if length >= LONGEST_ROAD_MIN and length > best_length:
			best_length = length
			best_player = p
	# 如果有当前持有者，检查是否仍持有
	var current_holder: PlayerState = null
	for p in state.get_all_players():
		if p.has_longest_road:
			current_holder = p
			break
	if best_player == null:
		# 无人达到门槛，保持现状（如果有持有者则保留）
		return
	if current_holder == null:
		# 无人持有，授予新持有者
		best_player.has_longest_road = true
	elif current_holder.player_id != best_player.player_id:
		# 转移
		current_holder.has_longest_road = false
		best_player.has_longest_road = true


## 更新最大军队成就。
static func _update_largest_army(state: GameState) -> void:
	var best_player: PlayerState = null
	var best_count: int = 0
	for p in state.get_all_players():
		if p.played_knights >= LARGEST_ARMY_MIN and p.played_knights > best_count:
			best_count = p.played_knights
			best_player = p
	var current_holder: PlayerState = null
	for p in state.get_all_players():
		if p.has_largest_army:
			current_holder = p
			break
	if best_player == null:
		return
	if current_holder == null:
		best_player.has_largest_army = true
	elif current_holder.player_id != best_player.player_id:
		current_holder.has_largest_army = false
		best_player.has_largest_army = true


## 计算玩家的最长道路长度（DFS）。
## 断链规则：对手定居点/城市插入则断链。
static func calculate_longest_road(state: GameState, player_id: int) -> int:
	# 收集该玩家所有道路
	var road_edges: Array = []
	for key in state.placements.keys():
		var p: Placement = state.placements[key]
		if p.player_id != player_id:
			continue
		if p.building_id != "road":
			continue
		road_edges.append(p.position_id)
	if road_edges.is_empty():
		return 0
	# 构建边到顶点的映射
	var max_length: int = 0
	# 从每条边开始 DFS
	for start_edge in road_edges:
		var visited: Dictionary = {}
		var length: int = _dfs_road_length(state, start_edge, player_id, visited)
		max_length = maxi(max_length, length)
	return max_length


## DFS 计算从指定边延伸的道路长度。
static func _dfs_road_length(state: GameState, edge_id: int, player_id: int, visited: Dictionary) -> int:
	if visited.has(edge_id):
		return 0
	visited[edge_id] = true
	var edge_verts: Array = state.board.edge_vertices(edge_id)
	var max_extend: int = 0
	for vid in edge_verts:
		# 检查顶点是否被对手定居点/城市占据（断链）
		var placement: Placement = state.placements.get(_vertex_key(vid))
		if placement != null and placement.player_id != player_id:
			continue  # 对手建筑，断链
		# 从该顶点延伸到其他边
		var adj_edges: Array = state.board.vertex_edges(vid)
		for next_edge in adj_edges:
			if next_edge == edge_id:
				continue
			if visited.has(next_edge):
				continue
			var next_p: Placement = state.placements.get(_edge_key(next_edge))
			if next_p == null or next_p.player_id != player_id:
				continue
			if next_p.building_id != "road":
				continue
			var ext: int = _dfs_road_length(state, next_edge, player_id, visited)
			max_extend = maxi(max_extend, ext)
	visited.erase(edge_id)
	return 1 + max_extend


## 动作执行后检查胜利条件。
static func _check_victory_after_action(state: GameState, action: Action) -> Event:
	var winner: PlayerState = state.check_winner()
	if winner != null and not state.is_game_over:
		state.end_game(winner)
		return Event.create_game_over(winner.player_id)
	return null


# ---- 辅助方法 ----

## 顶点放置键。
static func _vertex_key(vertex_id: int) -> String:
	return "v:%d" % vertex_id


## 边放置键。
static func _edge_key(edge_id: int) -> String:
	return "e:%d" % edge_id


## 顶点是否有效。
static func _is_valid_vertex(state: GameState, vertex_id: int) -> bool:
	return state.board.get_vertex(vertex_id) != null


## 边是否有效。
static func _is_valid_edge(state: GameState, edge_id: int) -> bool:
	return state.board.get_edge(edge_id) != null


## 顶点是否已被占据。
static func _is_vertex_occupied(state: GameState, vertex_id: int) -> bool:
	return state.placements.has(_vertex_key(vertex_id))


## 边是否已被占据。
static func _is_edge_occupied(state: GameState, edge_id: int) -> bool:
	return state.placements.has(_edge_key(edge_id))


## 是否满足距离规则（距任意定居点 ≥2 边）。
static func _satisfies_distance_rule(state: GameState, vertex_id: int) -> bool:
	# 检查相邻顶点是否有定居点/城市
	var adj: Array = state.board.adjacent_vertices(vertex_id)
	for adj_vid in adj:
		var placement: Placement = state.placements.get(_vertex_key(adj_vid))
		if placement != null and (placement.building_id == "settlement" or placement.building_id == "city"):
			return false
	return true


## 道路是否连接到玩家道路网络。
static func _is_road_connected(state: GameState, edge_id: int, player_id: int) -> bool:
	var edge_verts: Array = state.board.edge_vertices(edge_id)
	for vid in edge_verts:
		# 顶点有己方定居点/城市
		var placement: Placement = state.placements.get(_vertex_key(vid))
		if placement != null and placement.player_id == player_id:
			if placement.building_id == "settlement" or placement.building_id == "city":
				return true
		# 顶点有己方道路连接
		var adj_edges: Array = state.board.vertex_edges(vid)
		for adj_eid in adj_edges:
			if adj_eid == edge_id:
				continue
			var adj_p: Placement = state.placements.get(_edge_key(adj_eid))
			if adj_p != null and adj_p.player_id == player_id and adj_p.building_id == "road":
				return true
	return false


## 定居点是否连接到玩家道路网络。
static func _is_settlement_connected(state: GameState, vertex_id: int, player_id: int) -> bool:
	var adj_edges: Array = state.board.vertex_edges(vertex_id)
	for eid in adj_edges:
		var placement: Placement = state.placements.get(_edge_key(eid))
		if placement != null and placement.player_id == player_id and placement.building_id == "road":
			return true
	return false


## 玩家是否在指定六边形相邻顶点有建筑。
static func _player_has_building_near_hex(state: GameState, player_id: int, hex_id: int) -> bool:
	var vertex_ids: Array = _hex_vertex_ids(state.board, hex_id)
	for vid in vertex_ids:
		var placement: Placement = state.placements.get(_vertex_key(vid))
		if placement != null and placement.player_id == player_id:
			if placement.building_id == "settlement" or placement.building_id == "city":
				return true
	return false


## 获取六边形相邻的所有玩家 ID。
static func get_players_near_hex(state: GameState, hex_id: int) -> Array:
	var result: Array = []
	var vertex_ids: Array = _hex_vertex_ids(state.board, hex_id)
	for vid in vertex_ids:
		var placement: Placement = state.placements.get(_vertex_key(vid))
		if placement != null and (placement.building_id == "settlement" or placement.building_id == "city"):
			if not result.has(placement.player_id):
				result.append(placement.player_id)
	return result
