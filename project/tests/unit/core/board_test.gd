## Board 拓扑单元测试。
extends GutTest


func _make_simple_board() -> Board:
	var board := Board.new()
	# 3 个六边形组成简单拓扑
	board.add_hex(HexCoord.new(0, 0))
	board.add_hex(HexCoord.new(1, 0))
	board.add_hex(HexCoord.new(0, 1))
	board.build_topology()
	return board


func test_board_hex_count():
	var board := _make_simple_board()
	assert_eq(board.hex_count(), 3)


func test_board_has_hex():
	var board := _make_simple_board()
	assert_true(board.has_hex(HexCoord.new(0, 0)))
	assert_false(board.has_hex(HexCoord.new(5, 5)))


func test_board_get_hex():
	var board := _make_simple_board()
	var h := board.get_hex(HexCoord.new(0, 0))
	assert_not_null(h)
	assert_eq(h.id, 0)


func test_board_get_hex_by_id():
	var board := _make_simple_board()
	var h := board.get_hex_by_id(1)
	assert_not_null(h)
	assert_eq(h.coord.q, 1)
	assert_eq(h.coord.r, 0)


func test_board_all_hexes():
	var board := _make_simple_board()
	assert_eq(board.all_hexes().size(), 3)


func test_board_vertex_count():
	var board := _make_simple_board()
	# 3 个相邻六边形共享顶点
	assert_true(board.vertex_count() > 0)


func test_board_edge_count():
	var board := _make_simple_board()
	assert_true(board.edge_count() > 0)


func test_board_edge_vertices():
	var board := _make_simple_board()
	var edges := board.all_edges()
	assert_false(edges.is_empty())
	var e: Board.EdgeData = edges[0]
	var verts := board.edge_vertices(e.id)
	assert_eq(verts.size(), 2)


func test_board_vertex_edges():
	var board := _make_simple_board()
	var verts := board.all_vertices()
	assert_false(verts.is_empty())
	var v: Board.VertexData = verts[0]
	var edges := board.vertex_edges(v.id)
	assert_false(edges.is_empty())


func test_board_adjacent_vertices():
	var board := _make_simple_board()
	var verts := board.all_vertices()
	var v: Board.VertexData = verts[0]
	var adj := board.adjacent_vertices(v.id)
	assert_false(adj.is_empty())


func test_board_vertex_hexes():
	var board := _make_simple_board()
	var verts := board.all_vertices()
	# 至少有一个顶点属于多个六边形
	var found_shared := false
	for v in verts:
		var vd: Board.VertexData = v
		if board.vertex_hexes(vd.id).size() > 1:
			found_shared = true
			break
	assert_true(found_shared)


func test_board_vertex_distance():
	var board := _make_simple_board()
	var verts := board.all_vertices()
	var v1: Board.VertexData = verts[0]
	assert_eq(board.vertex_distance(v1.id, v1.id), 0)


func test_board_boundary_vertices():
	var board := _make_simple_board()
	var boundary := board.boundary_vertices()
	assert_false(boundary.is_empty())


func test_board_port_management():
	var board := _make_simple_board()
	var verts := board.all_vertices()
	var vid: int = verts[0].id
	assert_eq(board.get_port(vid), "")
	board.set_port(vid, "generic_3to1")
	assert_eq(board.get_port(vid), "generic_3to1")
	assert_eq(board.port_count(), 1)


func test_board_full_base_generation():
	var terrains_r := DataLoader.load_terrains()
	assert_true(terrains_r.ok)
	var ports_r := DataLoader.load_ports()
	assert_true(ports_r.ok)
	var board_r := BoardGenerator.generate_full_base_board(42, terrains_r.value, ports_r.value)
	assert_true(board_r.ok)
	var board: Board = board_r.value
	assert_eq(board.hex_count(), 19)
	# 18 个数字牌（沙漠无数牌）
	var with_tokens := 0
	for h in board.all_hexes():
		if h.number_token > 0:
			with_tokens += 1
	assert_eq(with_tokens, 18)
	# 9 个港口
	assert_eq(board.port_count(), 9)


func test_board_seed_reproducibility():
	var terrains_r := DataLoader.load_terrains()
	var ports_r := DataLoader.load_ports()
	var b1_r := BoardGenerator.generate_full_base_board(123, terrains_r.value, ports_r.value)
	var b2_r := BoardGenerator.generate_full_base_board(123, terrains_r.value, ports_r.value)
	var b1: Board = b1_r.value
	var b2: Board = b2_r.value
	# 相同种子应产生相同地形分布
	for i in range(b1.hex_count()):
		var h1 := b1.get_hex_by_id(i)
		var h2 := b2.get_hex_by_id(i)
		assert_eq(h1.terrain_id, h2.terrain_id)
		assert_eq(h1.number_token, h2.number_token)
