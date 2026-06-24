## 建筑类型定义（数据对象）。
##
## 由 [DataLoader] 从 [param Paths.BUILDINGS_FILE] 加载。
## 包含道路/船只/定居点/城市/发展卡购买的定义。
class_name BuildingDef extends RefCounted

## 建筑标识（如 "road"、"settlement"）
var id: String = ""
## 显示名称
var display_name: String = ""
## 建造成本（ResourceSet）
var cost: ResourceSet
## 胜利点数
var victory_points: int = 0
## 位置类型："vertex"（顶点）、"edge"（边）、"none"（无位置，如发展卡）
var position_type: String = "none"
## 适合的地形类别："land"、"sea"、"none"
var terrain_category: String = "none"
## 每位玩家上限（-1 表示无限制）
var max_per_player: int = -1
## 所属扩展（空表示基础版）
var expansion: String = ""
## 产出倍率（定居点 1，城市 2）
var production_multiplier: int = 0
## 升级来源（城市从定居点升级）
var upgrades_from: String = ""
## 是否可移动（船只）
var movable: bool = false


func _init() -> void:
	cost = ResourceSet.new()


## 从字典构造。
static func from_dict(id: String, d: Dictionary) -> BuildingDef:
	var b := BuildingDef.new()
	b.id = id
	b.display_name = String(d.get("name", id))
	var cost_dict: Dictionary = d.get("cost", {})
	b.cost = ResourceSet.from_dict(cost_dict)
	b.victory_points = int(d.get("victory_points", 0))
	b.position_type = String(d.get("position_type", "none"))
	b.terrain_category = String(d.get("terrain_category", "none"))
	b.max_per_player = int(d.get("max_per_player", -1))
	b.expansion = String(d.get("expansion", ""))
	b.production_multiplier = int(d.get("production_multiplier", 0))
	b.upgrades_from = String(d.get("upgrades_from", ""))
	b.movable = bool(d.get("movable", false))
	return b


## 是否为升级型建筑（如城市升级自定居点）。
var is_upgrade: bool:
	get:
		return upgrades_from != ""
