## 操作结果容器。
##
## Layer 1 核心层统一返回类型，避免抛异常。
## 成功时 [member ok] 为 true，[member value] 携带结果；
## 失败时 [member ok] 为 false，[member error_code] 与 [member error_message] 描述原因。
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
