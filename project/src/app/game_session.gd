## 游戏会话（Layer 2 应用层）。
##
## 持有 GameState 与 EventBus，对外暴露 submit_action 接口。
## 是网络层与表现层的统一交互点。
##
## 见 ARCHITECTURE §4.2。
class_name GameSession extends RefCounted

## 当前游戏状态
var state: GameState
## 事件总线
var event_bus: EventBus
## 动作历史记录（用于回放/调试）
var _action_history: Array = []
## 事件历史记录
var _event_history: Array = []
## 会话是否已初始化
var _initialized: bool = false


func _init() -> void:
	event_bus = EventBus.new()


## 初始化新游戏。
## [param player_count] 玩家数量（2-4）
## [param seed] 随机种子
func setup_new_game(player_count: int = 4, seed: int = 0) -> Result:
	if player_count < 2 or player_count > 4:
		return Result.failure(Result.ERR_INVALID_ARG, "player_count must be 2-4")
	# 加载数据
	var terrains_r := DataLoader.load_terrains()
	if not terrains_r.ok:
		return terrains_r
	var buildings_r := DataLoader.load_buildings()
	if not buildings_r.ok:
		return buildings_r
	var dev_cards_r := DataLoader.load_dev_cards()
	if not dev_cards_r.ok:
		return dev_cards_r
	var ports_r := DataLoader.load_ports()
	if not ports_r.ok:
		return ports_r
	# 生成棋盘
	var use_seed: int = seed
	if use_seed == 0:
		use_seed = Time.get_ticks_msec()
	var board_r := BoardGenerator.generate_full_base_board(use_seed, terrains_r.value, ports_r.value)
	if not board_r.ok:
		return board_r
	# 创建状态
	state = GameState.new()
	state.terrains = terrains_r.value
	state.buildings = buildings_r.value
	state.dev_cards = dev_cards_r.value
	state.ports = ports_r.value
	state.board = board_r.value
	# 放置强盗到沙漠
	for hex_data in state.board.all_hexes():
		if hex_data.terrain_id == "desert":
			state.robber_hex_id = hex_data.id
			break
	# 初始化银行和牌堆
	state.init_bank()
	state.init_dev_card_deck()
	# 添加玩家
	var colors := ["red", "blue", "white", "orange"]
	for i in range(player_count):
		state.add_player(PlayerState.new(i, colors[i]))
	# 初始阶段
	state.set_phase(GameState.Phase.SETUP)
	state.setup_round = 1
	state.setup_direction = 1
	# 发送回合开始事件
	_event_history.append(Event.create_turn_started(0, 1))
	event_bus.dispatch(Event.create_turn_started(0, 1))
	_initialized = true
	return Result.success()


## 提交动作并执行。
## [param action] 待执行动作
## [return] Result，成功时 value 为事件列表
func submit_action(action: Action) -> Result:
	if not _initialized:
		return Result.failure(Result.ERR_INVALID_STATE, "session not initialized")
	if state.is_game_over:
		return Result.failure(Result.ERR_GAME_OVER, "game is over")
	# 执行动作
	var result := RulesEngine.apply(action, state)
	if not result.result.ok:
		return result.result
	# 更新状态
	state = result.state
	# 记录历史
	_action_history.append(action)
	_event_history.append_array(result.events)
	# 分发事件
	event_bus.dispatch_all(result.events)
	return Result.success(result.events)


## 获取当前 FSM 状态。
func current_fsm_state() -> int:
	return TurnFSM.get_state(state)


## 获取当前玩家。
func current_player() -> PlayerState:
	return state.current_player()


## 获取当前状态下允许的动作类型。
func allowed_actions() -> Array:
	return TurnFSM.allowed_actions(current_fsm_state())


## 检查动作是否允许。
func is_action_allowed(action: Action) -> bool:
	return TurnFSM.is_action_allowed(current_fsm_state(), action.action_type)


## 获取动作历史。
func action_history() -> Array:
	return _action_history


## 获取事件历史。
func event_history() -> Array:
	return _event_history


## 游戏是否结束。
func is_game_over() -> bool:
	return state.is_game_over


## 获取获胜者。
func winner() -> PlayerState:
	return state.winner
