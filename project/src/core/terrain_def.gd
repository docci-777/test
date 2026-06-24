## 地形类型定义（数据对象）。
##
## 由 [DataLoader] 从 [param Paths.TERRAINS_FILE] 加载。
## 不可变数据对象，加载后不应修改。
class_name TerrainDef extends RefCounted

## 地形标识（如 "mountains"）
var id: String = ""
## 显示名称（如 "山脉"）
var display_name: String = ""
## 产出资源类型（沙漠/海洋为 INVALID，黄金为 INVALID 但 is_gold=true）
var resource: int = -1
## 基础版该地形数量
var count_base: int = 0
## 是否可建造建筑
var buildable: bool = true
## 强盗停留时是否压制产出
var robber_blocks: bool = true
## 类别："land" 或 "sea"
var category: String = "land"
## 所属扩展（空表示基础版）
var expansion: String = ""
## 是否可建船只（仅浅海为 true）
var ship_buildable: bool = false


## 从字典构造。
## [param id] 地形标识
## [param d] 原始字典数据
static func from_dict(id: String, d: Dictionary) -> TerrainDef:
	var t := TerrainDef.new()
	t.id = id
	t.display_name = String(d.get("name", id))
	var res_raw: Variant = d.get("resource", null)
	if res_raw == null or String(res_raw) == "any":
		t.resource = ResType.INVALID
	else:
		t.resource = ResType.from_name(String(res_raw))
	t.count_base = int(d.get("count_base", 0))
	t.buildable = bool(d.get("buildable", true))
	t.robber_blocks = bool(d.get("robber_blocks", true))
	t.category = String(d.get("category", "land"))
	t.expansion = String(d.get("expansion", ""))
	t.ship_buildable = bool(d.get("ship_buildable", false))
	return t


## 是否为黄金地形（产出任意资源）。
var is_gold: bool:
	get:
		return id == "gold"


## 是否为海洋地形。
var is_sea: bool:
	get:
		return category == "sea"
