## 使用发展卡动作。
##
## 见 GAME_RULES §9。
class_name UseDevCardAction extends Action

## 卡牌标识（"knight"/"victory_point"/"road_building"/"year_of_plenty"/"monopoly"）
var card_id: String = ""
## 发明卡指定的第 1 种资源（仅 year_of_plenty 用）
var year_of_plenty_res1: int = ResType.INVALID
## 发明卡指定的第 2 种资源（仅 year_of_plenty 用）
var year_of_plenty_res2: int = ResType.INVALID
## 垄断卡指定的资源（仅 monopoly 用）
var monopoly_resource: int = ResType.INVALID
## 道路建设卡的第 1 条道路边 ID（仅 road_building 用）
var road_building_edge1: int = -1
## 道路建设卡的第 2 条道路边 ID（仅 road_building 用）
var road_building_edge2: int = -1


func _init(pid: int = -1, cid: String = "") -> void:
	super._init(Action.TYPE_USE_DEV_CARD, pid)
	card_id = cid
