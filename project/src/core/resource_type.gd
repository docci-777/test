## 资源类型枚举与工具方法。
##
## 定义基础版 5 种资源类型（见 GAME_RULES §1.1）。
## 海洋扩展不新增资源类型，黄金地形产出由玩家从现有 5 种中选择。
##
## 本类为枚举容器，不实例化。所有方法为静态。
## 注：命名为 ResType 以避免与 Godot 内置 ResourceType 冲突。
class_name ResType extends RefCounted

## 木材（森林产出）
const WOOD: int = 0
## 砖块（丘陵产出）
const BRICK: int = 1
## 羊毛（牧场产出）
const SHEEP: int = 2
## 麦子（麦田产出）
const WHEAT: int = 3
## 矿石（山脉产出）
const ORE: int = 4

## 无效类型标识
const INVALID: int = -1


## 返回全部资源类型列表。
static func all() -> Array:
	return [WOOD, BRICK, SHEEP, WHEAT, ORE]


## 查询资源类型的小写名称。
## [param t] 资源类型
## [return] 形如 "wood" 的名称；未知返回 "unknown"
static func name_of(t: int) -> String:
	match t:
		WOOD: return "wood"
		BRICK: return "brick"
		SHEEP: return "sheep"
		WHEAT: return "wheat"
		ORE: return "ore"
		_: return "unknown"


## 根据名称查询资源类型。
## [param name] 小写资源名称
## [return] 资源类型；未知返回 [member INVALID]
static func from_name(name: String) -> int:
	match name:
		"wood": return WOOD
		"brick": return BRICK
		"sheep": return SHEEP
		"wheat": return WHEAT
		"ore": return ORE
		_: return INVALID
