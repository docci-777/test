## 发展卡类型定义（数据对象）。
##
## 由 [DataLoader] 从 [param Paths.DEV_CARDS_FILE] 加载。
## 定义 5 种发展卡：骑士、胜利点、道路建设、发明、垄断（见 GAME_RULES §9）。
class_name DevCardDef extends RefCounted

## 卡牌标识（如 "knight"）
var id: String = ""
## 显示名称
var display_name: String = ""
## 牌堆中数量
var count: int = 0
## 胜利点数（仅胜利点卡为 1）
var victory_points: int = 0
## 购买当回合是否可使用（胜利点卡为 true，其余为 false）
var usable_same_turn: bool = false
## 效果标识（如 "move_robber_and_steal"）
var effect: String = ""
## 是否隐藏（胜利点卡在达到胜利前不公开）
var hidden: bool = false
## 是否计入最大军队判定（仅骑士为 true）
var counts_for_largest_army: bool = false


## 从字典构造。
static func from_dict(id: String, d: Dictionary) -> DevCardDef:
	var c := DevCardDef.new()
	c.id = id
	c.display_name = String(d.get("name", id))
	c.count = int(d.get("count", 0))
	c.victory_points = int(d.get("victory_points", 0))
	c.usable_same_turn = bool(d.get("usable_same_turn", false))
	c.effect = String(d.get("effect", ""))
	c.hidden = bool(d.get("hidden", false))
	c.counts_for_largest_army = bool(d.get("counts_for_largest_army", false))
	return c
