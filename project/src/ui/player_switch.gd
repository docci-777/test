## 热座玩家切换遮罩（P9-8）。
##
## 回合切换时全屏遮罩，隐藏棋盘信息，等待玩家确认后继续。
class_name PlayerSwitch extends CanvasLayer

signal confirmed()

var _label: Label
var _detail_label: Label
var _button: Button
var _bg: ColorRect


func _ready() -> void:
	layer = 50
	_build_ui()


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.05, 0.08, 0.97)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 36)
	vbox.add_child(_label)

	_detail_label = Label.new()
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.add_theme_font_size_override("font_size", 18)
	_detail_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(_detail_label)

	_button = Button.new()
	_button.text = "开始回合"
	_button.custom_minimum_size = Vector2(200, 50)
	_button.add_theme_font_size_override("font_size", 20)
	_button.pressed.connect(_on_confirm)
	vbox.add_child(_button)


## 显示玩家切换遮罩。
func show_switch(player: PlayerState, round_number: int, is_setup: bool) -> void:
	var color_name: String = ThemeColors.PLAYER_NAMES.get(player.color, player.color)
	var color_val: Color = ThemeColors.PLAYER_COLORS.get(player.color, Color.WHITE)
	_label.text = "%s 的回合" % color_name
	_label.add_theme_color_override("font_color", color_val)
	if is_setup:
		_detail_label.text = "初始放置阶段 · 第 %d 轮" % round_number
	else:
		_detail_label.text = "第 %d 回合" % round_number
	visible = true
	_button.grab_focus()


func _on_confirm() -> void:
	visible = false
	confirmed.emit()
