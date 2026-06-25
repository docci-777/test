## 事件（Event）。
##
## Layer 1 核心层，表示状态变更的不可变记录。
## RulesEngine.apply 产出事件列表，供 Layer 2 事件总线分发。
##
## 事件类型对照 GAME_RULES 各章节。
class_name Event extends RefCounted

# ---- 事件类型 ----
## 回合开始
const TYPE_TURN_STARTED: int = 0
## 回合结束
const TYPE_TURN_ENDED: int = 1
## 阶段切换
const TYPE_PHASE_CHANGED: int = 2
## 掷骰
const TYPE_DICE_ROLLED: int = 3
## 资源产出
const TYPE_RESOURCE_PRODUCED: int = 4
## 建筑建成
const TYPE_BUILDING_BUILT: int = 5
## 道路建成
const TYPE_ROAD_BUILT: int = 6
## 交易完成
const TYPE_TRADE_COMPLETED: int = 7
## 强盗移动
const TYPE_ROBBER_MOVED: int = 8
## 发展卡使用
const TYPE_DEV_CARD_USED: int = 9
## 资源被偷
const TYPE_RESOURCE_STOLEN: int = 10
## 弃牌
const TYPE_CARDS_DISCARDED: int = 11
## 游戏结束
const TYPE_GAME_OVER: int = 12

## 事件类型
var event_type: int
## 触发玩家 ID
var player_id: int
## 事件载荷
var payload: Dictionary = {}


func _init(type: int = TYPE_TURN_STARTED, pid: int = -1) -> void:
	event_type = type
	player_id = pid


## 设置载荷字段。
func set_payload(key: String, value: Variant) -> Event:
	payload[key] = value
	return self


## 获取载荷字段（不存在返回 null）。
func get_payload(key: String) -> Variant:
	return payload.get(key, null)


## 事件类型名称（调试用）。
static func type_name(type: int) -> String:
	match type:
		TYPE_TURN_STARTED: return "TURN_STARTED"
		TYPE_TURN_ENDED: return "TURN_ENDED"
		TYPE_PHASE_CHANGED: return "PHASE_CHANGED"
		TYPE_DICE_ROLLED: return "DICE_ROLLED"
		TYPE_RESOURCE_PRODUCED: return "RESOURCE_PRODUCED"
		TYPE_BUILDING_BUILT: return "BUILDING_BUILT"
		TYPE_ROAD_BUILT: return "ROAD_BUILT"
		TYPE_TRADE_COMPLETED: return "TRADE_COMPLETED"
		TYPE_ROBBER_MOVED: return "ROBBER_MOVED"
		TYPE_DEV_CARD_USED: return "DEV_CARD_USED"
		TYPE_RESOURCE_STOLEN: return "RESOURCE_STOLEN"
		TYPE_CARDS_DISCARDED: return "CARDS_DISCARDED"
		TYPE_GAME_OVER: return "GAME_OVER"
		_: return "UNKNOWN"


# ---- 工厂方法 ----

## 创建"回合开始"事件。
static func create_turn_started(pid: int, round_number: int) -> Event:
	return Event.new(TYPE_TURN_STARTED, pid) \
		.set_payload("round_number", round_number)


## 创建"回合结束"事件。
static func create_turn_ended(pid: int) -> Event:
	return Event.new(TYPE_TURN_ENDED, pid)


## 创建"阶段切换"事件。
static func create_phase_changed(pid: int, old_phase: int, new_phase: int) -> Event:
	return Event.new(TYPE_PHASE_CHANGED, pid) \
		.set_payload("old_phase", old_phase) \
		.set_payload("new_phase", new_phase)


## 创建"掷骰"事件。
static func create_dice_rolled(pid: int, die1: int, die2: int) -> Event:
	return Event.new(TYPE_DICE_ROLLED, pid) \
		.set_payload("die1", die1) \
		.set_payload("die2", die2) \
		.set_payload("total", die1 + die2)


## 创建"资源产出"事件。
static func create_resource_produced(pid: int, resource: int, amount: int) -> Event:
	return Event.new(TYPE_RESOURCE_PRODUCED, pid) \
		.set_payload("resource", resource) \
		.set_payload("amount", amount)


## 创建"建筑建成"事件。
static func create_building_built(pid: int, building_id: String, position_id: int) -> Event:
	return Event.new(TYPE_BUILDING_BUILT, pid) \
		.set_payload("building_id", building_id) \
		.set_payload("position_id", position_id)


## 创建"道路建成"事件。
static func create_road_built(pid: int, position_id: int) -> Event:
	return Event.new(TYPE_ROAD_BUILT, pid) \
		.set_payload("position_id", position_id)


## 创建"交易完成"事件。
static func create_trade_completed(pid: int, trade_type: String, \
		give: ResourceSet = null, receive: ResourceSet = null) -> Event:
	var e := Event.new(TYPE_TRADE_COMPLETED, pid) \
		.set_payload("trade_type", trade_type)
	if give != null:
		e.set_payload("give", give.to_dict())
	if receive != null:
		e.set_payload("receive", receive.to_dict())
	return e


## 创建"强盗移动"事件。
static func create_robber_moved(pid: int, old_hex_id: int, new_hex_id: int) -> Event:
	return Event.new(TYPE_ROBBER_MOVED, pid) \
		.set_payload("old_hex_id", old_hex_id) \
		.set_payload("new_hex_id", new_hex_id)


## 创建"发展卡使用"事件。
static func create_dev_card_used(pid: int, card_id: String) -> Event:
	return Event.new(TYPE_DEV_CARD_USED, pid) \
		.set_payload("card_id", card_id)


## 创建"资源被偷"事件。
static func create_resource_stolen(thief_id: int, victim_id: int, resource: int) -> Event:
	return Event.new(TYPE_RESOURCE_STOLEN, thief_id) \
		.set_payload("victim_id", victim_id) \
		.set_payload("resource", resource)


## 创建"弃牌"事件。
static func create_cards_discarded(pid: int, discarded: ResourceSet) -> Event:
	return Event.new(TYPE_CARDS_DISCARDED, pid) \
		.set_payload("discarded", discarded.to_dict())


## 创建"游戏结束"事件。
static func create_game_over(winner_id: int) -> Event:
	return Event.new(TYPE_GAME_OVER, winner_id) \
		.set_payload("winner_id", winner_id)
