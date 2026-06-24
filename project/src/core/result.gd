## 操作结果容器。
##
## Layer 1 核心层统一返回类型，避免抛异常。
## 成功时 [member ok] 为 true，[member value] 携带结果；
## 失败时 [member ok] 为 false，[member error_code] 与 [member error_message] 描述原因。
##
## 错误码分两类：
## - 通用错误码（ERR_UNKNOWN ~ ERR_INVALID_STATE）：基础设施层错误
## - 规则错误码（ERR_NOT_YOUR_TURN 起）：游戏规则违反，可通过 [method is_rule_error] 判定
##
## 用法：
##   [codeblock]
##   var r := Result.success(42)
##   if not r.ok:
##       push_error(r.error_message)
##       return
##   print(r.value)
##   [/codeblock]
class_name Result extends RefCounted

# ---- 通用错误码 ----
## 通用错误码：未知错误
const ERR_UNKNOWN: int = 1
## 通用错误码：参数非法
const ERR_INVALID_ARG: int = 2
## 通用错误码：资源未找到
const ERR_NOT_FOUND: int = 3
## 通用错误码：格式/解析错误
const ERR_PARSE: int = 4
## 通用错误码：状态非法（动作在当前状态不可执行）
const ERR_INVALID_STATE: int = 5

# ---- 回合流程错误码 ----
## 规则错误：不是该玩家的回合
const ERR_NOT_YOUR_TURN: int = 100
## 规则错误：当前阶段不可执行该动作
const ERR_INVALID_PHASE: int = 101
## 规则错误：游戏已结束
const ERR_GAME_OVER: int = 102

# ---- 资源错误码 ----
## 规则错误：资源不足，无法支付
const ERR_INSUFFICIENT_RESOURCES: int = 200
## 规则错误：银行该资源已耗尽
const ERR_BANK_EMPTY: int = 201

# ---- 建造位置错误码 ----
## 规则错误：位置非法（不存在或不可建造）
const ERR_INVALID_POSITION: int = 300
## 规则错误：违反定居点距离规则（需 ≥2 边）
const ERR_DISTANCE_RULE_VIOLATED: int = 301
## 规则错误：未连接到己方道路网络
const ERR_NOT_CONNECTED: int = 302
## 规则错误：位置已被占用
const ERR_POSITION_OCCUPIED: int = 303
## 规则错误：目标不属于该玩家
const ERR_NOT_OWNED: int = 304

# ---- 强盗错误码 ----
## 规则错误：需先移动强盗
const ERR_ROBBER_REQUIRED: int = 400
## 规则错误：强盗不能停留在原六边形
const ERR_ROBBER_SAME_HEX: int = 401

# ---- 发展卡错误码 ----
## 规则错误：发展卡当前不可使用（如购买当回合）
const ERR_CARD_NOT_USABLE: int = 500
## 规则错误：本回合已使用过发展卡
const ERR_DEV_CARD_ALREADY_USED: int = 501
## 规则错误：玩家未持有该发展卡
const ERR_CARD_NOT_FOUND: int = 502

# ---- 交易错误码 ----
## 规则错误：交易被拒绝
const ERR_TRADE_REJECTED: int = 600
## 规则错误：未拥有对应港口
const ERR_PORT_NOT_OWNED: int = 601

## 规则错误码起始值（≥此值即为规则错误）
const _RULE_ERROR_BASE: int = 100

## 是否成功
var ok: bool = false
## 成功时携带的返回值
var value: Variant = null
## 失败时的错误码（见 ERR_* 常量）
var error_code: int = 0
## 失败时的人类可读描述
var error_message: String = ""


## 构造成功结果。
## [param v] 携带的返回值，默认 null
static func success(v: Variant = null) -> Result:
	var r := Result.new()
	r.ok = true
	r.value = v
	return r


## 构造失败结果。
## [param code] 错误码（见 ERR_* 常量）
## [param msg] 人类可读描述
static func failure(code: int, msg: String = "") -> Result:
	var r := Result.new()
	r.ok = false
	r.error_code = code
	r.error_message = msg
	return r


## 便捷断言：若失败则断言失败（仅用于测试）。
func assert_ok() -> Result:
	assert(ok, "Expected success but got error %d: %s" % [error_code, error_message])
	return self


## 判断错误码是否为规则错误（游戏规则违反）。
## [param code] 错误码
## [return] true 表示规则错误，false 表示通用错误或无效码
static func is_rule_error(code: int) -> bool:
	return code >= _RULE_ERROR_BASE


## 查询错误码的常量名称。
## [param code] 错误码
## [return] 形如 "ERR_NOT_FOUND" 的名称；未知码返回 "UNKNOWN"
static func error_name(code: int) -> String:
	match code:
		ERR_UNKNOWN: return "ERR_UNKNOWN"
		ERR_INVALID_ARG: return "ERR_INVALID_ARG"
		ERR_NOT_FOUND: return "ERR_NOT_FOUND"
		ERR_PARSE: return "ERR_PARSE"
		ERR_INVALID_STATE: return "ERR_INVALID_STATE"
		ERR_NOT_YOUR_TURN: return "ERR_NOT_YOUR_TURN"
		ERR_INVALID_PHASE: return "ERR_INVALID_PHASE"
		ERR_GAME_OVER: return "ERR_GAME_OVER"
		ERR_INSUFFICIENT_RESOURCES: return "ERR_INSUFFICIENT_RESOURCES"
		ERR_BANK_EMPTY: return "ERR_BANK_EMPTY"
		ERR_INVALID_POSITION: return "ERR_INVALID_POSITION"
		ERR_DISTANCE_RULE_VIOLATED: return "ERR_DISTANCE_RULE_VIOLATED"
		ERR_NOT_CONNECTED: return "ERR_NOT_CONNECTED"
		ERR_POSITION_OCCUPIED: return "ERR_POSITION_OCCUPIED"
		ERR_NOT_OWNED: return "ERR_NOT_OWNED"
		ERR_ROBBER_REQUIRED: return "ERR_ROBBER_REQUIRED"
		ERR_ROBBER_SAME_HEX: return "ERR_ROBBER_SAME_HEX"
		ERR_CARD_NOT_USABLE: return "ERR_CARD_NOT_USABLE"
		ERR_DEV_CARD_ALREADY_USED: return "ERR_DEV_CARD_ALREADY_USED"
		ERR_CARD_NOT_FOUND: return "ERR_CARD_NOT_FOUND"
		ERR_TRADE_REJECTED: return "ERR_TRADE_REJECTED"
		ERR_PORT_NOT_OWNED: return "ERR_PORT_NOT_OWNED"
		_: return "UNKNOWN"
