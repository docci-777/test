## 全局游戏状态。
##
## 持有所有玩家状态、银行资源池、发展卡牌堆、强盗位置、回合流程状态。
## 属于 Layer 1 核心层，纯逻辑，不依赖 Node。
##
## 回合阶段定义见 GAME_RULES §5。胜利条件见 §12。
class_name GameState extends RefCounted

## 回合阶段
enum Phase {
	SETUP,       ## 初始放置阶段
	ROLL,        ## 掷骰阶段
	ACTION,      ## 行动阶段
	END_TURN,    ## 结束阶段
	GAME_OVER    ## 游戏结束
}

## 基础版默认胜利点门槛
const DEFAULT_VICTORY_THRESHOLD: int = 10
## 银行每种资源默认数量
const DEFAULT_BANK_PER_RESOURCE: int = 19

## 玩家列表（按 player_id 索引）
var players: Array = [] # Array of PlayerState
## 当前回合玩家 ID
var current_player_id: int = 0
## 当前阶段
var phase: int = Phase.SETUP
## 回合数（从 1 开始，初始放置完成后进入第 1 回合）
var round_number: int = 1
## 胜利点门槛
var victory_threshold: int = DEFAULT_VICTORY_THRESHOLD
## 银行资源池
var bank: ResourceSet
## 发展卡牌堆（剩余可抽）
var dev_card_deck: Array = [] # Array of String
## 强盗所在六边形 ID（-1 表示未放置）
## 强盗位置（hex_id，-1 表示未放置）
var robber_hex_id: int = -1
## 本回合是否已掷骰
var has_rolled_this_turn: bool = false
## 是否需要移动强盗（掷出 7 后）
var robber_required: bool = false
## 初始放置轮次（1=第一轮正向, 2=第二轮反向）
var setup_round: int = 1
## 初始放置方向（1=正向, -1=反向）
var setup_direction: int = 1
## 初始放置时刚放置的定居点顶点（用于道路连接校验）
var setup_last_settlement_vertex: int = -1
## 初始放置时当前玩家是否已放置定居点（等待放置道路）
var setup_settlement_placed: bool = false
## 游戏是否结束
var is_game_over: bool = false
## 获胜者（游戏结束时设置）
var winner: PlayerState = null
## 场景标识（基础版/海洋扩展场景）
var scenario_id: String = "base_4p"
## 建筑定义（id -> BuildingDef，配置数据，不可变）
var buildings: Dictionary = {}
## 地形定义（id -> TerrainDef，配置数据，不可变）
var terrains: Dictionary = {}
## 港口定义（id -> PortDef，配置数据，不可变）
var ports: Dictionary = {}
## 发展卡定义（id -> DevCardDef，配置数据，不可变）
var dev_cards: Dictionary = {}
## 棋盘拓扑（Board 实例，配置数据，不可变）
var board: Board = null
## 建筑放置状态（vertex_id/edge_id -> Placement）
var placements: Dictionary = {}


func _init() -> void:
	bank = ResourceSet.new()


# ---- 玩家管理 ----

## 添加玩家。
func add_player(p: PlayerState) -> void:
	players.append(p)


## 玩家数量。
func player_count() -> int:
	return players.size()


## 根据 ID 获取玩家（不存在返回 null）。
func get_player(pid: int) -> PlayerState:
	for p in players:
		if p.player_id == pid:
			return p
	return null


## 获取所有玩家。
func get_all_players() -> Array:
	return players


## 获取当前回合玩家。
func current_player() -> PlayerState:
	return get_player(current_player_id)


# ---- 回合流程 ----

## 推进到下一位玩家（环绕，并递增回合数）。
func advance_turn() -> void:
	current_player_id = (current_player_id + 1) % players.size()
	if current_player_id == 0:
		round_number += 1
	# 重置新回合玩家的本回合标记
	var p := current_player()
	if p != null:
		p.reset_turn_flags()


## 设置当前阶段。
func set_phase(p: int) -> void:
	phase = p


# ---- 银行资源池 ----

## 初始化银行（每种资源 19 张）。
func init_bank() -> void:
	bank = ResourceSet.new()
	for t in ResType.all():
		bank.set_amount(t, DEFAULT_BANK_PER_RESOURCE)


## 从银行取出资源（不足返回 false）。
func bank_withdraw(t: int, amount: int) -> bool:
	if bank.get_amount(t) < amount:
		return false
	bank.subtract(t, amount)
	return true


## 存入银行。
func bank_deposit(t: int, amount: int) -> void:
	bank.add(t, amount)


# ---- 发展卡牌堆 ----

## 初始化发展卡牌堆（按 dev_cards.json 数量生成，共 25 张）。
func init_dev_card_deck() -> void:
	dev_card_deck.clear()
	# 数量定义（与 data/dev_cards.json 一致，数据驱动加载后可替换）
	var counts: Dictionary = {
		"knight": 14,
		"victory_point": 5,
		"road_building": 2,
		"year_of_plenty": 2,
		"monopoly": 2,
	}
	for card_id in counts.keys():
		for i in range(counts[card_id]):
			dev_card_deck.append(card_id)


## 从牌堆抽一张卡（空堆返回空字符串）。
func draw_dev_card() -> String:
	if dev_card_deck.is_empty():
		return ""
	return dev_card_deck.pop_back()


# ---- 强盗 ----

## 设置强盗位置。
func set_robber_position(hex_id: int) -> void:
	robber_hex_id = hex_id


# ---- 胜利判定 ----

## 设置胜利点门槛。
func set_victory_threshold(threshold: int) -> void:
	victory_threshold = threshold


## 检查是否有玩家达到胜利点门槛。
## [return] 获胜玩家，无则 null
func check_winner() -> PlayerState:
	for p in players:
		if p.total_victory_points() >= victory_threshold:
			return p
	return null


## 结束游戏并记录获胜者。
func end_game(winner_player: PlayerState) -> void:
	is_game_over = true
	winner = winner_player
	phase = Phase.GAME_OVER


# ---- 克隆 ----

## 创建独立副本（用于不可变状态变更）。
func clone() -> GameState:
	var c := GameState.new()
	c.current_player_id = current_player_id
	c.phase = phase
	c.round_number = round_number
	c.victory_threshold = victory_threshold
	c.bank = bank.clone()
	c.dev_card_deck = dev_card_deck.duplicate()
	c.robber_hex_id = robber_hex_id
	c.has_rolled_this_turn = has_rolled_this_turn
	c.robber_required = robber_required
	c.setup_round = setup_round
	c.setup_direction = setup_direction
	c.setup_last_settlement_vertex = setup_last_settlement_vertex
	c.setup_settlement_placed = setup_settlement_placed
	c.is_game_over = is_game_over
	c.winner = winner  # 引用共享，不应修改
	c.scenario_id = scenario_id
	c.buildings = buildings  # 配置数据，共享引用
	c.terrains = terrains  # 配置数据，共享引用
	c.ports = ports  # 配置数据，共享引用
	c.dev_cards = dev_cards  # 配置数据，共享引用
	c.board = board  # 拓扑数据，共享引用
	c.placements = placements.duplicate(true)  # 放置状态，深拷贝
	for p in players:
		c.players.append(p.clone())
	return c
