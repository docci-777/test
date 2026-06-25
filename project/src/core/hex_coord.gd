## 六边形坐标（轴向坐标 axial coordinates）。
##
## 使用 (q, r) 轴向坐标表示六边形位置，s = -q - r。
## 适用于 pointy-top 布局（见 ARCHITECTURE §3.1）。
##
## 不可变值对象：创建后不应修改 q/r。
class_name HexCoord extends RefCounted

## 轴向坐标 q（列）
var q: int
## 轴向坐标 r（行）
var r: int


func _init(q_val: int = 0, r_val: int = 0) -> void:
	q = q_val
	r = r_val


## 第三坐标 s = -q - r。
func s() -> int:
	return -q - r


## 6 个邻居方向（pointy-top）。
const DIRECTIONS: Array = [
	{q = 1, r = 0},   # 东
	{q = 1, r = -1},  # 东北
	{q = 0, r = -1},  # 西北
	{q = -1, r = 0},  # 西
	{q = -1, r = 1},  # 西南
	{q = 0, r = 1},   # 东南
]


## 是否与另一坐标相等。
func equals(other: HexCoord) -> bool:
	return q == other.q and r == other.r


## 坐标键（用于字典索引）。
func to_key() -> String:
	return "%d,%d" % [q, r]


## 创建副本。
func clone() -> HexCoord:
	return HexCoord.new(q, r)


## 像素坐标（pointy-top，size=1）。
## x = sqrt(3) * (q + r/2)
## y = 1.5 * r
func to_pixel() -> Vector2:
	var x: float = sqrt(3.0) * (float(q) + float(r) / 2.0)
	var y: float = 1.5 * float(r)
	return Vector2(x, y)


## 像素距离（用于渲染排序）。
func distance_to(other: HexCoord) -> int:
	return (abs(q - other.q) + abs(q + r - other.q - other.r) + abs(r - other.r)) / 2
