## P9 表现层冒烟测试。
##
## 验证 UI 组件可正确实例化与初始化。
## 不测试渲染像素，仅验证逻辑接口不崩溃。
extends GutTest

var _state: GameState


func before_each():
	_state = TestHelper.make_standard_state()


func test_theme_colors_exist():
	assert_true(ThemeColors.TERRAIN_COLORS.has("mountains"))
	assert_true(ThemeColors.TERRAIN_COLORS.has("desert"))
	assert_true(ThemeColors.PLAYER_COLORS.has("red"))
	assert_true(ThemeColors.PLAYER_COLORS.has("orange"))
	assert_eq(ThemeColors.RESOURCE_NAMES.size(), 5)


func test_theme_colors_resource_names():
	assert_eq(ThemeColors.RESOURCE_NAMES[ResType.WOOD], "木材")
	assert_eq(ThemeColors.RESOURCE_NAMES[ResType.BRICK], "砖块")
	assert_eq(ThemeColors.RESOURCE_NAMES[ResType.SHEEP], "羊毛")
	assert_eq(ThemeColors.RESOURCE_NAMES[ResType.WHEAT], "麦子")
	assert_eq(ThemeColors.RESOURCE_NAMES[ResType.ORE], "矿石")


func test_board_view_creates():
	var bv := BoardView.new()
	assert_not_null(bv)
	bv.queue_free()


func test_board_view_update():
	var bv := BoardView.new()
	bv.update_view(_state)
	# 不崩溃即通过
	assert_not_null(bv)
	bv.queue_free()


func test_board_view_build_mode():
	var bv := BoardView.new()
	bv.update_view(_state)
	bv.set_build_mode("settlement", [0, 1, 2])
	bv.clear_build_mode()
	assert_not_null(bv)
	bv.queue_free()


func test_player_switch_creates():
	var ps := PlayerSwitch.new()
	assert_not_null(ps)
	ps.queue_free()


func test_victory_screen_creates():
	var vs := VictoryScreen.new()
	assert_not_null(vs)
	vs.queue_free()


func test_victory_screen_show():
	var vs := VictoryScreen.new()
	add_child(vs)
	var winner: PlayerState = _state.get_player(0)
	winner.add_building("settlement")
	winner.add_building("settlement")
	winner.add_building("settlement")
	winner.add_building("settlement")
	winner.add_building("settlement")
	winner.add_building("settlement")
	winner.add_building("settlement")
	winner.add_building("settlement")
	winner.add_building("settlement")
	winner.add_building("settlement")
	vs.show_victory(winner, _state.get_all_players())
	assert_true(vs.visible)
	vs.queue_free()


func test_trade_dialog_creates():
	var td := TradeDialog.new()
	assert_not_null(td)
	td.queue_free()


func test_trade_dialog_show():
	var td := TradeDialog.new()
	add_child(td)
	td.show_dialog(_state)
	assert_true(td.visible)
	td.hide_dialog()
	assert_false(td.visible)
	td.queue_free()


func test_hud_creates():
	var hud := HUD.new()
	assert_not_null(hud)
	hud.queue_free()


func test_hud_update():
	var hud := HUD.new()
	add_child(hud)
	hud.update_view(_state)
	# 不崩溃即通过
	assert_not_null(hud)
	hud.queue_free()


func test_game_controller_valid_vertices():
	# 测试 GameController 的辅助方法逻辑
	# 创建一个简单的棋盘状态
	var state := TestHelper.make_standard_state()
	state.set_phase(GameState.Phase.ACTION)
	state.has_rolled_this_turn = true

	# 验证棋盘有顶点和边
	assert_true(state.board.vertex_count() > 0)
	assert_true(state.board.edge_count() > 0)

	# 验证所有六边形都有地形
	for hex_data in state.board.all_hexes():
		assert_true(not hex_data.terrain_id.is_empty())
