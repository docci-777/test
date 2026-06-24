## 港口类型定义（数据对象）。
##
## 由 [DataLoader] 从 [param Paths.PORTS_FILE] 加载。
## 定义 4 个 3:1 通用港口 + 5 个 2:1 专项港口（见 GAME_RULES §1.1、§6.3）。
class_name PortDef extends RefCounted

## 港口标识（如 "generic_3to1"、"wood_2to1"）
var id: String = ""
## 显示名称
var display_name: String = ""
## 交易比例字符串（如 "3:1"）
var trade_ratio: String = ""
## 给出的资源数量
var give_count: int = 3
## 收到的资源数量
var receive_count: int = 1
## 专项港口对应的资源（通用港口为 INVALID）
var resource: int = -1
## 基础版该港口数量
var count_base: int = 0


## 从字典构造。
static func from_dict(id: String, d: Dictionary) -> PortDef:
	var p := PortDef.new()
	p.id = id
	p.display_name = String(d.get("name", id))
	p.trade_ratio = String(d.get("trade_ratio", ""))
	p.give_count = int(d.get("give_count", 3))
	p.receive_count = int(d.get("receive_count", 1))
	var res_raw: Variant = d.get("resource", null)
	if res_raw == null:
		p.resource = ResType.INVALID
	else:
		p.resource = ResType.from_name(String(res_raw))
	p.count_base = int(d.get("count_base", 0))
	return p


## 是否为专项港口（2:1）。
var is_specialized: bool:
	get:
		return resource != ResType.INVALID
