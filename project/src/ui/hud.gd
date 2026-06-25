## HUD 面板（P9-3, P9-5, P9-6）。
##
## 显示当前玩家资源、胜利点、建筑库存、发展卡手牌。
## 提供动作按钮（掷骰/建造/交易/使用卡/结束回合）与骰子显示。
class_name HUD extends CanvasLayer

# ---- 信号 ----
signal roll_dice_pressed()
signal build_pressed(building_id: String)
signal trade_pressed()
signal use_dev_card_pressed(card_id: String)
signal end_turn_pressed()

# ---- 节点引用 ----
var _state: GameState
var _top_bar: Panel
var _resource_panel: Panel
var _action_panel: Panel
var _dice_label: Label
var _phase_label: Label
var _message_label: Label
var _dev_card_container: HBoxContainer
var _build_buttons: Dictionary = {}  # building_id -> Button

# 骰子动画
var _die1: int = 0
var _die2: int = 0
var _dice_anim_timer: float = 0.0
var _dice_animating: bool = false
var _dice_display: Label


func _ready() -> void:
	layer = 10
	_build_ui()


func _process(delta: float) -> void:
	if _dice_animating:
		_dice_anim_timer -= delta
		if _dice_anim_timer > 0:
			# 随机翻滚
			_die1 = randi_range(1, 6)
			_die2 = randi_range(1, 6)
			_update_dice_display()
		else:
			_dice_animating = false
			_update_dice_display()


## 更新 HUD 视图。
func update_view(state: GameState) -> void:
	_state = state
	_refresh_player_info()
	_refresh_action_buttons()
	_refresh_dev_cards()


# ---- UI 构建 ----

func _build_ui() -> void:
	_build_top_bar()
	_build_resource_panel()
	_build_action_panel()
	_build_dice_display()
	_build_message_label()


func _build_top_bar() -> void:
	_top_bar = Panel.new()
	_top_bar.position = Vector2(0, 0)
	_top_bar.size = Vector2(1280, 40)
	_top_bar.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_top_bar)

	_phase_label = Label.new()
	_phase_label.position = Vector2(16, 8)
	_phase_label.size = Vector2(400, 24)
	_phase_label.add_theme_font_size_override("font_size", 18)
	_top_bar.add_child(_phase_label)


func _build_resource_panel() -> void:
	_resource_panel = Panel.new()
	_resource_panel.position = Vector2(0, 640)
	_resource_panel.size = Vector2(1280, 80)
	_resource_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_resource_panel)

	var hbox := HBoxContainer.new()
	hbox.position = Vector2(16, 8)
	hbox.size = Vector2(1248, 64)
	hbox.add_theme_constant_override("separation", 20)
	_resource_panel.add_child(hbox)

	# 资源显示（5 种）
	for i in range(5):
		var res_box := _make_resource_display(i)
		hbox.add_child(res_box)

	# 分隔
	var sep := VSeparator.new()
	sep.add_theme_constant_override("separation", 10)
	hbox.add_child(sep)

	# 胜利点
	var vp_box := VBoxContainer.new()
	vp_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var vp_label := Label.new()
	vp_label.text = "胜利点"
	vp_label.add_theme_font_size_override("font_size", 12)
	vp_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vp_box.add_child(vp_label)
	var vp_value := Label.new()
	vp_value.name = "VPValue"
	vp_value.text = "0"
	vp_value.add_theme_font_size_override("font_size", 22)
	vp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vp_box.add_child(vp_value)
	hbox.add_child(vp_box)

	# 建筑库存
	var stock_box := VBoxContainer.new()
	stock_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var stock_label := Label.new()
	stock_label.text = "建筑库存"
	stock_label.add_theme_font_size_override("font_size", 12)
	stock_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	stock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock_box.add_child(stock_label)
	var stock_detail := Label.new()
	stock_detail.name = "StockDetail"
	stock_detail.text = "路15 定5 城4"
	stock_detail.add_theme_font_size_override("font_size", 14)
	stock_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stock_box.add_child(stock_detail)
	hbox.add_child(stock_box)


func _build_action_panel() -> void:
	_action_panel = Panel.new()
	_action_panel.position = Vector2(960, 40)
	_action_panel.size = Vector2(320, 600)
	_action_panel.add_theme_stylebox_override("panel", _make_panel_style())
	add_child(_action_panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(12, 12)
	vbox.size = Vector2(296, 576)
	vbox.add_theme_constant_override("separation", 8)
	_action_panel.add_child(vbox)

	# 掷骰按钮
	var roll_btn := Button.new()
	roll_btn.text = "🎲 掷骰子"
	roll_btn.name = "RollButton"
	roll_btn.custom_minimum_size = Vector2(0, 44)
	roll_btn.add_theme_font_size_override("font_size", 18)
	roll_btn.pressed.connect(func(): roll_dice_pressed.emit())
	vbox.add_child(roll_btn)

	# 建造按钮组
	var build_label := Label.new()
	build_label.text = "建造"
	build_label.add_theme_font_size_override("font_size", 14)
	build_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(build_label)

	for bid in ["road", "settlement", "city", "dev_card"]:
		var btn := Button.new()
		btn.text = _build_button_text(bid)
		btn.name = "Build_" + bid
		btn.custom_minimum_size = Vector2(0, 38)
		btn.add_theme_font_size_override("font_size", 15)
		btn.pressed.connect(func(): build_pressed.emit(bid))
		vbox.add_child(btn)
		_build_buttons[bid] = btn

	# 交易按钮
	var trade_btn := Button.new()
	trade_btn.text = "🤝 交易"
	trade_btn.name = "TradeButton"
	trade_btn.custom_minimum_size = Vector2(0, 44)
	trade_btn.add_theme_font_size_override("font_size", 18)
	trade_btn.pressed.connect(func(): trade_pressed.emit())
	vbox.add_child(trade_btn)

	# 发展卡区域
	var dev_label := Label.new()
	dev_label.text = "发展卡"
	dev_label.add_theme_font_size_override("font_size", 14)
	dev_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	vbox.add_child(dev_label)

	_dev_card_container = HBoxContainer.new()
	_dev_card_container.add_theme_constant_override("separation", 6)
	vbox.add_child(_dev_card_container)

	# 结束回合
	var end_btn := Button.new()
	end_btn.text = "✓ 结束回合"
	end_btn.name = "EndTurnButton"
	end_btn.custom_minimum_size = Vector2(0, 44)
	end_btn.add_theme_font_size_override("font_size", 18)
	end_btn.pressed.connect(func(): end_turn_pressed.emit())
	vbox.add_child(end_btn)


func _build_dice_display() -> void:
	_dice_display = Label.new()
	_dice_display.position = Vector2(540, 50)
	_dice_display.size = Vector2(200, 50)
	_dice_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dice_display.add_theme_font_size_override("font_size", 28)
	_dice_display.visible = false
	add_child(_dice_display)


func _build_message_label() -> void:
	_message_label = Label.new()
	_message_label.position = Vector2(400, 610)
	_message_label.size = Vector2(480, 30)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 16)
	_message_label.add_theme_color_override("font_color", ThemeColors.TEXT_COLOR)
	add_child(_message_label)


# ---- 刷新 ----

func _refresh_player_info() -> void:
	if _state == null:
		return
	var player: PlayerState = _state.current_player()
	if player == null:
		return

	# 阶段标签
	var fsm_state: int = TurnFSM.get_state(_state)
	var phase_text: String = TurnFSM.state_name(fsm_state)
	var color_name: String = ThemeColors.PLAYER_NAMES.get(player.color, player.color)
	_phase_label.text = "%s | %s | 回合 %d" % [color_name, phase_text, _state.round_number]
	_phase_label.add_theme_color_override("font_color", ThemeColors.PLAYER_COLORS.get(player.color, Color.WHITE))

	# 资源数量
	var hbox: HBoxContainer = _resource_panel.get_child(0)
	var res_idx: int = 0
	for child in hbox.get_children():
		if child is VBoxContainer:
			var val_label: Label = child.get_child(1) if child.get_child_count() > 1 else null
			if val_label == null:
				continue
			if res_idx < 5:
				val_label.text = str(player.resources.get_amount(res_idx))
				res_idx += 1
			elif val_label.name == "VPValue":
				val_label.text = str(player.visible_victory_points())
			elif val_label.name == "StockDetail":
				val_label.text = "路%d 定%d 城%d" % [
					15 - player.count_building("road"),
					5 - player.count_building("settlement"),
					4 - player.count_building("city"),
				]


func _refresh_action_buttons() -> void:
	if _state == null:
		return
	var fsm_state: int = TurnFSM.get_state(_state)
	var allowed: Array = TurnFSM.allowed_actions(fsm_state)

	# 掷骰按钮
	var roll_btn: Button = _action_panel.get_node_or_null("RollButton")
	if roll_btn:
		roll_btn.disabled = not allowed.has(Action.TYPE_ROLL_DICE)

	# 建造按钮
	for bid in _build_buttons.keys():
		var btn: Button = _build_buttons[bid]
		btn.disabled = not allowed.has(Action.TYPE_BUILD)

	# 交易按钮
	var trade_btn: Button = _action_panel.get_node_or_null("TradeButton")
	if trade_btn:
		trade_btn.disabled = not allowed.has(Action.TYPE_TRADE)

	# 结束回合
	var end_btn: Button = _action_panel.get_node_or_null("EndTurnButton")
	if end_btn:
		end_btn.disabled = not allowed.has(Action.TYPE_END_TURN)


func _refresh_dev_cards() -> void:
	if _state == null:
		return
	for child in _dev_card_container.get_children():
		child.queue_free()

	var player: PlayerState = _state.current_player()
	if player == null:
		return

	# 按类型分组
	var card_counts: Dictionary = {}
	for card_id in player.dev_cards_hand:
		card_counts[card_id] = card_counts.get(card_id, 0) + 1

	for card_id in card_counts.keys():
		var def: DevCardDef = _state.dev_cards.get(card_id)
		var display_name: String = def.display_name if def != null else card_id
		var count: int = card_counts[card_id]

		var btn := Button.new()
		btn.text = "%s ×%d" % [display_name, count]
		btn.add_theme_font_size_override("font_size", 13)
		btn.custom_minimum_size = Vector2(90, 36)

		# 检查是否可用
		var can_use: bool = TurnFSM.is_action_allowed(TurnFSM.get_state(_state), Action.TYPE_USE_DEV_CARD)
		can_use = can_use and not player.dev_card_used_this_turn
		can_use = can_use and player.has_usable_dev_card(card_id)
		btn.disabled = not can_use

		var captured_id: String = card_id
		btn.pressed.connect(func(): use_dev_card_pressed.emit(captured_id))
		_dev_card_container.add_child(btn)


# ---- 骰子 ----

## 显示骰子动画。
func show_dice_roll(die1: int, die2: int) -> void:
	_die1 = die1
	_die2 = die2
	_dice_animating = true
	_dice_anim_timer = 0.6
	_dice_display.visible = true


func _update_dice_display() -> void:
	if _dice_animating:
		_dice_display.text = "🎲 %d + %d" % [_die1, _die2]
	else:
		var total: int = _die1 + _die2
		var color: Color = ThemeColors.TEXT_COLOR
		if total == 7:
			color = Color(0.9, 0.3, 0.3)
		_dice_display.text = "🎲 %d + %d = %d" % [_die1, _die2, total]
		_dice_display.add_theme_color_override("font_color", color)


## 显示临时消息。
func show_message(text: String, duration: float = 3.0) -> void:
	_message_label.text = text
	_message_label.visible = true
	# 简单定时器
	var tree: SceneTree = get_tree()
	if tree:
		tree.create_timer(duration).timeout.connect(func(): _message_label.visible = false)


# ---- 辅助 ----

func _make_resource_display(res_type: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon_label := Label.new()
	icon_label.text = ThemeColors.RESOURCE_ICONS.get(res_type, "?")
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(icon_label)

	var name_label := Label.new()
	name_label.text = ThemeColors.RESOURCE_NAMES.get(res_type, "?")
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", ThemeColors.TEXT_DIM)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name_label)

	var value_label := Label.new()
	value_label.text = "0"
	value_label.add_theme_font_size_override("font_size", 22)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value_label)

	return box


func _build_button_text(bid: String) -> String:
	match bid:
		"road": return "🛤️ 道路 (1木1砖)"
		"settlement": return "🏠 定居点 (1木1砖1羊1麦)"
		"city": return "🏰 城市 (2麦3矿)"
		"dev_card": return "📜 发展卡 (1羊1麦1矿)"
		_: return bid


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeColors.PANEL_COLOR
	style.border_color = ThemeColors.PANEL_BORDER
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style
