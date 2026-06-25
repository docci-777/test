## 弃牌动作。
##
## 7 点掷骰触发，手牌 >7 张的玩家须弃一半（向下取整）。
## 见 GAME_RULES §8.2 第 1 步。
class_name DiscardAction extends Action

## 弃掉的资源集合
var discard_set: ResourceSet


func _init(pid: int = -1, ds: ResourceSet = null) -> void:
	super._init(Action.TYPE_DISCARD, pid)
	if ds == null:
		discard_set = ResourceSet.new()
	else:
		discard_set = ds
