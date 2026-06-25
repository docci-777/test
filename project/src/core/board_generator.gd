## 棋盘生成器。
##
## 根据地形定义生成基础版棋盘（19 个六边形 + 数字牌 + 港口）。
## 属于 Layer 1 核心层，纯逻辑。
##
## 基础版棋盘布局（标准 4 人）：
## - 19 个陆地六边形（3-4-5-4-3 环形）
## - 18 个数字牌（2-12，除 7，沙漠无数牌）
## - 9 个港口（4 通用 3:1 + 5 专项 2:1）
class_name BoardGenerator extends RefCounted


## 生成基础版棋盘（仅六边形 + 地形，不含数字牌与港口）。
## [param seed] 随机种子
## [param terrains] 地形定义字典
## [return] Result，成功时 value 为 Board
static func generate_base_board(seed: int, terrains: Dictionary) -> Result:
	var board := Board.new()
	# 基础版 19 个六边形坐标（3-4-5-4-3 环形）
	var coords: Array = [
		HexCoord.new(-1, -2), HexCoord.new(0, -2), HexCoord.new(1, -2),
		HexCoord.new(-2, -1), HexCoord.new(-1, -1), HexCoord.new(0, -1), HexCoord.new(1, -1),
		HexCoord.new(-2, 0), HexCoord.new(-1, 0), HexCoord.new(0, 0), HexCoord.new(1, 0), HexCoord.new(2, 0),
		HexCoord.new(-2, 1), HexCoord.new(-1, 1), HexCoord.new(0, 1), HexCoord.new(1, 1),
		HexCoord.new(-1, 2), HexCoord.new(0, 2), HexCoord.new(1, 2),
	]
	for coord in coords:
		board.add_hex(coord)
	# 分配地形
	var terrain_pool := _build_terrain_pool(terrains)
	terrain_pool = _shuffle_with_seed(terrain_pool, seed)
	var idx: int = 0
	for hex_data in board.all_hexes():
		if idx < terrain_pool.size():
			hex_data.terrain_id = terrain_pool[idx]
			idx += 1
	board.build_topology()
	return Result.success(board)


## 生成完整基础版棋盘（六边形 + 地形 + 数字牌 + 港口）。
## [param seed] 随机种子
## [param terrains] 地形定义字典
## [param ports] 港口定义字典
## [return] Result，成功时 value 为 Board
static func generate_full_base_board(seed: int, terrains: Dictionary, ports: Dictionary) -> Result:
	var board_result := generate_base_board(seed, terrains)
	if not board_result.ok:
		return board_result
	var board: Board = board_result.value
	assign_number_tokens(board, seed)
	assign_ports(board, seed, ports)
	return Result.success(board)


## 分配数字牌（2-12，除 7，沙漠无数牌）。
## [param board] 棋盘
## [param seed] 随机种子
static func assign_number_tokens(board: Board, seed: int) -> Result:
	# 数字牌池：2,3,3,4,4,5,5,6,6,8,8,9,9,10,10,11,11,12（18 张，无 7）
	var tokens: Array = [2, 3, 3, 4, 4, 5, 5, 6, 6, 8, 8, 9, 9, 10, 10, 11, 11, 12]
	tokens = _shuffle_with_seed(tokens, seed)
	var idx: int = 0
	for hex_data in board.all_hexes():
		if hex_data.terrain_id == "desert":
			continue  # 沙漠无数牌
		if idx < tokens.size():
			hex_data.number_token = tokens[idx]
			idx += 1
	return Result.success()


## 分配港口到边界顶点。
## [param board] 棋盘
## [param seed] 随机种子
## [param ports] 港口定义字典
static func assign_ports(board: Board, seed: int, ports: Dictionary) -> Result:
	var port_pool := _build_port_pool(ports)
	port_pool = _shuffle_with_seed(port_pool, seed)
	# 获取边界顶点（相邻六边形数 < 3）
	var boundary: Array = board.boundary_vertices()
	boundary = _shuffle_with_seed(boundary, seed)
	# 每隔 2 个顶点放一个港口（避免相邻）
	var idx: int = 0
	var skip: int = 0
	for vid in boundary:
		if skip > 0:
			skip -= 1
			continue
		if idx >= port_pool.size():
			break
		board.set_port(vid, port_pool[idx])
		idx += 1
		skip = 1  # 跳过下一个顶点
	return Result.success()


# ---- 内部辅助 ----

## 构建地形池（按 count_base 重复）。
static func _build_terrain_pool(terrains: Dictionary) -> Array:
	var pool: Array = []
	for id in terrains.keys():
		var def: TerrainDef = terrains[id]
		for i in range(def.count_base):
			pool.append(id)
	return pool


## 构建港口池（按 count_base 重复）。
static func _build_port_pool(ports: Dictionary) -> Array:
	var pool: Array = []
	for id in ports.keys():
		var def: PortDef = ports[id]
		for i in range(def.count_base):
			pool.append(id)
	return pool


## 用种子打乱数组（Fisher-Yates）。
static func _shuffle_with_seed(arr: Array, seed: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var result := arr.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result
