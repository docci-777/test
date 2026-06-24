## PlayerState 单元测试。
extends GutTest


func _make_player(pid: int = 0, color: String = "red") -> PlayerState:
	return PlayerState.new(pid, color)


# ---- 基础属性 ----

func test_new_player_has_zero_resources():
	var p := _make_player()
	assert_eq(p.resources.total(), 0)
	assert_eq(p.resources.get_amount(ResType.WOOD), 0)


func test_new_player_has_id_and_color():
	var p := _make_player(2, "blue")
	assert_eq(p.player_id, 2)
	assert_eq(p.color, "blue")


func test_new_player_has_zero_buildings():
	var p := _make_player()
	assert_eq(p.count_building("road"), 0)
	assert_eq(p.count_building("settlement"), 0)
	assert_eq(p.count_building("city"), 0)
	assert_eq(p.count_building("ship"), 0)


func test_new_player_has_zero_dev_cards():
	var p := _make_player()
	assert_eq(p.dev_cards_hand.size(), 0)
	assert_eq(p.played_knights, 0)


func test_new_player_has_zero_victory_points():
	var p := _make_player()
	assert_eq(p.visible_victory_points(), 0)
	assert_eq(p.total_victory_points(), 0)


# ---- 资源操作 ----

func test_add_resource_increments_amount():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 3)
	assert_eq(p.resources.get_amount(ResType.WOOD), 3)
	assert_eq(p.resources.total(), 3)


func test_remove_resource_decrements_amount():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 5)
	p.remove_resource(ResType.WOOD, 2)
	assert_eq(p.resources.get_amount(ResType.WOOD), 3)


func test_remove_resource_below_zero_clamps():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 1)
	p.remove_resource(ResType.WOOD, 5)
	assert_eq(p.resources.get_amount(ResType.WOOD), 0)


func test_can_afford_returns_true_when_enough():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 2)
	p.add_resource(ResType.BRICK, 1)
	var cost := ResourceSet.new()
	cost.set_amount(ResType.WOOD, 1)
	cost.set_amount(ResType.BRICK, 1)
	assert_true(p.can_afford(cost))


func test_can_afford_returns_false_when_insufficient():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 1)
	var cost := ResourceSet.new()
	cost.set_amount(ResType.WOOD, 2)
	assert_false(p.can_afford(cost))


func test_pay_subtracts_cost():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 3)
	p.add_resource(ResType.BRICK, 2)
	var cost := ResourceSet.new()
	cost.set_amount(ResType.WOOD, 1)
	cost.set_amount(ResType.BRICK, 1)
	p.pay(cost)
	assert_eq(p.resources.get_amount(ResType.WOOD), 2)
	assert_eq(p.resources.get_amount(ResType.BRICK), 1)


# ---- 建筑计数 ----

func test_add_building_increments_count():
	var p := _make_player()
	p.add_building("road")
	p.add_building("road")
	p.add_building("settlement")
	assert_eq(p.count_building("road"), 2)
	assert_eq(p.count_building("settlement"), 1)


func test_add_building_unknown_type_starts_at_one():
	var p := _make_player()
	p.add_building("ship")
	assert_eq(p.count_building("ship"), 1)


func test_upgrade_settlement_to_city_decrements_settlement_increments_city():
	var p := _make_player()
	p.add_building("settlement")
	p.upgrade_settlement_to_city()
	assert_eq(p.count_building("settlement"), 0)
	assert_eq(p.count_building("city"), 1)


# ---- 发展卡 ----

func test_add_dev_card_appends_to_hand():
	var p := _make_player()
	p.add_dev_card("knight")
	p.add_dev_card("victory_point")
	assert_eq(p.dev_cards_hand.size(), 2)
	assert_eq(p.dev_cards_hand[0], "knight")


func test_use_dev_card_removes_from_hand():
	var p := _make_player()
	p.add_dev_card("knight")
	p.add_dev_card("victory_point")
	p.use_dev_card("knight")
	assert_eq(p.dev_cards_hand.size(), 1)
	assert_eq(p.dev_cards_hand[0], "victory_point")


func test_use_dev_card_knight_increments_played_knights():
	var p := _make_player()
	p.add_dev_card("knight")
	p.use_dev_card("knight")
	assert_eq(p.played_knights, 1)


func test_use_dev_card_victory_point_increments_hidden_vp():
	var p := _make_player()
	p.add_dev_card("victory_point")
	p.use_dev_card("victory_point")
	assert_eq(p.hidden_victory_points, 1)


func test_use_dev_card_nonexistent_returns_false():
	var p := _make_player()
	var ok := p.use_dev_card("knight")
	assert_false(ok)


func test_has_dev_card_returns_true_when_in_hand():
	var p := _make_player()
	p.add_dev_card("knight")
	assert_true(p.has_dev_card("knight"))
	assert_false(p.has_dev_card("monopoly"))


# ---- 胜利点 ----

func test_visible_victory_points_sums_buildings_and_achievements():
	var p := _make_player()
	p.add_building("settlement")  # 1
	p.add_building("settlement")  # 1
	p.add_building("city")        # 2
	# 默认无成就
	assert_eq(p.visible_victory_points(), 4)


func test_total_victory_points_includes_hidden():
	var p := _make_player()
	p.add_building("settlement")  # 1
	p.add_dev_card("victory_point")
	p.use_dev_card("victory_point")  # +1 隐藏
	assert_eq(p.visible_victory_points(), 1)
	assert_eq(p.total_victory_points(), 2)


func test_set_longest_road_adds_two_vp():
	var p := _make_player()
	p.add_building("settlement")  # 1
	p.has_longest_road = true
	assert_eq(p.visible_victory_points(), 3)


func test_set_largest_army_adds_two_vp():
	var p := _make_player()
	p.add_building("settlement")  # 1
	p.has_largest_army = true
	assert_eq(p.visible_victory_points(), 3)


# ---- 手牌上限（7 点弃半） ----

func test_hand_size_returns_total_resources():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 3)
	p.add_resource(ResType.ORE, 2)
	assert_eq(p.hand_size(), 5)


func test_discard_half_returns_amount_to_discard():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 9)
	# 9 张弃 4（向下取整）
	assert_eq(p.discard_half_count(), 4)


func test_discard_half_at_eight_returns_four():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 8)
	assert_eq(p.discard_half_count(), 4)


func test_discard_half_at_seven_returns_zero():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 7)
	assert_eq(p.discard_half_count(), 0)


func test_discard_half_at_zero_returns_zero():
	var p := _make_player()
	assert_eq(p.discard_half_count(), 0)


# ---- clone ----

func test_clone_returns_independent_copy():
	var p := _make_player()
	p.add_resource(ResType.WOOD, 3)
	p.add_building("road")
	p.add_dev_card("knight")
	var c := p.clone()
	c.add_resource(ResType.WOOD, 1)
	c.add_building("road")
	c.add_dev_card("monopoly")
	assert_eq(p.resources.get_amount(ResType.WOOD), 3)
	assert_eq(p.count_building("road"), 1)
	assert_eq(p.dev_cards_hand.size(), 1)
	assert_eq(c.resources.get_amount(ResType.WOOD), 4)
	assert_eq(c.count_building("road"), 2)
	assert_eq(c.dev_cards_hand.size(), 2)
