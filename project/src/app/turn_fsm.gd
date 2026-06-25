## 回合状态机（Layer 2 应用层）。
##
## 管理游戏回合的阶段流转，基于 GameState.Phase 进行状态转移。
## 每个状态定义合法动作集合，非法动作在 Layer 1 校验阶段被拒。
##
## 见 ARCHITECTURE §4.1。
class_name TurnFSM extends RefCounted

# ---- 状态定义 ----
## 初始放置阶段 1（正向）
const STATE_SETUP_1: int = 0
## 初始放置阶段 2（反向）
const STATE_SETUP_2: int = 1
## 掷骰阶段
const STATE_ROLL: int = 2
## 行动阶段
const STATE_ACTION: int = 3
## 等待弃牌阶段（7 点触发）
const STATE_DISCARD: int = 4
## 等待移动强盗阶段
const STATE_MOVE_ROBBER: int = 5
## 结束回合阶段
const STATE_END_TURN: int = 6
## 游戏结束
const STATE_GAME_OVER: int = 7


## 根据 GameState 推导当前 FSM 状态。
## [param state] 游戏状态
## [return] FSM 状态常量
static func get_state(state: GameState) -> int:
	if state.is_game_over:
		return STATE_GAME_OVER
	if state.phase == GameState.Phase.SETUP:
		if state.setup_round == 1:
			return STATE_SETUP_1
		elif state.setup_round == 2:
			return STATE_SETUP_2
		return STATE_SETUP_1
	if state.robber_required:
		return STATE_MOVE_ROBBER
	if state.phase == GameState.Phase.ROLL:
		return STATE_ROLL
	if state.phase == GameState.Phase.ACTION:
		return STATE_ACTION
	if state.phase == GameState.Phase.END_TURN:
		return STATE_END_TURN
	return STATE_ACTION


## 获取状态名称。
static func state_name(state: int) -> String:
	match state:
		STATE_SETUP_1: return "SETUP_1"
		STATE_SETUP_2: return "SETUP_2"
		STATE_ROLL: return "ROLL"
		STATE_ACTION: return "ACTION"
		STATE_DISCARD: return "DISCARD"
		STATE_MOVE_ROBBER: return "MOVE_ROBBER"
		STATE_END_TURN: return "END_TURN"
		STATE_GAME_OVER: return "GAME_OVER"
		_: return "UNKNOWN"


## 获取指定状态下允许的动作类型列表。
## [param state] FSM 状态
## [return] Array of int (Action.TYPE_*)
static func allowed_actions(state: int) -> Array:
	match state:
		STATE_SETUP_1, STATE_SETUP_2:
			return [Action.TYPE_BUILD]
		STATE_ROLL:
			return [Action.TYPE_ROLL_DICE]
		STATE_ACTION:
			return [Action.TYPE_BUILD, Action.TYPE_TRADE, Action.TYPE_USE_DEV_CARD, Action.TYPE_END_TURN]
		STATE_MOVE_ROBBER:
			return [Action.TYPE_MOVE_ROBBER]
		STATE_DISCARD:
			return [Action.TYPE_DISCARD]
		STATE_END_TURN:
			return [Action.TYPE_END_TURN]
		STATE_GAME_OVER:
			return []
		_:
			return []


## 检查动作类型在指定状态下是否允许。
static func is_action_allowed(state: int, action_type: int) -> bool:
	return allowed_actions(state).has(action_type)


## 检查是否需要弃牌（7 点触发后，检查所有玩家）。
## [param state] 游戏状态
## [return] 需要弃牌的玩家 ID 列表
static func get_players_needing_discard(state: GameState) -> Array:
	var result: Array = []
	for p in state.get_all_players():
		if p.discard_half_count() > 0:
			result.append(p.player_id)
	return result
