## 掷骰动作。
##
## 在 ROLL 阶段执行，产出 DICE_ROLLED 事件。
## 见 GAME_RULES §5。
class_name RollDiceAction extends Action


func _init(pid: int = -1) -> void:
	super._init(Action.TYPE_ROLL_DICE, pid)
