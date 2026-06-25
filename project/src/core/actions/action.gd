## 动作基类（命令模式）。
##
## 所有状态变更通过 Action 对象表达（见 ARCHITECTURE §3.2）。
## RulesEngine.validate(action, state) 纯校验；
## RulesEngine.apply(action, state) 执行并返回新状态 + 事件列表。
##
## 动作是不可变数据载体（创建后不应修改）。
class_name Action extends RefCounted

# ---- 动作类型 ----
## 掷骰子
const TYPE_ROLL_DICE: int = 0
## 建造（道路/定居点/城市/发展卡）
const TYPE_BUILD: int = 1
## 交易（银行/港口/玩家间）
const TYPE_TRADE: int = 2
## 使用发展卡
const TYPE_USE_DEV_CARD: int = 3
## 移动强盗
const TYPE_MOVE_ROBBER: int = 4
## 结束回合
const TYPE_END_TURN: int = 5
## 弃牌（7 点触发）
const TYPE_DISCARD: int = 6

## 动作类型
var action_type: int = TYPE_END_TURN
## 发起动作的玩家 ID
var player_id: int = -1


func _init(type: int = TYPE_END_TURN, pid: int = -1) -> void:
	action_type = type
	player_id = pid


# ---- 查询 ----

## 查询动作类型的常量名称。
static func type_name(type: int) -> String:
	match type:
		TYPE_ROLL_DICE: return "ROLL_DICE"
		TYPE_BUILD: return "BUILD"
		TYPE_TRADE: return "TRADE"
		TYPE_USE_DEV_CARD: return "USE_DEV_CARD"
		TYPE_MOVE_ROBBER: return "MOVE_ROBBER"
		TYPE_END_TURN: return "END_TURN"
		TYPE_DISCARD: return "DISCARD"
		_: return "UNKNOWN"
