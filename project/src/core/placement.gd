## 建筑放置记录。
##
## 记录某个顶点/边上的建筑归属与类型。
## 属于 Layer 1 核心层，纯数据。
class_name Placement extends RefCounted

## 所属玩家 ID
var player_id: int
## 建筑标识（"road"/"settlement"/"city"）
var building_id: String
## 位置 ID（vertex_id 或 edge_id）
var position_id: int


func _init(pid: int = -1, bid: String = "", pos_id: int = -1) -> void:
	player_id = pid
	building_id = bid
	position_id = pos_id


## 序列化为字典（用于 GameState.placements 深拷贝）。
func to_dict() -> Dictionary:
	return {
		"player_id": player_id,
		"building_id": building_id,
		"position_id": position_id,
	}


## 从字典反序列化。
static func from_dict(d: Dictionary) -> Placement:
	return Placement.new(int(d.get("player_id", -1)), \
		String(d.get("building_id", "")), int(d.get("position_id", -1)))
