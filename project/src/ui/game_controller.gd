## 游戏控制器（P9-8）。
##
## 表现层核心控制器，协调 BoardView、HUD、对话框等子视图。
## 管理游戏流程：初始放置 → 掷骰 → 行动 → 回合切换。
##
## 见 ARCHITECTURE §6：表现层不直接改状态，通过 GameSession.submit_action 提交动作。
class_name GameController extends Node2D

# ---- 子视图 ----
var _board_view: BoardView
var _hud: HUD
var _trade_dialog: TradeDialog
var _victory_screen: VictoryScreen
var _player_switch: PlayerSwitch

# ---- 游戏会话 ----
var _session: GameSession

# ---- UI 状态 ----
enum UIBuildMode {
	NONE,
	SETUP_SETTLEMENT,
	SETUP_ROAD,
	BUILD_ROAD,
	BUILD_SETTLEMENT,
	BUILD_CITY,
	MOVE_ROBBER,
}
var _ui_mode: UIBuildMode = UIBuildMode.NONE

# SETUP 阶段：记录刚放置的定居点顶点
var _setup_settlement_vertex: int = -1

# 强盗移动后待偷取的目标玩家列表
var _steal_candidates: Array = []


func _ready() -> void:
	_create_views()
	_connect_signals()
	_start_new_game()


func _create_views() -> void:
	_board_view = BoardView.new()
	_board_view.name = "BoardView"
	add_child(_board_view)

	_hud = HUD.new()
	_hud.name = "HUD"
	add_child(_hud)

	_trade_dialog = TradeDialog.new()
	_trade_dialog.name = "TradeDialog"
	add_child(_trade_dialog)

	_victory_screen = VictoryScreen.new()
	_victory_screen.name = "VictoryScreen"
	add_child(_victory_screen)

	_player_switch = PlayerSwitch.new()
	_player_switch.name = "PlayerSwitch"
	add_child(_player_switch)


func _connect_signals() -> void:
	_board_view.vertex_clicked.connect(_on_vertex_clicked)
	_board_view.edge_clicked.connect(_on_edge_clicked)
	_board_view.hex_clicked.connect(_on_hex_clicked)

	_hud.roll_dice_pressed.connect(_on_roll_dice)
	_hud.build_pressed.connect(_on_build_pressed)
	_hud.trade_pressed.connect(_on_trade_pressed)
	_hud.use_dev_card_pressed.connect(_on_use_dev_card)
	_hud.end_turn_pressed.connect(_on_end_turn)

	_trade_dialog.trade_confirmed.connect(_on_trade_confirmed)
	_trade_dialog.trade_cancelled.connect(_on_trade_cancelled)

	_player_switch.confirmed.connect(_on_player_switch_confirmed)
	_victory_screen.restart_requested.connect(_on_restart)


func _start_new_game() -> void:
	_session = GameSession.new()
	var r := _session.setup_new_game(4)
	if not r.ok:
		push_error("Failed to start game: %s" % r.error_message)
		return

	# 订阅全局事件
	_session.event_bus.subscribe(-1, _on_game_event)

	_refresh_all_views()
	_show_player_switch()


# ---- 视图刷新 ----

func _refresh_all_views() -> void:
	_board_view.update_view(_session.state)
	_hud.update_view(_session.state)


func _refresh_after_action() -> void:
	_refresh_all_views()

	# 检查游戏结束
	if _session.is_game_over():
		_victory_screen.show_victory(_session.winner(), _session.state.get_all_players())
		return

	# 检查是否需要切换玩家
	var fsm_state: int = _session.current_fsm_state()
	if fsm_state == TurnFSM.STATE_SETUP_1 or fsm_state == TurnFSM.STATE_SETUP_2:
		# SETUP 阶段，可能需要切换玩家
		_handle_setup_flow()
	elif fsm_state == TurnFSM.STATE_ROLL:
		# 新回合，显示玩家切换
		_show_player_switch()
	elif fsm_state == TurnFSM.STATE_MOVE_ROBBER:
		_start_move_robber()


# ---- 玩家切换 ----

func _show_player_switch() -> void:
	var player: PlayerState = _session.current_player()
	if player == null:
		return
	var fsm_state: int = _session.current_fsm_state()
	var is_setup: bool = fsm_state == TurnFSM.STATE_SETUP_1 or fsm_state == TurnFSM.STATE_SETUP_2
	_player_switch.show_switch(player, _session.state.round_number, is_setup)


func _on_player_switch_confirmed() -> void:
	var fsm_state: int = _session.current_fsm_state()
	match fsm_state:
		TurnFSM.STATE_SETUP_1, TurnFSM.STATE_SETUP_2:
			_start_setup_placement()
		TurnFSM.STATE_ROLL:
			_ui_mode = UIBuildMode.NONE
			_board_view.clear_build_mode()
		TurnFSM.STATE_MOVE_ROBBER:
			_start_move_robber()


# ---- SETUP 阶段 ----

func _handle_setup_flow() -> void:
	# 检查SETUP是否完成
	var fsm_state: int = _session.current_fsm_state()
	if fsm_state == TurnFSM.STATE_SETUP_1 or fsm_state == TurnFSM.STATE_SETUP_2:
		# 还在SETUP阶段，切换到下一位玩家
		_show_player_switch()


func _start_setup_placement() -> void:
	var fsm_state: int = _session.current_fsm_state()
	if fsm_state != TurnFSM.STATE_SETUP_1 and fsm_state != TurnFSM.STATE_SETUP_2:
		return

	# 检查当前玩家是否需要放定居点还是道路
	if not _session.state.setup_settlement_placed:
		# 需要放定居点
		_ui_mode = UIBuildMode.SETUP_SETTLEMENT
		var valid := _get_valid_setup_vertices()
		_board_view.set_build_mode("settlement", valid)
		_hud.show_message("请放置定居点")
	else:
		# 需要放道路
		_ui_mode = UIBuildMode.SETUP_ROAD
		var valid := _get_valid_setup_edges()
		_board_view.set_build_mode("road", valid)
		_hud.show_message("请放置道路（连接到定居点）")


func _get_valid_setup_vertices() -> Array:
	var valid: Array = []
	var board: Board = _session.state.board
	for v in board.all_vertices():
		var vd: Board.VertexData = v
		# 距离规则：距已有定居点 ≥2 边
		var ok: bool = true
		for adj_vid in board.adjacent_vertices(vd.id):
			var p: Placement = _session.state.placements.get("v:%d" % adj_vid)
			if p != null and (p.building_id == "settlement" or p.building_id == "city"):
				ok = false
				break
		# 顶点未被占据
		if ok and not _session.state.placements.has("v:%d" % vd.id):
			valid.append(vd.id)
	return valid


func _get_valid_setup_edges() -> Array:
	var valid: Array = []
	var board: Board = _session.state.board
	var pid: int = _session.state.current_player_id
	var settlement_vid: int = _setup_settlement_vertex
	if settlement_vid < 0:
		settlement_vid = _session.state.setup_last_settlement_vertex

	# 找到连接到定居点的边
	for e in board.all_edges():
		var ed: Board.EdgeData = e
		var verts: Array = board.edge_vertices(ed.id)
		if verts.has(settlement_vid) and not _session.state.placements.has("e:%d" % ed.id):
			valid.append(ed.id)
	return valid


# ---- 掷骰 ----

func _on_roll_dice() -> void:
	var player: PlayerState = _session.current_player()
	if player == null:
		return
	var action := RollDiceAction.new(player.player_id)
	var r := _session.submit_action(action)
	if not r.ok:
		_hud.show_message("掷骰失败：%s" % r.error_message)
		return

	# 从事件中提取骰子结果
	var die1: int = 1
	var die2: int = 1
	var events: Array = r.value
	for e in events:
		if e is Event and e.event_type == Event.TYPE_DICE_ROLLED:
			die1 = int(e.get_payload("die1"))
			die2 = int(e.get_payload("die2"))
			break

	_hud.show_dice_roll(die1, die2)
	_refresh_after_action()

	# 如果掷出 7，需要处理强盗
	if die1 + die2 == 7:
		_hud.show_message("掷出 7！强盗出动！")
		# 先处理弃牌
		_handle_discard_phase()
	else:
		_hud.show_message("掷出 %d" % (die1 + die2))


# ---- 建造 ----

func _on_build_pressed(building_id: String) -> void:
	match building_id:
		"road":
			_ui_mode = UIBuildMode.BUILD_ROAD
			var valid := _get_valid_build_edges()
			_board_view.set_build_mode("road", valid)
			if valid.is_empty():
				_hud.show_message("没有可放置道路的位置")
				_board_view.clear_build_mode()
				_ui_mode = UIBuildMode.NONE
			else:
				_hud.show_message("点击高亮位置放置道路")
		"settlement":
			_ui_mode = UIBuildMode.BUILD_SETTLEMENT
			var valid := _get_valid_build_vertices()
			_board_view.set_build_mode("settlement", valid)
			if valid.is_empty():
				_hud.show_message("没有可放置定居点的位置")
				_board_view.clear_build_mode()
				_ui_mode = UIBuildMode.NONE
			else:
				_hud.show_message("点击高亮位置放置定居点")
		"city":
			_ui_mode = UIBuildMode.BUILD_CITY
			var valid := _get_valid_city_vertices()
			_board_view.set_build_mode("city", valid)
			if valid.is_empty():
				_hud.show_message("没有可升级城市的定居点")
				_board_view.clear_build_mode()
				_ui_mode = UIBuildMode.NONE
			else:
				_hud.show_message("点击高亮定居点升级为城市")
		"dev_card":
			_buy_dev_card()


func _get_valid_build_edges() -> Array:
	var valid: Array = []
	var board: Board = _session.state.board
	var pid: int = _session.state.current_player_id
	for e in board.all_edges():
		var ed: Board.EdgeData = e
		if _session.state.placements.has("e:%d" % ed.id):
			continue
		# 检查连接性
		var verts: Array = board.edge_vertices(ed.id)
		var connected: bool = false
		for vid in verts:
			# 顶点有己方定居点/城市
			var p: Placement = _session.state.placements.get("v:%d" % vid)
			if p != null and p.player_id == pid and (p.building_id == "settlement" or p.building_id == "city"):
				connected = true
				break
			# 顶点有己方道路
			for adj_eid in board.vertex_edges(vid):
				if adj_eid == ed.id:
					continue
				var adj_p: Placement = _session.state.placements.get("e:%d" % adj_eid)
				if adj_p != null and adj_p.player_id == pid and adj_p.building_id == "road":
					connected = true
					break
			if connected:
				break
		if connected:
			valid.append(ed.id)
	return valid


func _get_valid_build_vertices() -> Array:
	var valid: Array = []
	var board: Board = _session.state.board
	var pid: int = _session.state.current_player_id
	for v in board.all_vertices():
		var vd: Board.VertexData = v
		if _session.state.placements.has("v:%d" % vd.id):
			continue
		# 距离规则
		var ok: bool = true
		for adj_vid in board.adjacent_vertices(vd.id):
			var p: Placement = _session.state.placements.get("v:%d" % adj_vid)
			if p != null and (p.building_id == "settlement" or p.building_id == "city"):
				ok = false
				break
		if not ok:
			continue
		# 连接性：相邻边有己方道路
		var connected: bool = false
		for eid in board.vertex_edges(vd.id):
			var p: Placement = _session.state.placements.get("e:%d" % eid)
			if p != null and p.player_id == pid and p.building_id == "road":
				connected = true
				break
		if connected:
			valid.append(vd.id)
	return valid


func _get_valid_city_vertices() -> Array:
	var valid: Array = []
	var pid: int = _session.state.current_player_id
	for key in _session.state.placements.keys():
		var p: Placement = _session.state.placements[key]
		if p.player_id == pid and p.building_id == "settlement":
			valid.append(p.position_id)
	return valid


func _buy_dev_card() -> void:
	var player: PlayerState = _session.current_player()
	if player == null:
		return
	var action := BuildAction.new(player.player_id, "dev_card", -1)
	var r := _session.submit_action(action)
	if not r.ok:
		_hud.show_message("购买失败：%s" % r.error_message)
		return
	# 从新状态获取抽到的卡（手牌最后一张）
	var new_player: PlayerState = _session.state.get_player(player.player_id)
	var card_id: String = ""
	if new_player != null and not new_player.dev_cards_hand.is_empty():
		card_id = new_player.dev_cards_hand[-1]
	_hud.show_message("抽到发展卡：%s" % card_id)
	_refresh_after_action()


# ---- 点击处理 ----

func _on_vertex_clicked(vertex_id: int) -> void:
	var player: PlayerState = _session.current_player()
	if player == null:
		return

	match _ui_mode:
		UIBuildMode.SETUP_SETTLEMENT:
			var action := BuildAction.new(player.player_id, "settlement", vertex_id)
			var r := _session.submit_action(action)
			if not r.ok:
				_hud.show_message("放置失败：%s" % r.error_message)
				return
			_setup_settlement_vertex = vertex_id
			_session.state.setup_settlement_placed = true
			_board_view.clear_build_mode()
			_refresh_after_action()
			# 继续放置道路
			_start_setup_placement()

		UIBuildMode.BUILD_SETTLEMENT:
			var action := BuildAction.new(player.player_id, "settlement", vertex_id)
			var r := _session.submit_action(action)
			if not r.ok:
				_hud.show_message("建造失败：%s" % r.error_message)
				return
			_ui_mode = UIBuildMode.NONE
			_board_view.clear_build_mode()
			_refresh_after_action()

		UIBuildMode.BUILD_CITY:
			var action := BuildAction.new(player.player_id, "city", vertex_id)
			var r := _session.submit_action(action)
			if not r.ok:
				_hud.show_message("升级失败：%s" % r.error_message)
				return
			_ui_mode = UIBuildMode.NONE
			_board_view.clear_build_mode()
			_refresh_after_action()


func _on_edge_clicked(edge_id: int) -> void:
	var player: PlayerState = _session.current_player()
	if player == null:
		return

	match _ui_mode:
		UIBuildMode.SETUP_ROAD:
			var action := BuildAction.new(player.player_id, "road", edge_id)
			var r := _session.submit_action(action)
			if not r.ok:
				_hud.show_message("放置失败：%s" % r.error_message)
				return
			_setup_settlement_vertex = -1
			_session.state.setup_settlement_placed = false
			_board_view.clear_build_mode()
			_ui_mode = UIBuildMode.NONE
			_refresh_after_action()
			# SETUP 阶段放置完成后切换玩家
			_show_player_switch()

		UIBuildMode.BUILD_ROAD:
			var action := BuildAction.new(player.player_id, "road", edge_id)
			var r := _session.submit_action(action)
			if not r.ok:
				_hud.show_message("建造失败：%s" % r.error_message)
				return
			_ui_mode = UIBuildMode.NONE
			_board_view.clear_build_mode()
			_refresh_after_action()


func _on_hex_clicked(hex_id: int) -> void:
	if _ui_mode != UIBuildMode.MOVE_ROBBER:
		return
	var player: PlayerState = _session.current_player()
	if player == null:
		return

	# 查找相邻玩家
	_steal_candidates = RulesEngine.get_players_near_hex(_session.state, hex_id)

	var action := MoveRobberAction.new(player.player_id, hex_id, -1)
	var r := _session.submit_action(action)
	if not r.ok:
		_hud.show_message("移动强盗失败：%s" % r.error_message)
		return

	_ui_mode = UIBuildMode.NONE
	_board_view.clear_build_mode()
	_refresh_after_action()

	# 如果有可偷取的玩家，自动偷取第一个
	if not _steal_candidates.is_empty():
		# 简化：自动偷取第一个玩家（后续可扩展为选择对话框）
		var target_id: int = _steal_candidates[0]
		_hud.show_message("从玩家 %d 偷取资源" % target_id)
	else:
		_hud.show_message("强盗已移动")


# ---- 强盗 ----

func _start_move_robber() -> void:
	_ui_mode = UIBuildMode.MOVE_ROBBER
	var valid: Array = []
	for hex_data in _session.state.board.all_hexes():
		if hex_data.id != _session.state.robber_hex_id:
			valid.append(hex_data.id)
	_board_view.set_build_mode("robber", valid)
	_hud.show_message("请移动强盗到新地形")


# ---- 弃牌 ----

func _handle_discard_phase() -> void:
	var need_discard: Array = TurnFSM.get_players_needing_discard(_session.state)
	if need_discard.is_empty():
		# 无需弃牌，直接移动强盗
		_start_move_robber()
	else:
		# 简化：自动为需要弃牌的玩家随机弃牌
		for pid in need_discard:
			var p: PlayerState = _session.state.get_player(pid)
			if p == null:
				continue
			var need: int = p.discard_half_count()
			var ds := ResourceSet.new()
			var remaining: int = need
			for t in ResType.all():
				if remaining <= 0:
					break
				var avail: int = p.resources.get_amount(t)
				var take: int = mini(avail, remaining)
				if take > 0:
					ds.set_amount(t, take)
					remaining -= take
			if remaining == 0:
				var action := DiscardAction.new(pid, ds)
				_session.submit_action(action)
		_hud.show_message("手牌超 7 的玩家已弃牌")
		_refresh_after_action()
		_start_move_robber()


# ---- 交易 ----

func _on_trade_pressed() -> void:
	_trade_dialog.show_dialog(_session.state)


func _on_trade_confirmed(action: TradeAction) -> void:
	var r := _session.submit_action(action)
	if not r.ok:
		_hud.show_message("交易失败：%s" % r.error_message)
		return
	_hud.show_message("交易完成")
	_refresh_after_action()


func _on_trade_cancelled() -> void:
	pass


# ---- 发展卡 ----

func _on_use_dev_card(card_id: String) -> void:
	var player: PlayerState = _session.current_player()
	if player == null:
		return

	var action := UseDevCardAction.new(player.player_id, card_id)

	# 对于需要额外参数的卡，设置默认值
	match card_id:
		"knight":
			# 骑士卡：需要移动强盗，先提交使用
			var r := _session.submit_action(action)
			if not r.ok:
				_hud.show_message("使用失败：%s" % r.error_message)
				return
			_hud.show_message("使用骑士卡，请移动强盗")
			_refresh_after_action()
			_start_move_robber()
			return
		"year_of_plenty":
			# 发明卡：简化为取木材和矿石
			action.year_of_plenty_res1 = ResType.WOOD
			action.year_of_plenty_res2 = ResType.ORE
		"monopoly":
			# 垄断卡：简化为垄断木材
			action.monopoly_resource = ResType.WOOD
		"road_building":
			# 道路建设卡：需要后续放置 2 条道路
			action.road_building_edge1 = -1
			action.road_building_edge2 = -1

	var r := _session.submit_action(action)
	if not r.ok:
		_hud.show_message("使用失败：%s" % r.error_message)
		return
	_hud.show_message("使用了 %s" % card_id)
	_refresh_after_action()


# ---- 结束回合 ----

func _on_end_turn() -> void:
	var player: PlayerState = _session.current_player()
	if player == null:
		return
	var action := EndTurnAction.new(player.player_id)
	var r := _session.submit_action(action)
	if not r.ok:
		_hud.show_message("结束回合失败：%s" % r.error_message)
		return
	_ui_mode = UIBuildMode.NONE
	_board_view.clear_build_mode()
	_refresh_after_action()
	_show_player_switch()


# ---- 事件处理 ----

func _on_game_event(event: Event) -> void:
	# 事件驱动的 UI 更新已在 _refresh_after_action 中处理
	pass


# ---- 重新开始 ----

func _on_restart() -> void:
	_start_new_game()


# ---- 输入 ----

func _unhandled_input(event: InputEvent) -> void:
	# ESC 取消建造模式
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _ui_mode != UIBuildMode.NONE:
			_ui_mode = UIBuildMode.NONE
			_board_view.clear_build_mode()
			_hud.show_message("已取消")
