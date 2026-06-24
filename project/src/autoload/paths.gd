## 集中管理项目路径常量。
##
## 作为 autoload 单例全局可访问，仅承载路径与配置常量，
## 不持有任何游戏运行时状态（符合 CODING_STANDARDS §12）。
## 所有跨模块路径字符串必须引用本类常量，禁止散落字面量。
extends Node

# ---- 数据根目录 ----
const DATA_DIR: String = "res://data/"
const SCENARIOS_DIR: String = "res://data/scenarios/"
const ASSETS_DIR: String = "res://assets/"

# ---- 数据文件 ----
const TERRAINS_FILE: String = "res://data/terrains.json"
const BUILDINGS_FILE: String = "res://data/buildings.json"
const DEV_CARDS_FILE: String = "res://data/dev_cards.json"
const PORTS_FILE: String = "res://data/ports.json"

# ---- 场景文件 ----
const SCENARIO_BASE_4P: String = "res://data/scenarios/base_4p.json"
const SCENARIO_NEW_WORLD: String = "res://data/scenarios/seafarers_new_world.json"
const SCENARIO_DESERT: String = "res://data/scenarios/seafarers_desert.json"

# ---- 测试 fixtures ----
const TEST_FIXTURES_DIR: String = "res://tests/fixtures/"
