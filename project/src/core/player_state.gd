## 玩家状态。
##
## 表示单个玩家的完整状态：资源手牌、已建建筑、发展卡、胜利点、成就持有。
## 属于 Layer 1 核心层，纯逻辑，不依赖 Node。
##
## 胜利点构成见 GAME_RULES §12.3。
class_name PlayerState extends RefCounted

## 玩家 ID（0-3）
var player_id: int = 0
## 颜色标识（"red"/"blue"/"white"/"orange"）
var color: String = "red"
## 资源手牌
var resources: ResourceSet
## 已建建筑计数（建筑 id -> 数量）
var buildings: Dictionary = {} # String -> int
## 发展卡手牌（卡牌 id 列表，按购买顺序）
var dev_cards_hand: Array = [] # Array of String
## 已使用骑士数（计入最大军队）
var played_knights: int = 0
## 隐藏胜利点（已使用的胜利点卡）
var hidden_victory_points: int = 0
## 是否持有最长道路成就
var has_longest_road: bool = false
## 是否持有最大军队成就
var has_largest_army: bool = false
## 本回合是否已使用发展卡
var dev_card_used_this_turn: bool = false
## 本回合购买的发展卡计数（card_id -> count，用于当回合不可用规则）
var dev_cards_bought_this_turn: Dictionary = {}


func _init(pid: int = 0, col: String = "red") -> void:
	player_id = pid
	color = col
	resources = ResourceSet.new()


# ---- 资源操作 ----

## 增加资源。
func add_resource(t: int, amount: int) -> void:
	resources.add(t, amount)


## 减少资源（不低于 0）。
func remove_resource(t: int, amount: int) -> void:
	resources.subtract(t, amount)


## 判断是否能支付指定成本。
func can_afford(cost: ResourceSet) -> bool:
	return resources.covers(cost)


## 支付成本（调用前应先 [method can_afford] 校验）。
func pay(cost: ResourceSet) -> void:
	resources.subtract_set(cost)


## 手牌总数。
func hand_size() -> int:
	return resources.total()


## 7 点触发时需弃牌数量（>7 张弃一半，向下取整）。
func discard_half_count() -> int:
	if hand_size() <= 7:
		return 0
	return hand_size() / 2


## 弃掉指定资源集合（用于 7 点弃半）。
## 调用前应确保资源足够。
func discard(rs: ResourceSet) -> void:
	resources.subtract_set(rs)


# ---- 建筑操作 ----

## 增加建筑计数。
func add_building(building_id: String) -> void:
	buildings[building_id] = buildings.get(building_id, 0) + 1


## 查询建筑数量。
func count_building(building_id: String) -> int:
	return buildings.get(building_id, 0)


## 升级定居点为城市（定居点 -1，城市 +1）。
func upgrade_settlement_to_city() -> void:
	var s: int = buildings.get("settlement", 0)
	if s > 0:
		buildings["settlement"] = s - 1
	buildings["city"] = buildings.get("city", 0) + 1


# ---- 发展卡操作 ----

## 添加发展卡到手牌。
## [param card_id] 卡牌标识
## [param bought_this_turn] 是否本回合购买（默认 true，用于当回合不可用规则）
func add_dev_card(card_id: String, bought_this_turn: bool = true) -> void:
	dev_cards_hand.append(card_id)
	if bought_this_turn:
		dev_cards_bought_this_turn[card_id] = dev_cards_bought_this_turn.get(card_id, 0) + 1


## 使用发展卡（从手牌移除并处理副作用）。
## [return] true 表示成功使用；false 表示未持有该卡
func use_dev_card(card_id: String) -> bool:
	var idx: int = dev_cards_hand.find(card_id)
	if idx < 0:
		return false
	dev_cards_hand.remove_at(idx)
	if card_id == "knight":
		played_knights += 1
	elif card_id == "victory_point":
		hidden_victory_points += 1
	dev_card_used_this_turn = true
	return true


## 是否持有指定发展卡。
func has_dev_card(card_id: String) -> bool:
	return dev_cards_hand.has(card_id)


## 是否有本回合不可使用的发展卡（非 usable_same_turn 且非本回合购买）。
## [return] true 表示手牌中至少有 1 张该类型卡牌不是本回合购买的
func has_usable_dev_card(card_id: String) -> bool:
	var hand_count: int = dev_cards_hand.count(card_id)
	var bought_this_turn: int = int(dev_cards_bought_this_turn.get(card_id, 0))
	return hand_count > bought_this_turn


# ---- 胜利点 ----

## 可见胜利点（建筑 + 成就，不含隐藏胜利点卡）。
func visible_victory_points() -> int:
	var vp: int = 0
	vp += count_building("settlement") * 1
	vp += count_building("city") * 2
	if has_longest_road:
		vp += 2
	if has_largest_army:
		vp += 2
	return vp


## 总胜利点（含隐藏胜利点卡）。
func total_victory_points() -> int:
	return visible_victory_points() + hidden_victory_points


# ---- 回合重置 ----

## 回合开始时重置本回合标记。
func reset_turn_flags() -> void:
	dev_card_used_this_turn = false
	dev_cards_bought_this_turn.clear()


# ---- 克隆 ----

## 创建独立副本（用于不可变状态变更，见 ARCHITECTURE §3.3）。
func clone() -> PlayerState:
	var c := PlayerState.new(player_id, color)
	c.resources = resources.clone()
	c.buildings = buildings.duplicate()
	c.dev_cards_hand = dev_cards_hand.duplicate()
	c.played_knights = played_knights
	c.hidden_victory_points = hidden_victory_points
	c.has_longest_road = has_longest_road
	c.has_largest_army = has_largest_army
	c.dev_card_used_this_turn = dev_card_used_this_turn
	c.dev_cards_bought_this_turn = dev_cards_bought_this_turn.duplicate()
	return c
