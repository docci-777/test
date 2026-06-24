## 数据对象类（TerrainDef/BuildingDef/DevCardDef/PortDef）单元测试。
extends GutTest

const TERRAINS_PATH := "res://data/terrains.json"
const BUILDINGS_PATH := "res://data/buildings.json"
const DEV_CARDS_PATH := "res://data/dev_cards.json"
const PORTS_PATH := "res://data/ports.json"


# ---- TerrainDef ----

func test_terrain_def_from_dict_loads_land_terrain():
	var d := {
		"name": "山脉",
		"resource": "ore",
		"count_base": 4,
		"buildable": true,
		"robber_blocks": true,
		"category": "land"
	}
	var t := TerrainDef.from_dict("mountains", d)
	assert_eq(t.id, "mountains")
	assert_eq(t.display_name, "山脉")
	assert_eq(t.resource, ResType.ORE)
	assert_eq(t.count_base, 4)
	assert_true(t.buildable)
	assert_true(t.robber_blocks)
	assert_eq(t.category, "land")


func test_terrain_def_from_dict_handles_null_resource():
	var d := {
		"name": "沙漠",
		"resource": null,
		"count_base": 1,
		"buildable": true,
		"robber_blocks": true,
		"category": "land"
	}
	var t := TerrainDef.from_dict("desert", d)
	assert_eq(t.resource, ResType.INVALID)


func test_terrain_def_from_dict_handles_any_resource_for_gold():
	var d := {
		"name": "黄金地形",
		"resource": "any",
		"count_base": 0,
		"buildable": true,
		"robber_blocks": true,
		"category": "land"
	}
	var t := TerrainDef.from_dict("gold", d)
	# "any" 不是具体资源，应映射为 INVALID（产出时特殊处理）
	assert_eq(t.resource, ResType.INVALID)
	assert_true(t.is_gold)


func test_terrain_def_is_gold_returns_true_for_gold():
	var t := TerrainDef.new()
	t.id = "gold"
	assert_true(t.is_gold)
	t.id = "mountains"
	assert_false(t.is_gold)


func test_terrain_def_is_sea_returns_true_for_water():
	var t := TerrainDef.new()
	t.category = "sea"
	assert_true(t.is_sea)
	t.category = "land"
	assert_false(t.is_sea)


# ---- BuildingDef ----

func test_building_def_from_dict_loads_road():
	var d := {
		"name": "道路",
		"cost": {"wood": 1, "brick": 1},
		"victory_points": 0,
		"position_type": "edge",
		"terrain_category": "land",
		"max_per_player": 15
	}
	var b := BuildingDef.from_dict("road", d)
	assert_eq(b.id, "road")
	assert_eq(b.display_name, "道路")
	assert_eq(b.cost.get_amount(ResType.WOOD), 1)
	assert_eq(b.cost.get_amount(ResType.BRICK), 1)
	assert_eq(b.victory_points, 0)
	assert_eq(b.position_type, "edge")
	assert_eq(b.max_per_player, 15)


func test_building_def_from_dict_loads_city_with_upgrade():
	var d := {
		"name": "城市",
		"cost": {"wheat": 2, "ore": 3},
		"victory_points": 2,
		"position_type": "vertex",
		"terrain_category": "land",
		"max_per_player": 4,
		"upgrades_from": "settlement"
	}
	var b := BuildingDef.from_dict("city", d)
	assert_eq(b.cost.get_amount(ResType.WHEAT), 2)
	assert_eq(b.cost.get_amount(ResType.ORE), 3)
	assert_eq(b.victory_points, 2)
	assert_eq(b.upgrades_from, "settlement")


func test_building_def_is_upgrade_returns_true_when_upgrades_from_set():
	var b := BuildingDef.new()
	b.upgrades_from = "settlement"
	assert_true(b.is_upgrade)
	b.upgrades_from = ""
	assert_false(b.is_upgrade)


# ---- DevCardDef ----

func test_dev_card_def_from_dict_loads_knight():
	var d := {
		"name": "骑士",
		"count": 14,
		"victory_points": 0,
		"usable_same_turn": false,
		"effect": "move_robber_and_steal",
		"counts_for_largest_army": true
	}
	var c := DevCardDef.from_dict("knight", d)
	assert_eq(c.id, "knight")
	assert_eq(c.display_name, "骑士")
	assert_eq(c.count, 14)
	assert_eq(c.victory_points, 0)
	assert_false(c.usable_same_turn)
	assert_eq(c.effect, "move_robber_and_steal")
	assert_true(c.counts_for_largest_army)


func test_dev_card_def_from_dict_loads_victory_point_hidden():
	var d := {
		"name": "胜利点",
		"count": 5,
		"victory_points": 1,
		"usable_same_turn": true,
		"effect": "add_victory_point",
		"hidden": true,
		"counts_for_largest_army": false
	}
	var c := DevCardDef.from_dict("victory_point", d)
	assert_eq(c.victory_points, 1)
	assert_true(c.usable_same_turn)
	assert_true(c.hidden)
	assert_false(c.counts_for_largest_army)


# ---- PortDef ----

func test_port_def_from_dict_loads_generic_port():
	var d := {
		"name": "通用港口",
		"trade_ratio": "3:1",
		"give_count": 3,
		"receive_count": 1,
		"resource": null,
		"count_base": 4
	}
	var p := PortDef.from_dict("generic_3to1", d)
	assert_eq(p.id, "generic_3to1")
	assert_eq(p.display_name, "通用港口")
	assert_eq(p.give_count, 3)
	assert_eq(p.receive_count, 1)
	assert_eq(p.resource, ResType.INVALID)
	assert_false(p.is_specialized)


func test_port_def_from_dict_loads_specialized_port():
	var d := {
		"name": "木材港口",
		"trade_ratio": "2:1",
		"give_count": 2,
		"receive_count": 1,
		"resource": "wood",
		"count_base": 1
	}
	var p := PortDef.from_dict("wood_2to1", d)
	assert_eq(p.give_count, 2)
	assert_eq(p.resource, ResType.WOOD)
	assert_true(p.is_specialized)


# ---- 从真实数据文件加载 ----

func test_load_real_terrains_file_has_expected_terrains():
	var r := DataLoader.load_json(TERRAINS_PATH)
	assert_true(r.ok, "terrains.json should load: %s" % r.error_message)
	var terrains: Dictionary = r.value.terrains
	assert_true(terrains.has("mountains"))
	assert_true(terrains.has("desert"))
	assert_true(terrains.has("gold"))
	assert_true(terrains.has("shallow_water"))
	assert_true(terrains.has("deep_water"))


func test_load_real_buildings_file_has_five_buildings():
	var r := DataLoader.load_json(BUILDINGS_PATH)
	assert_true(r.ok, "buildings.json should load: %s" % r.error_message)
	var buildings: Dictionary = r.value.buildings
	assert_eq(buildings.size(), 5)
	assert_true(buildings.has("road"))
	assert_true(buildings.has("ship"))
	assert_true(buildings.has("settlement"))
	assert_true(buildings.has("city"))
	assert_true(buildings.has("dev_card"))


func test_load_real_dev_cards_file_total_is_25():
	var r := DataLoader.load_json(DEV_CARDS_PATH)
	assert_true(r.ok, "dev_cards.json should load: %s" % r.error_message)
	assert_eq(r.value.total_count, 25)
	var cards: Dictionary = r.value.dev_cards
	assert_eq(cards.size(), 5)


func test_load_real_ports_file_total_is_9():
	var r := DataLoader.load_json(PORTS_PATH)
	assert_true(r.ok, "ports.json should load: %s" % r.error_message)
	assert_eq(r.value.total_count, 9)
	var ports: Dictionary = r.value.ports
	assert_eq(ports.size(), 6)
