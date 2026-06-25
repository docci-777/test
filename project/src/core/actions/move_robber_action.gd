## 移动强盗动作。
##
## 7 点掷骰或使用骑士卡后触发。
## 见 GAME_RULES §8.2。
class_name MoveRobberAction extends Action

## 强盗移动到的目标六边形 ID
var target_hex_id: int = -1
## 被偷取资源的玩家 ID（-1 表示不偷取）
var target_player_id: int = -1


func _init(pid: int = -1, hex_id: int = -1, target_pid: int = -1) -> void:
	super._init(Action.TYPE_MOVE_ROBBER, pid)
	target_hex_id = hex_id
	target_player_id = target_pid
