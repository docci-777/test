## 交易对话框（P9-4）。
##
## 支持银行 4:1 交易、港口 3:1/2:1 交易、玩家间交易。
## 玩家选择给出的资源与数量，选择想接收的资源，确认后提交。
class_name TradeDialog extends CanvasLayer

signal trade_confirmed(action: TradeAction)
signal trade_cancelled()

# ---- 状态 ----
var _state: GameState
var _player: PlayerState

# 交易类型选择
var _trade_type: int = TradeAction.TRADE_BANK
var _port_vertex_id: int = -1

# 给出资源
var _give_amounts: Dictionary = {}  # res_type -> int

# 接收资源
var _receive_type: int = ResType.INVALID

# UI 节点
var _bg: ColorRect
var _panel: Panel
var _give_labels: Dictionary = {}  # res_type -> Label
var _recv_buttons: Dictionary = {}  # res_type -> Button
var _info_label: Label
var _confirm_btn: Button


func _ready() -> void:
	layer = 40
	_build_ui()
	visible = false


## 显示交易对话框。
func show_dialog(state: GameState) -> void:
	_state = state
	_player = state.current_player()
	_give_amounts.clear()
	for t in ResType.all():
		_give_amounts[t] = 0
	_receive_type = ResType.INVALID
	_trade_type = TradeAction.TRADE_BANK
	_port_vertex_id = -1
	_refresh_ui()
	visible = true


func hide_dialog() -> void:
	visible = false


# ---- UI 构建 ----

func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0, 0, 0, 0.6)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_cancel()
	)
	add_child(_bg)

	_panel = Panel.new()
	_panel.position = Vector2(290, 120)
	_panel.size = Vector2(700, 480)
	_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(20, 20)
	vbox.size = Vector2(660, 440)
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	# 标题
	var title := Label.new()
	title.text = "交易"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# 交易类型选择
	var type_hbox := HBoxContainer.new()
	type_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(type_hbox)

	for tt in [[TradeAction.TRADE_BANK, "银行 4:1"], [TradeAction.TRADE_PORT, "港口"], [TradeAction.TRADE_PLAYER, "玩家间"]]:
		var btn := Button.new()
		btn.text = tt[1]
		btn.toggle_mode = true
		btn.add_theme_font_size_override("font_size", 14)
		var captured: int = tt[0]
		btn.pressed.connect(func(): _select_trade_type(captured))
		type_hbox.add_child(btn)

	# 信息标签
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 14)
	_info_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(_info_label)

	# 给出资源区域
	var give_label := Label.new()
	give_label.text = "给出资源："
	give_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(give_label)

	var give_grid := GridContainer.new()
	give_grid.columns = 5
	give_grid.add_theme_constant_override("h_separation", 12)
	give_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(give_grid)

	for t in ResType.all():
		var cell := _make_give_cell(t)
		give_grid.add_child(cell)

	# 接收资源区域
	var recv_label := Label.new()
	recv_label.text = "接收资源："
	recv_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(recv_label)

	var recv_grid := GridContainer.new()
	recv_grid.columns = 5
	recv_grid.add_theme_constant_override("h_separation", 12)
	recv_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(recv_grid)

	for t in ResType.all():
		var btn := Button.new()
		btn.text = "%s %s" % [ThemeColors.RESOURCE_ICONS.get(t, ""), ThemeColors.RESOURCE_NAMES.get(t, "")]
		btn.add_theme_font_size_override("font_size", 14)
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(110, 40)
		var captured: int = t
		btn.pressed.connect(func(): _select_receive(captured))
		recv_grid.add_child(btn)
		_recv_buttons[t] = btn

	# 按钮行
	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(btn_hbox)

	var cancel_btn := Button.new()
	cancel_btn.text = "取消"
	cancel_btn.custom_minimum_size = Vector2(120, 44)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.pressed.connect(_cancel)
	btn_hbox.add_child(cancel_btn)

	_confirm_btn = Button.new()
	_confirm_btn.text = "确认交易"
	_confirm_btn.custom_minimum_size = Vector2(120, 44)
	_confirm_btn.add_theme_font_size_override("font_size", 18)
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_confirm)
	btn_hbox.add_child(_confirm_btn)


func _make_give_cell(res_type: int) -> VBoxContainer:
	var cell := VBoxContainer.new()
	cell.alignment = BoxContainer.ALIGNMENT_CENTER

	var name_lbl := Label.new()
	name_lbl.text = "%s %s" % [ThemeColors.RESOURCE_ICONS.get(res_type, ""), ThemeColors.RESOURCE_NAMES.get(res_type, "")]
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(name_lbl)

	var amount_lbl := Label.new()
	amount_lbl.text = "0"
	amount_lbl.add_theme_font_size_override("font_size", 22)
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cell.add_child(amount_lbl)
	_give_labels[res_type] = amount_lbl

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 4)
	cell.add_child(btn_hbox)

	var minus_btn := Button.new()
	minus_btn.text = "-"
	minus_btn.custom_minimum_size = Vector2(30, 30)
	var captured_m: int = res_type
	minus_btn.pressed.connect(func(): _adjust_give(captured_m, -1))
	btn_hbox.add_child(minus_btn)

	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(30, 30)
	var captured_p: int = res_type
	plus_btn.pressed.connect(func(): _adjust_give(captured_p, 1))
	btn_hbox.add_child(plus_btn)

	return cell


# ---- 交互 ----

func _select_trade_type(tt: int) -> void:
	_trade_type = tt
	_give_amounts.clear()
	for t in ResType.all():
		_give_amounts[t] = 0
	_receive_type = ResType.INVALID
	_port_vertex_id = -1

	# 如果选择港口，自动找到玩家可用的港口
	if tt == TradeAction.TRADE_PORT:
		_find_available_port()

	_refresh_ui()


func _find_available_port() -> void:
	if _state == null or _player == null:
		return
	# 查找玩家在港口顶点有定居点/城市的
	for vid in _state.board.all_port_vertices():
		var placement: Placement = _state.placements.get("v:%d" % vid)
		if placement != null and placement.player_id == _player.player_id:
			if placement.building_id == "settlement" or placement.building_id == "city":
				_port_vertex_id = vid
				return


func _adjust_give(res_type: int, delta: int) -> void:
	var current: int = _give_amounts.get(res_type, 0)
	var max_amount: int = _player.resources.get_amount(res_type) if _player != null else 0
	_give_amounts[res_type] = clampi(current + delta, 0, max_amount)
	_refresh_ui()


func _select_receive(res_type: int) -> void:
	_receive_type = res_type
	_refresh_ui()


func _refresh_ui() -> void:
	# 更新给出数量
	for t in ResType.all():
		var lbl: Label = _give_labels.get(t)
		if lbl:
			lbl.text = str(_give_amounts.get(t, 0))

	# 更新接收按钮
	for t in ResType.all():
		var btn: Button = _recv_buttons.get(t)
		if btn:
			btn.button_pressed = (t == _receive_type)

	# 信息标签
	match _trade_type:
		TradeAction.TRADE_BANK:
			_info_label.text = "银行交易：4 张相同资源换 1 张任意资源"
		TradeAction.TRADE_PORT:
			if _port_vertex_id < 0:
				_info_label.text = "你没有可用的港口（需在港口位置建有定居点/城市）"
			else:
				var port_id: String = _state.board.get_port(_port_vertex_id)
				var pdef: PortDef = _state.ports.get(port_id)
				if pdef != null:
					if pdef.is_specialized:
						_info_label.text = "%s：%d 张 %s 换 1 张任意" % [pdef.display_name, pdef.give_count, ThemeColors.RESOURCE_NAMES.get(pdef.resource, "?")]
					else:
						_info_label.text = "%s：%d 张相同资源换 1 张任意" % [pdef.display_name, pdef.give_count]
		TradeAction.TRADE_PLAYER:
			_info_label.text = "玩家间交易：与指定玩家交换资源"

	# 确认按钮状态
	_confirm_btn.disabled = not _is_trade_valid()


func _is_trade_valid() -> bool:
	if _receive_type == ResType.INVALID:
		return false
	if _trade_type == TradeAction.TRADE_BANK:
		# 银行交易：必须给出 4 张相同资源
		for t in ResType.all():
			if _give_amounts.get(t, 0) >= 4:
				return true
		return false
	elif _trade_type == TradeAction.TRADE_PORT:
		if _port_vertex_id < 0:
			return false
		var port_id: String = _state.board.get_port(_port_vertex_id)
		var pdef: PortDef = _state.ports.get(port_id)
		if pdef == null:
			return false
		# 专项港口：必须给出指定资源
		if pdef.is_specialized:
			return _give_amounts.get(pdef.resource, 0) >= pdef.give_count
		# 通用港口：任意相同资源
		for t in ResType.all():
			if _give_amounts.get(t, 0) >= pdef.give_count:
				return true
		return false
	elif _trade_type == TradeAction.TRADE_PLAYER:
		# 玩家间：至少给出 1 张
		var total: int = 0
		for t in ResType.all():
			total += _give_amounts.get(t, 0)
		return total > 0
	return false


func _confirm() -> void:
	var action: TradeAction
	var give_set := ResourceSet.new()
	for t in ResType.all():
		give_set.set_amount(t, _give_amounts.get(t, 0))

	match _trade_type:
		TradeAction.TRADE_BANK:
			# 银行交易只取第一种达到 4 张的资源
			for t in ResType.all():
				if _give_amounts.get(t, 0) >= 4:
					var single_give := ResourceSet.new()
					single_give.set_amount(t, 4)
					action = TradeAction.new_bank_trade(_player.player_id, single_give, _receive_type)
					break
		TradeAction.TRADE_PORT:
			var port_id: String = _state.board.get_port(_port_vertex_id)
			var pdef: PortDef = _state.ports.get(port_id)
			if pdef != null:
				var give_res: int = pdef.resource if pdef.is_specialized else -1
				if give_res >= 0:
					var single_give := ResourceSet.new()
					single_give.set_amount(give_res, pdef.give_count)
					action = TradeAction.new_port_trade(_player.player_id, single_give, _receive_type, _port_vertex_id)
				else:
					# 通用港口，找第一种达到数量的
					for t in ResType.all():
						if _give_amounts.get(t, 0) >= pdef.give_count:
							var single_give := ResourceSet.new()
							single_give.set_amount(t, pdef.give_count)
							action = TradeAction.new_port_trade(_player.player_id, single_give, _receive_type, _port_vertex_id)
							break
		TradeAction.TRADE_PLAYER:
			# 玩家间交易：简化为与下一个玩家交易
			var target_id: int = (_player.player_id + 1) % _state.player_count()
			var recv_set := ResourceSet.new()
			recv_set.set_amount(_receive_type, 1)
			action = TradeAction.new_player_trade(_player.player_id, target_id, give_set, recv_set)

	if action != null:
		trade_confirmed.emit(action)
		visible = false


func _cancel() -> void:
	visible = false
	trade_cancelled.emit()


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeColors.PANEL_COLOR
	style.border_color = ThemeColors.PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	return style
