## 结束回合动作。
##
## 在 ACTION 阶段执行，推进到下一位玩家的 ROLL 阶段。
class_name EndTurnAction extends Action


func _init(pid: int = -1) -> void:
	super._init(Action.TYPE_END_TURN, pid)
