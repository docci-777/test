## 胜利结算界面（P9-7）。
##
## 游戏结束时显示获胜者与最终得分。
class_name VictoryScreen extends CanvasLayer

signal restart_requested()

var _bg: ColorRect
var _title: Label
var _scores_container: VBoxContainer
var _button: Button


func _ready() -> void:
	layer = 60
	_build_ui()
	visible = false


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.05, 0.08, 0.98)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(500, 0)
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 42)
	vbox.add_child(_title)

	_scores_container = VBoxContainer.new()
	_scores_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_scores_container.add_theme_constant_override("separation", 8)
	vbox.add_child(_scores_container)

	_button = Button.new()
	_button.text = "再来一局"
	_button.custom_minimum_size = Vector2(200, 50)
	_button.add_theme_font_size_override("font_size", 20)
	_button.pressed.connect(_on_restart)
	vbox.add_child(_button)


## 显示胜利结算。
func show_victory(winner: PlayerState, all_players: Array) -> void:
	var color_name: String = ThemeColors.PLAYER_NAMES.get(winner.color, winner.color)
	var color_val: Color = ThemeColors.PLAYER_COLORS.get(winner.color, Color.WHITE)
	_title.text = "🏆 %s 获胜！" % color_name
	_title.add_theme_color_override("font_color", color_val)

	# 清除旧分数
	for child in _scores_container.get_children():
		child.queue_free()

	# 按分数排序
	var sorted := all_players.duplicate()
	sorted.sort_custom(func(a, b): return a.total_victory_points() > b.total_victory_points())

	for p in sorted:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var name_lbl := Label.new()
		name_lbl.text = ThemeColors.PLAYER_NAMES.get(p.color, p.color)
		name_lbl.add_theme_color_override("font_color", ThemeColors.PLAYER_COLORS.get(p.color, Color.WHITE))
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.custom_minimum_size = Vector2(100, 0)
		row.add_child(name_lbl)

		var vp_lbl := Label.new()
		vp_lbl.text = "%d VP" % p.total_victory_points()
		vp_lbl.add_theme_font_size_override("font_size", 22)
		vp_lbl.add_theme_color_override("font_color", ThemeColors.TEXT_COLOR)
		row.add_child(vp_lbl)

		var detail := Label.new()
		var details: Array = []
		details.append("定居点 %d" % p.count_building("settlement"))
		details.append("城市 %d" % p.count_building("city"))
		details.append("道路 %d" % p.count_building("road"))
		if p.has_longest_road:
			details.append("最长道路")
		if p.has_largest_army:
			details.append("最大军队")
		if p.hidden_victory_points > 0:
			details.append("VP卡 %d" % p.hidden_victory_points)
		detail.text = "  ".join(details)
		detail.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
		detail.add_theme_font_size_override("font_size", 16)
		row.add_child(detail)

		_scores_container.add_child(row)

	visible = true
	_button.grab_focus()


func _on_restart() -> void:
	visible = false
	restart_requested.emit()
