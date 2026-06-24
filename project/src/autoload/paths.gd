## 集中管理项目路径常量。
##
## 作为 autoload 单例全局可访问，仅承载路径与配置常量，
## 不持有任何游戏运行时状态（符合 CODING_STANDARDS §12）。
## 所有跨模块路径字符串必须引用本类常量，禁止散落字面量。
extends Node

# ---- 顶层目录 ----
const DATA_DIR: String = "res://data/"
const ASSETS_DIR: String = "res://assets/"
const SCENES_DIR: String = "res://scenes/"
const TEST_FIXTURES_DIR: String = "res://tests/fixtures/"

# ---- 数据文件（规则数据，JSON 格式）----
const TERRAINS_FILE: String = "res://data/terrains.json"
const BUILDINGS_FILE: String = "res://data/buildings.json"
const DEV_CARDS_FILE: String = "res://data/dev_cards.json"
const PORTS_FILE: String = "res://data/ports.json"

# ---- 场景布局数据 ----
const SCENARIOS_DIR: String = "res://data/scenarios/"
const SCENARIO_BASE_4P: String = "res://data/scenarios/base_4p.json"
const SCENARIO_NEW_WORLD: String = "res://data/scenarios/seafarers_new_world.json"
const SCENARIO_DESERT: String = "res://data/scenarios/seafarers_desert.json"

# ---- 美术资源（按类型细分）----
const SPRITES_DIR: String = "res://assets/sprites/"
const SPRITES_TERRAIN_DIR: String = "res://assets/sprites/terrain/"
const SPRITES_BUILDINGS_DIR: String = "res://assets/sprites/buildings/"
const SPRITES_CARDS_DIR: String = "res://assets/sprites/cards/"
const SPRITES_ICONS_DIR: String = "res://assets/sprites/icons/"

# ---- 音频资源 ----
const AUDIO_DIR: String = "res://assets/audio/"
const AUDIO_MUSIC_DIR: String = "res://assets/audio/music/"
const AUDIO_SFX_DIR: String = "res://assets/audio/sfx/"

# ---- 字体与主题 ----
const FONTS_DIR: String = "res://assets/fonts/"
const THEMES_DIR: String = "res://assets/themes/"

# ---- 着色器 ----
const SHADERS_DIR: String = "res://assets/shaders/"

# ---- 场景文件（按用途细分）----
const SCENES_MAIN_DIR: String = "res://scenes/main/"
const SCENES_BOARD_DIR: String = "res://scenes/board/"
const SCENES_UI_DIR: String = "res://scenes/ui/"
