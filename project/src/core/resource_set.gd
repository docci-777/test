## 资源数量集合。
##
## 表示一组资源及其数量（如玩家手牌、建筑成本、交易报价）。
## 所有数量非负，负值自动钳制为 0。
##
## 不可变原则：本类为可变容器，但提供 [method clone] 用于创建独立副本。
## Layer 1 状态变更时优先 clone 后修改，避免共享引用（见 ARCHITECTURE §3.3）。
class_name ResourceSet extends RefCounted

var _amounts: Dictionary = {} # int (ResType) -> int


func _init() -> void:
	for t in ResType.all():
		_amounts[t] = 0


## 获取指定资源的数量。
func get_amount(t: int) -> int:
	return _amounts.get(t, 0)


## 设置指定资源的数量（负值钳制为 0）。
func set_amount(t: int, amount: int) -> void:
	_amounts[t] = maxi(amount, 0)


## 增加指定资源数量。
func add(t: int, amount: int) -> void:
	set_amount(t, get_amount(t) + amount)


## 减少指定资源数量（不低于 0）。
func subtract(t: int, amount: int) -> void:
	set_amount(t, get_amount(t) - amount)


## 资源总数。
func total() -> int:
	var sum: int = 0
	for t in _amounts.keys():
		sum += _amounts[t]
	return sum


## 判断本集合是否覆盖（≥）另一集合的所有资源数量。
## [param other] 需求集合
## [return] true 表示本集合每种资源都 ≥ other 对应数量
func covers(other: ResourceSet) -> bool:
	for t in ResType.all():
		if get_amount(t) < other.get_amount(t):
			return false
	return true


## 合并另一集合到本集合（逐项相加）。
func add_set(other: ResourceSet) -> void:
	for t in ResType.all():
		add(t, other.get_amount(t))


## 从本集合减去另一集合（逐项相减，不低于 0）。
func subtract_set(other: ResourceSet) -> void:
	for t in ResType.all():
		subtract(t, other.get_amount(t))


## 创建独立副本。
func clone() -> ResourceSet:
	var c := ResourceSet.new()
	for t in ResType.all():
		c.set_amount(t, get_amount(t))
	return c


## 序列化为字典（资源名 -> 数量），包含全部 5 种资源。
func to_dict() -> Dictionary:
	var d: Dictionary = {}
	for t in ResType.all():
		d[ResType.name_of(t)] = get_amount(t)
	return d


## 从字典加载（资源名 -> 数量），忽略未知键。
static func from_dict(d: Dictionary) -> ResourceSet:
	var rs := ResourceSet.new()
	for key in d.keys():
		var t: int = ResType.from_name(String(key))
		if t != ResType.INVALID:
			rs.set_amount(t, int(d[key]))
	return rs
