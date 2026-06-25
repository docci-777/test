## 表现层颜色主题常量。
##
## 集中管理所有 UI 颜色，便于统一调整与后续替换素材（见 ARCHITECTURE §6.1）。
class_name ThemeColors extends RefCounted

# ---- 地形颜色 ----
const TERRAIN_COLORS: Dictionary = {
	"mountains": Color(0.55, 0.55, 0.60),
	"hills": Color(0.72, 0.42, 0.30),
	"forest": Color(0.20, 0.48, 0.24),
	"fields": Color(0.80, 0.72, 0.30),
	"pasture": Color(0.45, 0.70, 0.38),
	"desert": Color(0.86, 0.80, 0.58),
	"gold": Color(0.85, 0.70, 0.20),
	"shallow_water": Color(0.30, 0.52, 0.72, 0.80),
	"deep_water": Color(0.15, 0.30, 0.52, 0.85),
}

# ---- 玩家颜色 ----
const PLAYER_COLORS: Dictionary = {
	"red": Color(0.82, 0.22, 0.22),
	"blue": Color(0.22, 0.42, 0.82),
	"white": Color(0.92, 0.92, 0.92),
	"orange": Color(0.92, 0.60, 0.20),
}

const PLAYER_NAMES: Dictionary = {
	"red": "红方",
	"blue": "蓝方",
	"white": "白方",
	"orange": "橙方",
}

# ---- 资源颜色 ----
const RESOURCE_COLORS: Dictionary = {
	0: Color(0.20, 0.48, 0.24),   # wood - 绿
	1: Color(0.72, 0.42, 0.30),   # brick - 红棕
	2: Color(0.45, 0.70, 0.38),   # sheep - 浅绿
	3: Color(0.80, 0.72, 0.30),   # wheat - 金黄
	4: Color(0.55, 0.55, 0.60),   # ore - 灰
}

const RESOURCE_NAMES: Dictionary = {
	0: "木材",
	1: "砖块",
	2: "羊毛",
	3: "麦子",
	4: "矿石",
}

const RESOURCE_ICONS: Dictionary = {
	0: "🪵",
	1: "🧱",
	2: "🐑",
	3: "🌾",
	4: "⛏️",
}

# ---- UI 颜色 ----
const BG_COLOR: Color = Color(0.10, 0.10, 0.13)
const PANEL_COLOR: Color = Color(0.16, 0.16, 0.20, 0.95)
const PANEL_BORDER: Color = Color(0.35, 0.35, 0.40, 0.8)
const TEXT_COLOR: Color = Color(0.92, 0.92, 0.92)
const TEXT_DIM: Color = Color(0.60, 0.60, 0.65)
const HIGHLIGHT_COLOR: Color = Color(1.0, 1.0, 0.0, 0.35)
const VALID_COLOR: Color = Color(0.2, 1.0, 0.2, 0.30)
const INVALID_COLOR: Color = Color(1.0, 0.2, 0.2, 0.30)
const ROBBER_COLOR: Color = Color(0.08, 0.08, 0.08, 0.85)
const PORT_COLOR: Color = Color(0.60, 0.55, 0.40)

# ---- 建筑绘制参数 ----
const ROAD_WIDTH: float = 6.0
const SETTLEMENT_RADIUS: float = 8.0
const CITY_RADIUS: float = 12.0
const TOKEN_RADIUS: float = 14.0
