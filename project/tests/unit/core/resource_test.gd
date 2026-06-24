## ResType 与 ResourceSet 单元测试。
extends GutTest

# ---- ResType 枚举 ----

func test_resource_type_has_five_types():
	# 基础版 5 种资源
	assert_eq(ResType.WOOD, 0)
	assert_eq(ResType.BRICK, 1)
	assert_eq(ResType.SHEEP, 2)
	assert_eq(ResType.WHEAT, 3)
	assert_eq(ResType.ORE, 4)


func test_all_types_returns_five_entries():
	var types: Array = ResType.all()
	assert_eq(types.size(), 5)
	assert_true(types.has(ResType.WOOD))
	assert_true(types.has(ResType.ORE))


func test_name_returns_known_name():
	assert_eq(ResType.name_of(ResType.WOOD), "wood")
	assert_eq(ResType.name_of(ResType.BRICK), "brick")
	assert_eq(ResType.name_of(ResType.SHEEP), "sheep")
	assert_eq(ResType.name_of(ResType.WHEAT), "wheat")
	assert_eq(ResType.name_of(ResType.ORE), "ore")


func test_name_of_invalid_returns_unknown():
	assert_eq(ResType.name_of(-1), "unknown")
	assert_eq(ResType.name_of(99), "unknown")


func test_from_name_returns_known_type():
	assert_eq(ResType.from_name("wood"), ResType.WOOD)
	assert_eq(ResType.from_name("ore"), ResType.ORE)


func test_from_name_invalid_returns_minus_one():
	assert_eq(ResType.from_name("invalid"), -1)
	assert_eq(ResType.from_name(""), -1)


# ---- ResourceSet 基础 ----

func test_empty_resource_set_has_zero_for_all():
	var rs := ResourceSet.new()
	assert_eq(rs.get_amount(ResType.WOOD), 0)
	assert_eq(rs.get_amount(ResType.ORE), 0)
	assert_eq(rs.total(), 0)


func test_set_amount_stores_value():
	var rs := ResourceSet.new()
	rs.set_amount(ResType.WOOD, 3)
	rs.set_amount(ResType.BRICK, 2)
	assert_eq(rs.get_amount(ResType.WOOD), 3)
	assert_eq(rs.get_amount(ResType.BRICK), 2)
	assert_eq(rs.total(), 5)


func test_set_amount_negative_clamps_to_zero():
	var rs := ResourceSet.new()
	rs.set_amount(ResType.WOOD, -5)
	assert_eq(rs.get_amount(ResType.WOOD), 0)


func test_add_increments_amount():
	var rs := ResourceSet.new()
	rs.add(ResType.WOOD, 2)
	rs.add(ResType.WOOD, 3)
	assert_eq(rs.get_amount(ResType.WOOD), 5)


func test_add_zero_is_noop():
	var rs := ResourceSet.new()
	rs.add(ResType.WOOD, 0)
	assert_eq(rs.get_amount(ResType.WOOD), 0)


func test_subtract_decrements_amount():
	var rs := ResourceSet.new()
	rs.set_amount(ResType.WOOD, 5)
	rs.subtract(ResType.WOOD, 3)
	assert_eq(rs.get_amount(ResType.WOOD), 2)


func test_subtract_below_zero_clamps_to_zero():
	var rs := ResourceSet.new()
	rs.set_amount(ResType.WOOD, 2)
	rs.subtract(ResType.WOOD, 5)
	assert_eq(rs.get_amount(ResType.WOOD), 0)


# ---- ResourceSet 比较 ----

func test_covers_returns_true_when_superset():
	var a := ResourceSet.new()
	a.set_amount(ResType.WOOD, 3)
	a.set_amount(ResType.BRICK, 2)
	var b := ResourceSet.new()
	b.set_amount(ResType.WOOD, 2)
	b.set_amount(ResType.BRICK, 1)
	assert_true(a.covers(b))


func test_covers_returns_false_when_not_superset():
	var a := ResourceSet.new()
	a.set_amount(ResType.WOOD, 1)
	var b := ResourceSet.new()
	b.set_amount(ResType.WOOD, 2)
	assert_false(a.covers(b))


func test_covers_returns_true_for_empty_requirement():
	var a := ResourceSet.new()
	a.set_amount(ResType.WOOD, 1)
	var b := ResourceSet.new()
	assert_true(a.covers(b))


func test_covers_returns_true_for_both_empty():
	assert_true(ResourceSet.new().covers(ResourceSet.new()))


# ---- ResourceSet 运算 ----

func test_add_set_merges_two_sets():
	var a := ResourceSet.new()
	a.set_amount(ResType.WOOD, 2)
	a.set_amount(ResType.BRICK, 1)
	var b := ResourceSet.new()
	b.set_amount(ResType.WOOD, 3)
	b.set_amount(ResType.ORE, 4)
	a.add_set(b)
	assert_eq(a.get_amount(ResType.WOOD), 5)
	assert_eq(a.get_amount(ResType.BRICK), 1)
	assert_eq(a.get_amount(ResType.ORE), 4)


func test_subtract_set_subtracts_each():
	var a := ResourceSet.new()
	a.set_amount(ResType.WOOD, 5)
	a.set_amount(ResType.BRICK, 3)
	var b := ResourceSet.new()
	b.set_amount(ResType.WOOD, 2)
	b.set_amount(ResType.BRICK, 4)  # 超过 a 的数量
	a.subtract_set(b)
	assert_eq(a.get_amount(ResType.WOOD), 3)
	assert_eq(a.get_amount(ResType.BRICK), 0)  # 钳制为 0


func test_clone_returns_independent_copy():
	var a := ResourceSet.new()
	a.set_amount(ResType.WOOD, 3)
	var b := a.clone()
	b.set_amount(ResType.WOOD, 99)
	assert_eq(a.get_amount(ResType.WOOD), 3)
	assert_eq(b.get_amount(ResType.WOOD), 99)


func test_to_dict_returns_all_types():
	var rs := ResourceSet.new()
	rs.set_amount(ResType.WOOD, 2)
	rs.set_amount(ResType.ORE, 1)
	var d: Dictionary = rs.to_dict()
	assert_eq(d.size(), 5)
	assert_eq(d["wood"], 2)
	assert_eq(d["ore"], 1)
	assert_eq(d["brick"], 0)


func test_from_dict_loads_all_types():
	var d := {"wood": 3, "brick": 1, "sheep": 0, "wheat": 2, "ore": 4}
	var rs := ResourceSet.from_dict(d)
	assert_eq(rs.get_amount(ResType.WOOD), 3)
	assert_eq(rs.get_amount(ResType.BRICK), 1)
	assert_eq(rs.get_amount(ResType.SHEEP), 0)
	assert_eq(rs.get_amount(ResType.WHEAT), 2)
	assert_eq(rs.get_amount(ResType.ORE), 4)
	assert_eq(rs.total(), 10)


func test_from_dict_ignores_unknown_keys():
	var d := {"wood": 3, "unknown_resource": 99}
	var rs := ResourceSet.from_dict(d)
	assert_eq(rs.get_amount(ResType.WOOD), 3)
	assert_eq(rs.total(), 3)
