## 棋盘视图（P9-1, P9-2）。
##
## 负责渲染六边形棋盘、地形、数字牌、港口、建筑、强盗。
## 处理点击交互，将用户输入转换为位置选择信号。
##
## 见 ARCHITECTURE §6.1：视图与状态分离，不直接改状态。
class_name BoardView extends Node2D

# ---- 信号 ----
## 玩家点击了顶点（建筑放置）
signal vertex_clicked(vertex_id: int)
## 玩家点击了边（道路放置）
signal edge_clicked(edge_id: int)
## 玩家点击了六边形（强盗移动）
signal hex_clicked(hex_id: int)

# ---- 常量 ----
const HEX_SIZE: float = 52.0
const SQRT3: float = 1.7320508

# ---- 状态 ----
var _state: GameState
var _center_offset: Vector2 = Vector2(640, 340)

# 缓存的渲染数据
var _hex_centers: Dictionary = {}  # hex_id -> Vector2
var _vertex_pixels: Dictionary = {}  # vertex_id -> Vector2
var _edge_data: Dictionary = {}  # edge_id -> {center, p1, p2}

# 高亮
var _highlight_vertices: Array = []  # vertex_id 列表
var _highlight_edges: Array = []  # edge_id 列表
var _highlight_hexes: Array = []  # hex_id 列表
var _build_target: String = ""  # "road"/"settlement"/"city"/"robber"

# 字体
var _font: Font


func _ready() -> void:
	_font = ThemeDB.get_default_theme().default_font


## 更新视图（由 GameController 调用）。
func update_view(state: GameState) -> void:
	_state = state
	_rebuild_cache()
	queue_redraw()


## 设置建造模式，高亮可放置位置。
func set_build_mode(target: String, valid_positions: Array) -> void:
	_build_target = target
	_highlight_vertices.clear()
	_highlight_edges.clear()
	_highlight_hexes.clear()
	match target:
		"settlement", "city":
			_highlight_vertices = valid_positions
		"road":
			_highlight_edges = valid_positions
		"robber":
			_highlight_hexes = valid_positions
	queue_redraw()


## 清除建造模式。
func clear_build_mode() -> void:
	_build_target = ""
	_highlight_vertices.clear()
	_highlight_edges.clear()
	_highlight_hexes.clear()
	queue_redraw()


# ---- 缓存构建 ----

func _rebuild_cache() -> void:
	if _state == null or _state.board == null:
		return
	_hex_centers.clear()
	_vertex_pixels.clear()
	_edge_data.clear()

	# 六边形中心
	for hex_data in _state.board.all_hexes():
		var coord: HexCoord = hex_data.coord
		var px: float = SQRT3 * (float(coord.q) + float(coord.r) / 2.0) * HEX_SIZE
		var py: float = 1.5 * float(coord.r) * HEX_SIZE
		_hex_centers[hex_data.id] = _center_offset + Vector2(px, py)

	# 顶点像素位置（从 canonical_key 解析整数物理坐标）
	for v in _state.board.all_vertices():
		var vd: Board.VertexData = v
		var parts := vd.canonical_key.split(",")
		var cx: int = int(parts[0])
		var cy: int = int(parts[1])
		var px: float = SQRT3 / 2.0 * float(cx) * HEX_SIZE
		var py: float = 0.5 * float(cy) * HEX_SIZE
		_vertex_pixels[vd.id] = _center_offset + Vector2(px, py)

	# 边数据
	for e in _state.board.all_edges():
		var ed: Board.EdgeData = e
		var verts: Array = _state.board.edge_vertices(ed.id)
		if verts.size() < 2:
			continue
		var p1: Vector2 = _vertex_pixels.get(verts[0], Vector2.ZERO)
		var p2: Vector2 = _vertex_pixels.get(verts[1], Vector2.ZERO)
		_edge_data[ed.id] = {
			"center": (p1 + p2) / 2.0,
			"p1": p1,
			"p2": p2,
		}


# ---- 渲染 ----

func _draw() -> void:
	if _state == null or _state.board == null:
		return
	_draw_hexes()
	_draw_ports()
	_draw_buildings()
	_draw_robber()
	_draw_highlights()


func _draw_hexes() -> void:
	for hex_data in _state.board.all_hexes():
		var center: Vector2 = _hex_centers.get(hex_data.id, Vector2.ZERO)
		var terrain_id: String = hex_data.terrain_id
		var color: Color = ThemeColors.TERRAIN_COLORS.get(terrain_id, Color(0.5, 0.5, 0.5))

		# 绘制六边形
		var points := PackedVector2Array()
		for i in range(6):
			var angle: float = deg_to_rad(60 * i - 30)
			points.append(center + Vector2(cos(angle), sin(angle)) * HEX_SIZE)
		draw_colored_polygon(points, color)

		# 边框
		draw_polyline(points, Color(0.1, 0.1, 0.1, 0.5), 2.0, true)

		# 数字牌（沙漠无数牌）
		if hex_data.number_token > 0 and terrain_id != "desert":
			_draw_number_token(center, hex_data.number_token)

		# 地形名称
		var tdef: TerrainDef = _state.terrains.get(terrain_id)
		if tdef != null:
			var name_pos := center + Vector2(0, HEX_SIZE * 0.45)
			_draw_text_centered(name_pos, tdef.display_name, 12, Color(0.2, 0.2, 0.2, 0.7))


func _draw_number_token(center: Vector2, number: int) -> void:
	var token_color := Color(0.95, 0.93, 0.88)
	var text_color := Color(0.15, 0.15, 0.15)
	if number == 6 or number == 8:
		text_color = Color(0.75, 0.15, 0.15)

	draw_circle(center, ThemeColors.TOKEN_RADIUS, token_color)
	draw_arc(center, ThemeColors.TOKEN_RADIUS, 0, TAU, 32, Color(0.3, 0.3, 0.3), 1.5)
	_draw_text_centered(center + Vector2(0, -2), str(number), 18, text_color)

	# 概率点
	var dots: int = _probability_dots(number)
	if dots > 0:
		var dot_y: float = center.y + 10
		var dot_spacing: float = 4.0
		var start_x: float = center.x - (float(dots - 1) * dot_spacing) / 2.0
		for i in range(dots):
			draw_circle(Vector2(start_x + i * dot_spacing, dot_y), 1.5, text_color)


func _probability_dots(number: int) -> int:
	match number:
		2, 12: return 1
		3, 11: return 2
		4, 10: return 3
		5, 9: return 4
		6, 8: return 5
		_: return 0


func _draw_ports() -> void:
	for vid in _state.board.all_port_vertices():
		var port_id: String = _state.board.get_port(vid)
		var pos: Vector2 = _vertex_pixels.get(vid, Vector2.ZERO)
		var pdef: PortDef = _state.ports.get(port_id)
		if pdef == null:
			continue

		# 港口标记：半圆 + 比例文字
		draw_arc(pos, 10, 0, TAU, 16, ThemeColors.PORT_COLOR, 2.0)
		var label: String = pdef.trade_ratio
		if pdef.is_specialized:
			var res_name: String = ResType.name_of(pdef.resource)
			label = res_name.left(2) + pdef.trade_ratio
		_draw_text_centered(pos + Vector2(0, 16), label, 10, ThemeColors.PORT_COLOR)


func _draw_buildings() -> void:
	# 道路
	for key in _state.placements.keys():
		var p: Placement = _state.placements[key]
		var player: PlayerState = _state.get_player(p.player_id)
		if player == null:
			continue
		var pcolor: Color = ThemeColors.PLAYER_COLORS.get(player.color, Color.GRAY)

		if p.building_id == "road":
			var ed: Dictionary = _edge_data.get(p.position_id, {})
			if ed.is_empty():
				continue
			draw_line(ed["p1"], ed["p2"], Color(0.1, 0.1, 0.1), ThemeColors.ROAD_WIDTH + 2.0)
			draw_line(ed["p1"], ed["p2"], pcolor, ThemeColors.ROAD_WIDTH)

		elif p.building_id == "settlement":
			var pos: Vector2 = _vertex_pixels.get(p.position_id, Vector2.ZERO)
			draw_circle(pos, ThemeColors.SETTLEMENT_RADIUS + 1, Color(0.1, 0.1, 0.1))
			draw_circle(pos, ThemeColors.SETTLEMENT_RADIUS, pcolor)

		elif p.building_id == "city":
			var pos: Vector2 = _vertex_pixels.get(p.position_id, Vector2.ZERO)
			# 城市用方形
			var s := ThemeColors.CITY_RADIUS
			var rect := Rect2(pos.x - s, pos.y - s, s * 2, s * 2)
			draw_rect(rect, Color(0.1, 0.1, 0.1), false, 2.0)
			draw_rect(rect, pcolor, true)


func _draw_robber() -> void:
	if _state.robber_hex_id < 0:
		return
	var center: Vector2 = _hex_centers.get(_state.robber_hex_id, Vector2.ZERO)
	draw_circle(center, 8, ThemeColors.ROBBER_COLOR)
	draw_arc(center, 8, 0, TAU, 16, Color(0, 0, 0), 1.5)


func _draw_highlights() -> void:
	# 高亮顶点
	for vid in _highlight_vertices:
		var pos: Vector2 = _vertex_pixels.get(vid, Vector2.ZERO)
		draw_arc(pos, ThemeColors.SETTLEMENT_RADIUS + 4, 0, TAU, 24, ThemeColors.HIGHLIGHT_COLOR, 3.0)

	# 高亮边
	for eid in _highlight_edges:
		var ed: Dictionary = _edge_data.get(eid, {})
		if ed.is_empty():
			continue
		draw_line(ed["p1"], ed["p2"], ThemeColors.HIGHLIGHT_COLOR, ThemeColors.ROAD_WIDTH + 4.0)

	# 高亮六边形
	for hid in _highlight_hexes:
		var center: Vector2 = _hex_centers.get(hid, Vector2.ZERO)
		var points := PackedVector2Array()
		for i in range(6):
			var angle: float = deg_to_rad(60 * i - 30)
			points.append(center + Vector2(cos(angle), sin(angle)) * HEX_SIZE)
		draw_polyline(points, ThemeColors.HIGHLIGHT_COLOR, 3.0, true)


# ---- 点击检测 ----

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos: Vector2 = make_input_local(event).position
		_handle_click(pos)


func _handle_click(pos: Vector2) -> void:
	if _build_target == "robber":
		var hex_id := _find_nearest_hex(pos)
		if hex_id >= 0 and _highlight_hexes.has(hex_id):
			hex_clicked.emit(hex_id)
	elif _build_target == "settlement" or _build_target == "city":
		var vid := _find_nearest_vertex(pos)
		if vid >= 0 and _highlight_vertices.has(vid):
			vertex_clicked.emit(vid)
	elif _build_target == "road":
		var eid := _find_nearest_edge(pos)
		if eid >= 0 and _highlight_edges.has(eid):
			edge_clicked.emit(eid)


func _find_nearest_vertex(pos: Vector2) -> int:
	var best_id: int = -1
	var best_dist: float = 20.0
	for vid in _vertex_pixels.keys():
		var v: Vector2 = _vertex_pixels[vid]
		var d: float = v.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best_id = vid
	return best_id


func _find_nearest_edge(pos: Vector2) -> int:
	var best_id: int = -1
	var best_dist: float = 20.0
	for eid in _edge_data.keys():
		var ed: Dictionary = _edge_data[eid]
		var d: float = _dist_to_segment(pos, ed["p1"], ed["p2"])
		if d < best_dist:
			best_dist = d
			best_id = eid
	return best_id


func _find_nearest_hex(pos: Vector2) -> int:
	var best_id: int = -1
	var best_dist: float = HEX_SIZE
	for hid in _hex_centers.keys():
		var c: Vector2 = _hex_centers[hid]
		var d: float = c.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best_id = hid
	return best_id


func _dist_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab: Vector2 = b - a
	var len_sq: float = ab.length_squared()
	if len_sq < 0.001:
		return p.distance_to(a)
	var t: float = clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)


# ---- 辅助 ----

func _draw_text_centered(pos: Vector2, text: String, size: int, color: Color) -> void:
	if _font == null:
		return
	var text_size: Vector2 = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
	_font.draw_string(get_canvas_item(), pos - text_size / 2.0 + Vector2(0, size / 3.0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, size, color)
