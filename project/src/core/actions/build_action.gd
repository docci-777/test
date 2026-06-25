## 建造动作。
##
## 建造道路/定居点/城市/购买发展卡。
## 见 GAME_RULES §7。
class_name BuildAction extends Action

## 建筑标识（"road"/"settlement"/"city"/"dev_card"）
var building_id: String = ""
## 位置 ID（vertex_id 或 edge_id，dev_card 为 -1）
var position_id: int = -1


func _init(pid: int = -1, bid: String = "", pos_id: int = -1) -> void:
	super._init(Action.TYPE_BUILD, pid)
	building_id = bid
	position_id = pos_id
