## DataLoader 扩展加载方法单元测试。
##
## 测试强类型加载方法（load_terrains/load_buildings/load_dev_cards/load_ports）。
extends GutTest


# ---- load_terrains ----

func test_load_terrains_returns_dict_of_terrain_defs():
	var r := DataLoader.load_terrains()
	assert_true(r.ok, r.error_message)
	var terrains: Dictionary = r.value
	assert_true(terrains.has("mountains"))
	assert_true(terrains.has("desert"))
	var t: TerrainDef = terrains["mountains"]
	assert_eq(t.id, "mountains")
	assert_eq(t.resource, ResType.ORE)
	assert_eq(t.count_base, 4)


func test_load_terrains_includes_seafarers_terrains():
	var r := DataLoader.load_terrains()
	assert_true(r.ok)
	var terrains: Dictionary = r.value
	assert_true(terrains.has("gold"))
	assert_true(terrains.has("shallow_water"))
	assert_true(terrains.has("deep_water"))
	assert_true(terrains["gold"].is_gold)
	assert_true(terrains["shallow_water"].is_sea)


# ---- load_buildings ----

func test_load_buildings_returns_dict_of_building_defs():
	var r := DataLoader.load_buildings()
	assert_true(r.ok, r.error_message)
	var buildings: Dictionary = r.value
	assert_eq(buildings.size(), 5)
	var road: BuildingDef = buildings["road"]
	assert_eq(road.cost.get_amount(ResType.WOOD), 1)
	assert_eq(road.cost.get_amount(ResType.BRICK), 1)


func test_load_buildings_city_has_upgrade_from_settlement():
	var r := DataLoader.load_buildings()
	assert_true(r.ok)
	var city: BuildingDef = r.value["city"]
	assert_true(city.is_upgrade)
	assert_eq(city.upgrades_from, "settlement")


func test_load_buildings_ship_has_movable_flag():
	var r := DataLoader.load_buildings()
	assert_true(r.ok)
	var ship: BuildingDef = r.value["ship"]
	assert_true(ship.movable)


# ---- load_dev_cards ----

func test_load_dev_cards_returns_dict_of_card_defs():
	var r := DataLoader.load_dev_cards()
	assert_true(r.ok, r.error_message)
	var cards: Dictionary = r.value
	assert_eq(cards.size(), 5)
	var knight: DevCardDef = cards["knight"]
	assert_eq(knight.count, 14)
	assert_true(knight.counts_for_largest_army)


func test_load_dev_cards_victory_point_is_hidden():
	var r := DataLoader.load_dev_cards()
	assert_true(r.ok)
	var vp: DevCardDef = r.value["victory_point"]
	assert_true(vp.hidden)
	assert_eq(vp.victory_points, 1)


# ---- load_ports ----

func test_load_ports_returns_dict_of_port_defs():
	var r := DataLoader.load_ports()
	assert_true(r.ok, r.error_message)
	var ports: Dictionary = r.value
	assert_eq(ports.size(), 6)
	var generic: PortDef = ports["generic_3to1"]
	assert_eq(generic.give_count, 3)
	assert_false(generic.is_specialized)


func test_load_ports_specialized_has_correct_resource():
	var r := DataLoader.load_ports()
	assert_true(r.ok)
	var wood_port: PortDef = r.value["wood_2to1"]
	assert_true(wood_port.is_specialized)
	assert_eq(wood_port.resource, ResType.WOOD)
	assert_eq(wood_port.give_count, 2)


# ---- 校验失败 ----

func test_load_terrains_missing_file_returns_not_found():
	var r := DataLoader.load_terrains_from_path("res://tests/fixtures/nonexistent.json")
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_NOT_FOUND)


func test_load_terrains_invalid_structure_returns_parse_error():
	# 用 array 而非 dict 的 fixture
	var r := DataLoader.load_terrains_from_path("res://tests/fixtures/valid_array.json")
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_PARSE)


func test_load_terrains_missing_terrains_key_returns_parse_error():
	# valid_dict.json 没有 "terrains" 键
	var r := DataLoader.load_terrains_from_path("res://tests/fixtures/valid_dict.json")
	assert_false(r.ok)
	assert_eq(r.error_code, Result.ERR_PARSE)
