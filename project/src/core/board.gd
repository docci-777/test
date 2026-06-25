## 棋盘拓扑。
##
## 管理六边形集合、顶点（归一化）、边（归一化），以及邻接关系查询。
## 拓扑与规则解耦：Board 只描述几何关系，不知道"定居点"概念（见 ARCHITECTURE §3.1）。
##
## 顶点归一化：同一物理顶点可被最多 3 个相邻六边形以不同方向索引指向，
## Board 负责将其归一化为唯一 VertexId。
##
## 边归一化：同理，同一物理边可被 2 个相邻六边形指向。
class_name Board extends RefCounted

## 六边形数据（HexCoord.to_key() -> HexData）
var _hexes: Dictionary = {}
## 顶点集合（vertex_id -> VertexData）
var _vertices: Dictionary = {}
## 边集合（edge_id -> EdgeData）
var _edges: Dictionary = {}
## 顶点归一化映射：从 (hex_key + dir) 到归一化 vertex_id
var _vertex_canonical: Dictionary = {}
## 边归一化映射：从 (hex_key + dir) 到归一化 edge_id
var _edge_canonical: Dictionary = {}
## 顶点邻接表（vertex_id -> Array of vertex_id）
var _vertex_adjacency: Dictionary = {}
## 边到顶点映射（edge_id -> Array of vertex_id）
var _edge_vertices: Dictionary = {}
## 顶点到边映射（vertex_id -> Array of edge_id）
var _vertex_edges: Dictionary = {}
## 顶点到六边形映射（vertex_id -> Array of HexCoord）
var _vertex_hexes: Dictionary = {}
## 边到六边形映射（edge_id -> Array of HexCoord）
var _edge_hexes: Dictionary = {}
## 港口放置（vertex_id -> port_id 字符串）
var _ports: Dictionary = {}
## 顶点 ID 到 VertexData 的反向索引
var _vertices_by_id: Dictionary = {}
## 边 ID 到 EdgeData 的反向索引
var _edges_by_id: Dictionary = {}
## 六边形 ID 到 HexData 的反向索引
var _hexes_by_id: Dictionary = {}


# ---- 六边形管理 ----

## 添加六边形到棋盘（build_topology 前调用）。
func add_hex(coord: HexCoord) -> void:
	var key := coord.to_key()
	if _hexes.has(key):
		return
	var hex_data := HexData.new(coord)
	hex_data.id = _hexes.size()
	_hexes[key] = hex_data
	_hexes_by_id[hex_data.id] = hex_data


## 构建拓扑：归一化顶点与边，预计算邻接关系。
## 必须在所有 add_hex 之后调用一次。
func build_topology() -> void:
	_vertices.clear()
	_edges.clear()
	_vertex_canonical.clear()
	_edge_canonical.clear()
	_vertex_adjacency.clear()
	_edge_vertices.clear()
	_vertex_edges.clear()
	_vertex_hexes.clear()
	_edge_hexes.clear()
	_ports.clear()
	_vertices_by_id.clear()
	_edges_by_id.clear()
	_hexes_by_id.clear()

	# 第一遍：为每个六边形生成顶点与边，归一化
	for key in _hexes.keys():
		var hex_data: HexData = _hexes[key]
		_hexes_by_id[hex_data.id] = hex_data
		_build_hex_topology(hex_data)

	# 构建 _vertices_by_id 与 _edges_by_id 反向索引
	for v in _vertices.values():
		_vertices_by_id[(v as VertexData).id] = v
	for e in _edges.values():
		_edges_by_id[(e as EdgeData).id] = e

	# 第二遍：构建顶点邻接（通过共享边）
	_build_vertex_adjacency()


func _build_hex_topology(hex_data: HexData) -> void:
	var coord: HexCoord = hex_data.coord
	var coord_key := coord.to_key()
	# 六边形的 6 个顶点（按方向 0-5 顺时针）
	var hex_vertex_ids: Array = []
	for i in range(6):
		var vid := _canonical_vertex_id(coord, i)
		hex_vertex_ids.append(vid)
		# 记录顶点所属六边形（用 to_key 去重，避免引用比较问题）
		if not _vertex_hexes.has(vid):
			_vertex_hexes[vid] = []
		var existing_keys: Dictionary = {}
		for h in _vertex_hexes[vid]:
			existing_keys[(h as HexCoord).to_key()] = true
		if not existing_keys.has(coord_key):
			_vertex_hexes[vid].append(coord)

	# 六边形的 6 条边（边 i 连接顶点 i 和顶点 (i+1)%6）
	for i in range(6):
		var v1: int = hex_vertex_ids[i]
		var v2: int = hex_vertex_ids[(i + 1) % 6]
		var eid := _canonical_edge_id(v1, v2)
		# 记录边连接的顶点
		if not _edge_vertices.has(eid):
			_edge_vertices[eid] = [v1, v2]
		# 记录顶点连接的边
		if not _vertex_edges.has(v1):
			_vertex_edges[v1] = []
		if not _vertex_edges[v1].has(eid):
			_vertex_edges[v1].append(eid)
		if not _vertex_edges.has(v2):
			_vertex_edges[v2] = []
		if not _vertex_edges[v2].has(eid):
			_vertex_edges[v2].append(eid)
		# 记录边所属六边形（用 to_key 去重）
		if not _edge_hexes.has(eid):
			_edge_hexes[eid] = []
		var e_existing: Dictionary = {}
		for h in _edge_hexes[eid]:
			e_existing[(h as HexCoord).to_key()] = true
		if not e_existing.has(coord_key):
			_edge_hexes[eid].append(coord)


## 计算顶点的归一化 ID。
##
## 用顶点的物理坐标作为 canonical key。
##
## pointy-top 六边形（size=1），中心 (q, r) 的像素坐标：
##   x = sqrt(3) * (q + r/2)
##   y = 1.5 * r
##
## 为避免 sqrt(3) 无理数导致的浮点误差，将坐标整数化：
##   中心: (2q + r, 3r)
##   顶点偏移 i: (dx, dy) 查表
##   顶点坐标 = (2q + r + dx, 3r + dy)
const _VERTEX_OFFSETS: Array = [
	{dx = 1, dy = -1},  # 0 NE
	{dx = 1, dy = 1},   # 1 E
	{dx = 0, dy = 2},   # 2 SE
	{dx = -1, dy = 1},  # 3 SW
	{dx = -1, dy = -1}, # 4 W
	{dx = 0, dy = -2},  # 5 NW
]

func _canonical_vertex_id(coord: HexCoord, dir: int) -> int:
	# 顶点的整数物理坐标
	var cx: int = 2 * coord.q + coord.r
	var cy: int = 3 * coord.r
	var off: Dictionary = _VERTEX_OFFSETS[dir]
	var vx: int = cx + off.dx
	var vy: int = cy + off.dy
	var canonical := str(vx) + "," + str(vy)

	# 分配整数 ID
	if not _vertices.has(canonical):
		var new_id := _vertices.size()
		_vertices[canonical] = VertexData.new(new_id, canonical)
	return (_vertices[canonical] as VertexData).id


## 计算边的归一化 ID。
## 边由两个顶点确定，取 (min_vid, max_vid) 作为 canonical。
func _canonical_edge_id(v1: int, v2: int) -> int:
	var min_v := mini(v1, v2)
	var max_v := maxi(v1, v2)
	var canonical := str(min_v) + "-" + str(max_v)
	if not _edges.has(canonical):
		var new_id := _edges.size()
		_edges[canonical] = EdgeData.new(new_id, canonical)
	return (_edges[canonical] as EdgeData).id


## 构建顶点邻接表（通过共享边）。
func _build_vertex_adjacency() -> void:
	for eid in _edge_vertices.keys():
		var verts: Array = _edge_vertices[eid]
		var v1: int = verts[0]
		var v2: int = verts[1]
		if not _vertex_adjacency.has(v1):
			_vertex_adjacency[v1] = []
		if not _vertex_adjacency.has(v2):
			_vertex_adjacency[v2] = []
		if not _vertex_adjacency[v1].has(v2):
			_vertex_adjacency[v1].append(v2)
		if not _vertex_adjacency[v2].has(v1):
			_vertex_adjacency[v2].append(v1)


# ---- 查询接口 ----

## 六边形数量。
func hex_count() -> int:
	return _hexes.size()


## 是否包含指定六边形。
func has_hex(coord: HexCoord) -> bool:
	return _hexes.has(coord.to_key())


## 获取六边形数据。
func get_hex(coord: HexCoord) -> HexData:
	return _hexes.get(coord.to_key())


## 按 ID 获取六边形数据。
func get_hex_by_id(hex_id: int) -> HexData:
	return _hexes_by_id.get(hex_id)


## 获取所有六边形。
func all_hexes() -> Array:
	return _hexes.values()


## 顶点数量。
func vertex_count() -> int:
	return _vertices.size()


## 边数量。
func edge_count() -> int:
	return _edges.size()


## 获取所有顶点。
func all_vertices() -> Array:
	return _vertices.values()


## 获取所有边。
func all_edges() -> Array:
	return _edges.values()


## 获取六边形的邻居（仅返回棋盘上存在的）。
func hex_neighbors(coord: HexCoord) -> Array:
	var result: Array = []
	for d in HexCoord.DIRECTIONS:
		var n := HexCoord.new(coord.q + d.q, coord.r + d.r)
		if has_hex(n):
			result.append(n)
	return result


## 获取顶点连接的边。
func vertex_edges(vertex_id: int) -> Array:
	return _vertex_edges.get(vertex_id, [])


## 获取边连接的两个顶点。
func edge_vertices(edge_id: int) -> Array:
	return _edge_vertices.get(edge_id, [])


## 获取顶点的相邻顶点。
func adjacent_vertices(vertex_id: int) -> Array:
	return _vertex_adjacency.get(vertex_id, [])


## 获取顶点所属的六边形列表。
func vertex_hexes(vertex_id: int) -> Array:
	return _vertex_hexes.get(vertex_id, [])


## 获取边所属的六边形列表。
func edge_hexes(edge_id: int) -> Array:
	return _edge_hexes.get(edge_id, [])


## 按 ID 获取顶点数据。
func get_vertex(vertex_id: int) -> VertexData:
	return _vertices_by_id.get(vertex_id)


## 按 ID 获取边数据。
func get_edge(edge_id: int) -> EdgeData:
	return _edges_by_id.get(edge_id)


## 获取所有边界顶点（相邻六边形数 < 3 的顶点）。
## 这些顶点位于棋盘外圈，可放置港口。
func boundary_vertices() -> Array:
	var result: Array = []
	for vid in _vertices_by_id.keys():
		var hexes: Array = _vertex_hexes.get(vid, [])
		if hexes.size() < 3:
			result.append(vid)
	return result


# ---- 港口管理 ----

## 在指定顶点设置港口。
func set_port(vertex_id: int, port_id: String) -> void:
	_ports[vertex_id] = port_id


## 获取指定顶点的港口 ID（无港口返回空字符串）。
func get_port(vertex_id: int) -> String:
	return _ports.get(vertex_id, "")


## 获取所有已放置港口的顶点 ID 列表。
func all_port_vertices() -> Array:
	return _ports.keys()


## 港口数量。
func port_count() -> int:
	return _ports.size()


## 计算两个顶点之间的最短距离（BFS）。
## 用于定居点距离规则校验（≥2 边）。
func vertex_distance(v1: int, v2: int) -> int:
	if v1 == v2:
		return 0
	if not _vertex_adjacency.has(v1) or not _vertex_adjacency.has(v2):
		return -1

	var visited: Dictionary = {v1: 0}
	var queue: Array = [v1]
	while not queue.is_empty():
		var current: int = queue.pop_front()
		var dist: int = visited[current]
		for neighbor in _vertex_adjacency.get(current, []):
			if neighbor == v2:
				return dist + 1
			if not visited.has(neighbor):
				visited[neighbor] = dist + 1
				queue.append(neighbor)
	return -1


# ---- 数据类 ----

## 六边形数据。
class HexData:
	var id: int = -1
	var coord: HexCoord
	var terrain_id: String = ""
	var number_token: int = 0

	func _init(c: HexCoord) -> void:
		coord = c


## 顶点数据。
class VertexData:
	var id: int
	var canonical_key: String

	func _init(i: int, k: String) -> void:
		id = i
		canonical_key = k


## 边数据。
class EdgeData:
	var id: int
	var canonical_key: String

	func _init(i: int, k: String) -> void:
		id = i
		canonical_key = k
